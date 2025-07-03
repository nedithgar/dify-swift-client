import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Mock URL Protocol

/// Custom URLProtocol for intercepting and mocking HTTP requests in tests
public final class MockURLProtocol: URLProtocol {
    
    // MARK: - Types
    
    /// Mock response configuration
    public struct MockResponse {
        let statusCode: Int
        let data: Data
        let headers: [String: String]
        let error: Error?
        
        public init(statusCode: Int = 200, data: Data = Data(), headers: [String: String] = [:], error: Error? = nil) {
            self.statusCode = statusCode
            self.data = data
            self.headers = headers
            self.error = error
        }
        
        /// Create a JSON response
        public static func json(_ object: Any, statusCode: Int = 200) -> MockResponse {
            let data: Data
            do {
                data = try JSONSerialization.data(withJSONObject: object)
            } catch {
                data = Data()
            }
            return MockResponse(
                statusCode: statusCode,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        /// Create an error response
        public static func httpError(statusCode: Int, message: String? = nil) -> MockResponse {
            let errorData: Data
            if let message = message {
                let errorObject = ["error": message]
                errorData = (try? JSONSerialization.data(withJSONObject: errorObject)) ?? Data()
            } else {
                errorData = Data()
            }
            return MockResponse(
                statusCode: statusCode,
                data: errorData,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        /// Create a network error
        public static func networkError(_ error: Error) -> MockResponse {
            return MockResponse(error: error)
        }
    }
    
    // MARK: - Storage
    
    private static let lockQueue = DispatchQueue(label: "com.dify.mockurlprotocol.lock")
    nonisolated(unsafe) private static var _mocks: [String: MockResponse] = [:]
    nonisolated(unsafe) private static var _requestHandler: ((URLRequest) -> (HTTPURLResponse, Data)?)?
    nonisolated(unsafe) private static var _capturedRequests: [URLRequest] = []
    nonisolated(unsafe) private static var _isCapturing = false
    
    // MARK: - URLProtocol Overrides
    
    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        // Capture request if enabled
        MockURLProtocol.lockQueue.sync {
            if MockURLProtocol._isCapturing {
                MockURLProtocol._capturedRequests.append(request)
            }
        }
        
        // Try custom request handler first
        let handler = MockURLProtocol.lockQueue.sync { MockURLProtocol._requestHandler }
        if let handler = handler,
           let (response, data) = handler(request) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Extract endpoint from URL path
        let endpoint = extractEndpoint(from: request.url)
        
        // Look for registered mock
        let mockResponse = MockURLProtocol.lockQueue.sync { MockURLProtocol._mocks[endpoint] }
        if let mockResponse = mockResponse {
            if let error = mockResponse.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: mockResponse.statusCode,
                httpVersion: nil,
                headerFields: mockResponse.headers
            )!
            
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockResponse.data)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            // No mock registered - return 404
            let notFoundResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            
            let errorData = try! JSONSerialization.data(withJSONObject: [
                "error": "No mock registered for endpoint: \(endpoint)"
            ])
            
            client?.urlProtocol(self, didReceive: notFoundResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: errorData)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    public override func stopLoading() {
        // Nothing to do
    }
    
    // MARK: - Public API
    
    /// Register a mock response for a specific endpoint
    public static func registerMock(endpoint: String, response: MockResponse) {
        Self.lockQueue.sync { Self._mocks[endpoint] = response }
    }
    
    /// Set a custom request handler for complex scenarios
    public static func setRequestHandler(_ handler: @escaping (URLRequest) -> (HTTPURLResponse, Data)?) {
        Self.lockQueue.sync { Self._requestHandler = handler }
    }
    
    /// Clear all registered mocks
    public static func clearAllMocks() {
        Self.lockQueue.sync {
            Self._mocks.removeAll()
            Self._requestHandler = nil
        }
    }
    
    /// Start capturing requests for validation
    public static func startCapturing() {
        Self.lockQueue.sync {
            Self._isCapturing = true
            Self._capturedRequests.removeAll()
        }
    }
    
    /// Stop capturing requests
    public static func stopCapturing() {
        Self.lockQueue.sync { Self._isCapturing = false }
    }
    
    /// Get captured requests
    public static func getCapturedRequests() -> [URLRequest] {
        return Self.lockQueue.sync { Self._capturedRequests }
    }
    
    /// Clear captured requests
    public static func clearCapturedRequests() {
        Self.lockQueue.sync { Self._capturedRequests.removeAll() }
    }
    
    // MARK: - Helper Methods
    
    private func extractEndpoint(from url: URL?) -> String {
        guard let url = url else { return "" }
        
        // Remove base URL components to get just the endpoint
        let path = url.path
        if path.starts(with: "/v1/") {
            return String(path.dropFirst(4)) // Remove "/v1/"
        } else if path.starts(with: "/") {
            return String(path.dropFirst(1)) // Remove leading "/"
        }
        return path
    }
}

// MARK: - Mock Request Capture

/// Utility for capturing and validating requests made during tests
public final class MockRequestCapture {
    
    /// Start capturing all HTTP requests
    public static func startCapturing() {
        MockURLProtocol.startCapturing()
    }
    
    /// Stop capturing requests
    public static func stopCapturing() {
        MockURLProtocol.stopCapturing()
    }
    
    /// Get all captured requests
    public static func getCapturedRequests() -> [URLRequest] {
        return MockURLProtocol.getCapturedRequests()
    }
    
    /// Clear captured requests
    public static func clearCapturedRequests() {
        MockURLProtocol.clearCapturedRequests()
    }
}

// MARK: - Test Assertions

/// Utility functions for validating requests and responses in tests
public enum TestAssertions {
    
    /// Verify that a request has the correct authorization header
    public static func verifyAuthHeader(request: URLRequest, expectedApiKey: String) {
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer \(expectedApiKey)")
    }
    
    /// Verify that a request has the correct content type
    public static func verifyContentType(request: URLRequest, expectedType: String) {
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType == expectedType)
    }
    
    /// Verify that a request has the expected HTTP method
    public static func verifyHTTPMethod(request: URLRequest, expectedMethod: String) {
        #expect(request.httpMethod == expectedMethod)
    }
    
    /// Verify that a request URL contains the expected endpoint
    public static func verifyEndpoint(request: URLRequest, expectedEndpoint: String) {
        let url = request.url?.path ?? ""
        #expect(url.contains(expectedEndpoint))
    }
    
    /// Verify that request body contains expected JSON structure
    public static func verifyJSONBody<T: Codable>(request: URLRequest, expectedType: T.Type) throws -> T {
        guard let body = request.httpBody else {
            Issue.record("Request body is nil")
            throw TestError.missingRequestBody
        }
        
        do {
            return try JSONDecoder().decode(expectedType, from: body)
        } catch {
            Issue.record("Failed to decode request body: \(error)")
            throw TestError.invalidRequestBody(error)
        }
    }
}