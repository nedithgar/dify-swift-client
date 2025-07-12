import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A container that provides isolated mock session functionality for parallel testing
final class IsolatedMockSession: @unchecked Sendable {
    
    /// A unique identifier for this mock session instance
    private let sessionId = UUID()
    
    /// Storage for mock responses specific to this session
    private var mockResponses: [MockRequest: MockResponse] = [:]
    private var capturedRequests: [URLRequest] = []
    private let queue = DispatchQueue(label: "IsolatedMockSession.queue", attributes: .concurrent)
    
    /// The URLSession configured with a custom protocol
    let urlSession: URLSession
    
    /// Custom URLProtocol that routes to the correct mock session
    private class IsolatedMockURLProtocol: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            // Check if this request has a session ID header
            guard let _ = request.value(forHTTPHeaderField: "X-Mock-Session-ID") else {
                return false
            }
            
            guard let url = request.url,
                  let scheme = url.scheme,
                  ["http", "https"].contains(scheme) else {
                return false
            }
            
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            // Get the session ID from the request
            guard let sessionIdString = request.value(forHTTPHeaderField: "X-Mock-Session-ID"),
                  let sessionId = UUID(uuidString: sessionIdString),
                  let mockSession = IsolatedMockSession.activeSessions[sessionId] else {
                client?.urlProtocol(self, didFailWithError: NSError(
                    domain: "IsolatedMockURLProtocol",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Mock session not found"]
                ))
                return
            }
            
            // Capture request
            mockSession.queue.sync(flags: .barrier) {
                mockSession.capturedRequests.append(self.request)
            }
            
            // Find matching mock response
            let matchingResponse = mockSession.queue.sync {
                mockSession.findMatchingResponse(for: request)
            }
            
            if let mockResponse = matchingResponse {
                handleMockResponse(mockResponse)
            } else {
                handleNoMockFound()
            }
        }
        
        override func stopLoading() {
            // Nothing to clean up
        }
        
        private func handleMockResponse(_ mockResponse: MockResponse) {
            // Add delay if specified
            if mockResponse.delay > 0 {
                Thread.sleep(forTimeInterval: mockResponse.delay)
            }
            
            // Create HTTP response
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: mockResponse.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: mockResponse.headers
            )!
            
            // Send response
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            // Send data if available
            if let data = mockResponse.data {
                if mockResponse.isStreaming {
                    // Handle streaming response
                    handleStreamingResponse(data: data, delay: mockResponse.streamDelay)
                } else {
                    // Send all data at once
                    client?.urlProtocol(self, didLoad: data)
                }
            }
            
            // Complete the request
            client?.urlProtocolDidFinishLoading(self)
        }
        
        private func handleStreamingResponse(data: Data, delay: TimeInterval) {
            // Split data by double newlines (SSE format)
            let dataString = String(data: data, encoding: .utf8) ?? ""
            let chunks = dataString.components(separatedBy: "\n\n")
            
            for chunk in chunks where !chunk.isEmpty {
                let chunkData = (chunk + "\n\n").data(using: .utf8)!
                client?.urlProtocol(self, didLoad: chunkData)
                
                // Add delay between chunks
                if delay > 0 {
                    Thread.sleep(forTimeInterval: delay)
                }
            }
        }
        
        private func handleNoMockFound() {
            let error = NSError(
                domain: "IsolatedMockURLProtocol",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "No mock response registered for request: \(request.url?.absoluteString ?? "unknown")"
                ]
            )
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    /// Global registry of active mock sessions
    private nonisolated(unsafe) static var activeSessions: [UUID: IsolatedMockSession] = [:]
    private static let globalQueue = DispatchQueue(label: "IsolatedMockSession.global", attributes: .concurrent)
    
    /// Static initializer to register the protocol once
    private static let registerOnce: Void = {
        URLProtocol.registerClass(IsolatedMockURLProtocol.self)
    }()
    
    init() {
        // Ensure protocol is registered
        _ = Self.registerOnce
        
        // Create URLSession configuration
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IsolatedMockURLProtocol.self]
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Add custom header processor to inject session ID
        configuration.httpAdditionalHeaders = ["X-Mock-Session-ID": sessionId.uuidString]
        
        self.urlSession = URLSession(configuration: configuration)
        
        // Register this session globally
        Self.globalQueue.sync(flags: .barrier) {
            Self.activeSessions[sessionId] = self
        }
    }
    
    deinit {
        // Unregister this session
        let sessionIdToRemove = sessionId
        Self.globalQueue.async(flags: .barrier) {
            Self.activeSessions.removeValue(forKey: sessionIdToRemove)
        }
    }
    
    // MARK: - Mock Registration
    
    /// Register a mock response for a specific request pattern
    func register(method: String, urlPattern: String, response: MockResponse) {
        let mockRequest = MockRequest(method: method, urlPattern: urlPattern)
        queue.sync(flags: .barrier) {
            mockResponses[mockRequest] = response
        }
    }
    
    /// Register a mock response with more detailed matching
    func register(
        method: String,
        urlPattern: String,
        headers: [String: String]? = nil,
        bodyPattern: String? = nil,
        response: MockResponse
    ) {
        let mockRequest = MockRequest(
            method: method,
            urlPattern: urlPattern,
            headers: headers,
            bodyPattern: bodyPattern
        )
        queue.sync(flags: .barrier) {
            mockResponses[mockRequest] = response
        }
    }
    
    /// Clear all registered mocks and captured requests
    func reset() {
        queue.sync(flags: .barrier) {
            mockResponses.removeAll()
            capturedRequests.removeAll()
        }
    }
    
    /// Get all captured requests
    func getCapturedRequests() -> [URLRequest] {
        queue.sync {
            return capturedRequests
        }
    }
    
    /// Get captured requests matching a pattern
    func getCapturedRequests(matching pattern: String) -> [URLRequest] {
        queue.sync {
            return capturedRequests.filter { request in
                request.url?.absoluteString.contains(pattern) ?? false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func findMatchingResponse(for request: URLRequest) -> MockResponse? {
        // Try to find a matching mock
        for (mockRequest, mockResponse) in mockResponses {
            if mockRequest.matches(request: request) {
                return mockResponse
            }
        }
        
        return nil
    }
}

// MARK: - URLSession Extension

extension URLSession {
    /// Create a URLSession that adds the session ID header to all requests
    static func createWithSessionId(_ sessionId: UUID) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["X-Mock-Session-ID": sessionId.uuidString]
        return URLSession(configuration: configuration)
    }
}