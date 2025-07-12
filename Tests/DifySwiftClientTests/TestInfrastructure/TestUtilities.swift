import Foundation
import Testing
@testable import DifySwiftClient

/// Utilities for setting up and tearing down tests
enum TestUtilities {
    
    // MARK: - URL Session Configuration
    
    /// Create a test URL session with MockURLProtocol
    static func createMockURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration)
    }
    
    // MARK: - Client Creation
    
    /// Create a test DifyClient
    static func createTestClient(
        apiKey: String = "test-api-key",
        baseURL: String = "https://api.dify.ai/v1"
    ) -> DifyClient {
        let client = DifyClient(apiKey: apiKey, baseURL: baseURL)
        client.session = createMockURLSession()
        return client
    }
    
    /// Create a test ChatClient
    static func createTestChatClient(
        apiKey: String = "test-api-key",
        baseURL: String = "https://api.dify.ai/v1"
    ) -> ChatClient {
        let client = ChatClient(apiKey: apiKey, baseURL: baseURL)
        client.session = createMockURLSession()
        return client
    }
    
    /// Create a test CompletionClient
    static func createTestCompletionClient(
        apiKey: String = "test-api-key",
        baseURL: String = "https://api.dify.ai/v1"
    ) -> CompletionClient {
        let client = CompletionClient(apiKey: apiKey, baseURL: baseURL)
        client.session = createMockURLSession()
        return client
    }
    
    /// Create a test WorkflowClient
    static func createTestWorkflowClient(
        apiKey: String = "test-api-key",
        baseURL: String = "https://api.dify.ai/v1"
    ) -> WorkflowClient {
        let client = WorkflowClient(apiKey: apiKey, baseURL: baseURL)
        client.session = createMockURLSession()
        return client
    }
    
    /// Create a test KnowledgeBaseClient
    static func createTestKnowledgeBaseClient(
        apiKey: String = "test-api-key",
        baseURL: String = "https://api.dify.ai/v1"
    ) -> KnowledgeBaseClient {
        let client = KnowledgeBaseClient(apiKey: apiKey, baseURL: baseURL)
        client.session = createMockURLSession()
        return client
    }
    
    // MARK: - Mock Setup Helpers
    
    /// Setup common mock responses
    static func setupCommonMocks() {
        // File upload endpoint
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(
                MockDataProvider.fileUploadResponse,
                statusCode: 200
            )
        )
        
        // Application info endpoints
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/info",
            response: MockResponse.json(
                MockDataProvider.applicationInfo,
                statusCode: 200
            )
        )
        
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/parameters",
            response: MockResponse.json(
                MockDataProvider.applicationParameters,
                statusCode: 200
            )
        )
    }
    
    /// Setup chat-specific mocks
    static func setupChatMocks() {
        // Chat message endpoint
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(
                MockDataProvider.chatMessageResponse,
                statusCode: 200
            )
        )
        
        // Conversations endpoint
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/conversations",
            response: MockResponse.json(
                MockDataProvider.conversationList,
                statusCode: 200
            )
        )
        
        // Messages history endpoint
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/messages",
            response: MockResponse.json(
                MockDataProvider.messageHistory,
                statusCode: 200
            )
        )
    }
    
    /// Setup streaming mocks
    static func setupStreamingMocks() {
        // Streaming chat response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(
                MockDataProvider.streamingChatEvents,
                statusCode: 200
            )
        )
        
        // Streaming workflow response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/workflows/run",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(
                MockDataProvider.streamingWorkflowEvents,
                statusCode: 200
            )
        )
    }
    
    /// Setup error mocks
    static func setupErrorMocks() {
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/error/404",
            response: MockResponse.error(
                statusCode: 404,
                code: "not_found",
                message: "Resource not found"
            )
        )
        
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/error/401",
            response: MockResponse.error(
                statusCode: 401,
                code: "unauthorized",
                message: "Invalid API key"
            )
        )
        
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/error/429",
            response: MockResponse.error(
                statusCode: 429,
                code: "rate_limit_exceeded",
                message: "Rate limit exceeded"
            )
        )
    }
    
    // MARK: - Test Data Helpers
    
    /// Create test file data
    static func createTestImageData() -> Data {
        // Create a simple 1x1 PNG image
        let pngData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,  // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
            0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59,
            0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,  // IEND chunk
            0x44, 0xAE, 0x42, 0x60, 0x82
        ])
        return pngData
    }
    
    /// Create test text file data
    static func createTestTextData() -> Data {
        "This is a test document.\nIt has multiple lines.\nFor testing purposes.".data(using: .utf8)!
    }
    
    /// Create test audio data (simplified)
    static func createTestAudioData() -> Data {
        // Return some dummy data representing an audio file
        Data(repeating: 0xFF, count: 1024)
    }
    
    // MARK: - Assertion Helpers
    
    /// Assert that a request was captured with specific properties
    static func assertRequestCaptured(
        method: String,
        urlPattern: String,
        headers: [String: String]? = nil
    ) {
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        
        let matchingRequest = capturedRequests.first { request in
            guard request.httpMethod == method else { return false }
            guard let url = request.url?.absoluteString,
                  url.contains(urlPattern) else { return false }
            
            if let expectedHeaders = headers {
                for (key, value) in expectedHeaders {
                    guard request.value(forHTTPHeaderField: key) == value else {
                        return false
                    }
                }
            }
            
            return true
        }
        
        #expect(matchingRequest != nil, "Expected request not captured: \(method) \(urlPattern)")
    }
    
    /// Assert JSON body contains expected fields
    static func assertJSONBody(
        of request: URLRequest,
        contains expectedFields: [String: Any]
    ) throws {
        guard let bodyData = request.httpBody else {
            Issue.record("Request has no body")
            return
        }
        
        let bodyJSON = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        #expect(bodyJSON != nil, "Body is not valid JSON")
        
        for (key, expectedValue) in expectedFields {
            if let actualValue = bodyJSON?[key] {
                // Simple equality check - could be enhanced for deeper comparison
                #expect("\(actualValue)" == "\(expectedValue)", 
                       "Field '\(key)' mismatch. Expected: \(expectedValue), Got: \(actualValue)")
            } else {
                Issue.record("Missing expected field: \(key)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Reset all mocks and captured data
    static func cleanup() {
        MockURLProtocol.reset()
    }
}