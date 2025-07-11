import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Mock URL Protocol

/// A custom URLProtocol that intercepts HTTP requests and returns mock responses
/// This allows us to test our HTTP client code without making actual network requests
class MockURLProtocol: URLProtocol {
    
    // Static properties to control mock behavior
    @MainActor static var mockData: Data?
    @MainActor static var mockResponse: HTTPURLResponse?
    @MainActor static var mockError: Error?
    @MainActor static var shouldReturnError = false
    @MainActor static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data?, Error?))?
    
    // MARK: - URLProtocol Implementation
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true // Handle all requests
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        Task { @MainActor in
            // Use custom handler if provided
            if let handler = MockURLProtocol.requestHandler {
                let (response, data, error) = handler(request)
                
                if let error = error {
                    client?.urlProtocol(self, didFailWithError: error)
                    return
                }
                
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                
                if let data = data {
                    client?.urlProtocol(self, didLoad: data)
                }
                
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            
            // Use static mock data
            if MockURLProtocol.shouldReturnError {
                let error = MockURLProtocol.mockError ?? DifyError.networkError(NSError(domain: "MockError", code: 0, userInfo: nil))
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            guard let response = MockURLProtocol.mockResponse else {
                client?.urlProtocol(self, didFailWithError: DifyError.invalidResponse())
                return
            }
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            if let data = MockURLProtocol.mockData {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        // Required implementation
    }
    
    // MARK: - Helper Methods
    
    /// Reset all mock data to clean state
    @MainActor
    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        shouldReturnError = false
        requestHandler = nil
    }
    
    /// Configure mock to return successful response
    @MainActor
    static func setMockResponse(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
        mockData = data
        mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
        shouldReturnError = false
    }
    
    /// Configure mock to return error response
    @MainActor
    static func setMockError(_ error: Error) {
        mockError = error
        shouldReturnError = true
    }
    
    /// Configure mock to return HTTP error with specific status code
    @MainActor
    static func setMockHTTPError(statusCode: Int, message: String = "Mock error") {
        let errorData = try! JSONSerialization.data(withJSONObject: ["message": message])
        mockData = errorData
        mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        shouldReturnError = false
    }
}

// MARK: - Mock URL Session Configuration

/// Factory for creating URLSession instances configured with mock protocol
struct MockURLSessionFactory {
    
    /// Create a URLSession that uses MockURLProtocol for all requests
    static func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    /// Create a URLSession with custom request handler
    static func createMockSession(requestHandler: @escaping (URLRequest) -> (HTTPURLResponse, Data?, Error?)) -> URLSession {
        MockURLProtocol.requestHandler = requestHandler
        return createMockSession()
    }
}

// MARK: - Streaming Mock Support

/// Mock streaming response for testing AsyncThrowingStream functionality
class MockStreamingURLProtocol: URLProtocol {
    
    @MainActor static var streamingData: [String] = []
    @MainActor static var streamingError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        Task { @MainActor in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/event-stream"]
            )!
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            // Send streaming data
            for line in MockStreamingURLProtocol.streamingData {
                if let data = line.data(using: .utf8) {
                    client?.urlProtocol(self, didLoad: data)
                }
            }
            
            if let error = MockStreamingURLProtocol.streamingError {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }
    
    override func stopLoading() {
        // Required implementation
    }
    
    static func reset() {
        streamingData = []
        streamingError = nil
    }
}

// MARK: - Test Data Builders

/// Builder for creating test data objects
struct TestDataBuilder {
    
    /// Create mock JSON data for any Codable object
    static func createMockJSONData<T: Codable>(_ object: T) -> Data {
        return try! JSONEncoder.difyEncoder.encode(object)
    }
    
    /// Create mock HTTP response
    static func createMockHTTPResponse(statusCode: Int = 200, headers: [String: String] = [:]) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.dify.ai/v1/test")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
    }
    
    /// Create mock file data
    static func createMockFileData(size: Int = 1024) -> Data {
        return Data(repeating: 0x42, count: size)
    }
}