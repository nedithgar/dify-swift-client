import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// MockURLProtocol intercepts all HTTP requests during tests and returns mock responses
/// This allows us to test without any real network calls
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    
    /// Storage for mock responses keyed by request
    private nonisolated(unsafe) static var mockResponses: [MockRequest: MockResponse] = [:]
    
    /// Storage for captured requests for verification
    private nonisolated(unsafe) static var capturedRequests: [URLRequest] = []
    
    /// Thread-safe access queue
    private static let queue = DispatchQueue(label: "MockURLProtocol.queue", attributes: .concurrent)
    
    // MARK: - Mock Response Registration
    
    /// Register a mock response for a specific request pattern
    static func register(
        method: String,
        urlPattern: String,
        response: MockResponse
    ) {
        let mockRequest = MockRequest(method: method, urlPattern: urlPattern)
        queue.sync(flags: .barrier) {
            mockResponses[mockRequest] = response
            print("[MockURLProtocol] Registered mock: \(method) \(urlPattern) - Total mocks: \(mockResponses.count) - Thread: \(Thread.current)")
        }
    }
    
    /// Register a mock response with more detailed matching
    static func register(
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
    static func reset() {
        queue.sync(flags: .barrier) {
            print("[MockURLProtocol] Resetting all mocks - Had \(mockResponses.count) mocks")
            mockResponses.removeAll()
            capturedRequests.removeAll()
        }
    }
    
    /// Get all captured requests
    static func getCapturedRequests() -> [URLRequest] {
        queue.sync {
            return capturedRequests
        }
    }
    
    /// Get captured requests matching a pattern
    static func getCapturedRequests(matching pattern: String) -> [URLRequest] {
        queue.sync {
            return capturedRequests.filter { request in
                request.url?.absoluteString.contains(pattern) ?? false
            }
        }
    }
    
    // MARK: - URLProtocol Implementation
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all HTTP/HTTPS requests
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
        // Capture the request
        Self.queue.sync(flags: .barrier) {
            Self.capturedRequests.append(self.request)
        }
        
        // Find matching mock response
        let matchingResponse = Self.queue.sync {
            Self.findMatchingResponse(for: request)
        }
        
        if let mockResponse = matchingResponse {
            // Send mock response
            handleMockResponse(mockResponse)
        } else {
            // No mock found - return 404
            handleNoMockFound()
        }
    }
    
    override func stopLoading() {
        // Nothing to clean up
    }
    
    // MARK: - Private Methods
    
    private static func findMatchingResponse(for request: URLRequest) -> MockResponse? {
        guard let url = request.url else { return nil }
        
        print("[MockURLProtocol] Finding mock for: \(url.absoluteString)")
        print("[MockURLProtocol] Registered mocks: \(mockResponses.keys.map { "\($0.method) \($0.urlPattern)" })")
        
        // Try to find a matching mock
        for (mockRequest, mockResponse) in mockResponses {
            if mockRequest.matches(request: request) {
                print("[MockURLProtocol] Found matching mock!")
                return mockResponse
            }
        }
        
        print("[MockURLProtocol] No matching mock found")
        return nil
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
            domain: "MockURLProtocol",
            code: 404,
            userInfo: [
                NSLocalizedDescriptionKey: "No mock response registered for request: \(request.url?.absoluteString ?? "unknown")"
            ]
        )
        client?.urlProtocol(self, didFailWithError: error)
    }
}

// MARK: - Supporting Types

/// Represents a request pattern for matching
struct MockRequest: Hashable {
    let method: String
    let urlPattern: String
    let headers: [String: String]?
    let bodyPattern: String?
    
    init(method: String, urlPattern: String, headers: [String: String]? = nil, bodyPattern: String? = nil) {
        self.method = method.uppercased()
        self.urlPattern = urlPattern
        self.headers = headers
        self.bodyPattern = bodyPattern
    }
    
    func matches(request: URLRequest) -> Bool {
        // Check method
        guard request.httpMethod?.uppercased() == method else { return false }
        
        // Check URL pattern (simple contains check - could be enhanced with regex)
        guard let url = request.url?.absoluteString,
              url.contains(urlPattern) else { return false }
        
        // Check headers if specified
        if let expectedHeaders = headers {
            for (key, value) in expectedHeaders {
                guard request.value(forHTTPHeaderField: key) == value else { return false }
            }
        }
        
        // Check body pattern if specified
        if let bodyPattern = bodyPattern,
           let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            guard bodyString.contains(bodyPattern) else { return false }
        }
        
        return true
    }
}

/// Represents a mock response
struct MockResponse {
    let statusCode: Int
    let headers: [String: String]?
    let data: Data?
    let delay: TimeInterval
    let isStreaming: Bool
    let streamDelay: TimeInterval
    
    init(
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        data: Data? = nil,
        delay: TimeInterval = 0,
        isStreaming: Bool = false,
        streamDelay: TimeInterval = 0.01
    ) {
        self.statusCode = statusCode
        
        // Add default Content-Type if not specified
        var finalHeaders = headers ?? [:]
        if finalHeaders["Content-Type"] == nil {
            finalHeaders["Content-Type"] = isStreaming ? "text/event-stream" : "application/json"
        }
        self.headers = finalHeaders
        
        self.data = data
        self.delay = delay
        self.isStreaming = isStreaming
        self.streamDelay = streamDelay
    }
    
    /// Create a JSON response
    static func json(
        _ object: Any,
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        delay: TimeInterval = 0
    ) -> MockResponse {
        let data = try? JSONSerialization.data(withJSONObject: object, options: [])
        return MockResponse(
            statusCode: statusCode,
            headers: headers,
            data: data,
            delay: delay
        )
    }
    
    /// Create a streaming response
    static func streaming(
        _ events: [String],
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        delay: TimeInterval = 0,
        streamDelay: TimeInterval = 0.01
    ) -> MockResponse {
        let data = events.joined(separator: "\n\n").data(using: .utf8)
        return MockResponse(
            statusCode: statusCode,
            headers: headers,
            data: data,
            delay: delay,
            isStreaming: true,
            streamDelay: streamDelay
        )
    }
    
    /// Create an error response
    static func error(
        statusCode: Int,
        code: String,
        message: String,
        headers: [String: String]? = nil
    ) -> MockResponse {
        // Return DifyError-compatible format
        let errorData = [
            "message": message,
            "code": code,
            "status": statusCode
        ] as [String : Any]
        return json(errorData, statusCode: statusCode, headers: headers)
    }
}