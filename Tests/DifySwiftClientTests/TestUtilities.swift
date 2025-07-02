import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Test Utilities

/// Utilities for creating mock clients and responses in tests
public struct TestUtilities {
    
    // MARK: - Mock Client Creation
    
    /// Create a DifyClient with mock URLSession
    public static func createMockDifyClient() throws -> DifyClient {
        let mockSession = MockSessionManager.createMockSession()
        return try DifyClient(
            apiKey: "test-api-key",
            baseURL: "https://mock-api.dify.ai/v1",
            session: mockSession
        )
    }
    
    /// Create a ChatClient with mock URLSession
    public static func createMockChatClient() throws -> ChatClient {
        let mockSession = MockSessionManager.createMockSession()
        return try ChatClient(
            apiKey: "test-api-key",
            baseURL: "https://mock-api.dify.ai/v1",
            session: mockSession
        )
    }
    
    /// Create a CompletionClient with mock URLSession
    public static func createMockCompletionClient() throws -> CompletionClient {
        let mockSession = MockSessionManager.createMockSession()
        return try CompletionClient(
            apiKey: "test-api-key",
            baseURL: "https://mock-api.dify.ai/v1",
            session: mockSession
        )
    }
    
    /// Create a WorkflowClient with mock URLSession
    public static func createMockWorkflowClient() throws -> WorkflowClient {
        let mockSession = MockSessionManager.createMockSession()
        return try WorkflowClient(
            apiKey: "test-api-key",
            baseURL: "https://mock-api.dify.ai/v1",
            session: mockSession
        )
    }
    
    /// Create a KnowledgeBaseClient with mock URLSession
    public static func createMockKnowledgeBaseClient(datasetId: String = "test-dataset-123") throws -> KnowledgeBaseClient {
        let mockSession = MockSessionManager.createMockSession()
        return try KnowledgeBaseClient(
            apiKey: "test-api-key",
            baseURL: "https://mock-api.dify.ai/v1",
            datasetId: datasetId,
            session: mockSession
        )
    }
    
    // MARK: - Common Mock Setup
    
    /// Set up standard mock responses for all common endpoints
    public static func setupStandardMocks() {
        // Chat endpoints
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
        // Completion endpoints
        MockURLProtocol.registerMock(
            endpoint: "completion-messages",
            response: MockResponse.json(MockDataProvider.completionMessageResponse)
        )
        
        // Workflow endpoints
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockResponse.json(MockDataProvider.workflowResponse)
        )
        
        // File upload endpoints
        MockURLProtocol.registerMock(
            endpoint: "files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        // Application info endpoints
        MockURLProtocol.registerMock(
            endpoint: "info",
            response: MockResponse.json(MockDataProvider.applicationInfoResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "parameters",
            response: MockResponse.json(MockDataProvider.enhancedApplicationParametersResponse)
        )
        
        // Feedback endpoints
        MockURLProtocol.registerMock(
            endpoint: "feedbacks",
            response: MockResponse.json(MockDataProvider.messageFeedbackResponse)
        )
        
        // Conversation endpoints
        MockURLProtocol.registerMock(
            endpoint: "conversations",
            response: MockResponse.json(MockDataProvider.conversationsResponse)
        )
        
        // Knowledge base endpoints
        MockURLProtocol.registerMock(
            endpoint: "datasets",
            response: MockResponse.json(MockDataProvider.datasetResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "documents",
            response: MockResponse.json(MockDataProvider.documentResponse)
        )
    }
    
    // MARK: - Streaming Mocks
    
    /// Set up mock for streaming responses
    public static func setupStreamingMock() {
        MockURLProtocol.setRequestHandler { request in
            let url = request.url!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": "text/event-stream",
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive"
                ]
            )!
            
            // Create streaming data
            var streamData = Data()
            
            // Message event
            let messageData = MockDataProvider.streamingData(
                for: .message,
                data: [
                    "id": "stream-msg-1",
                    "conversation_id": "conv-123",
                    "answer": "Hello from streaming!"
                ]
            )
            streamData.append(messageData)
            
            // Message end event
            let endData = MockDataProvider.streamingData(
                for: .messageEnd,
                data: [
                    "id": "stream-msg-1",
                    "conversation_id": "conv-123",
                    "metadata": [
                        "usage": [
                            "prompt_tokens": 10,
                            "completion_tokens": 15,
                            "total_tokens": 25
                        ]
                    ]
                ]
            )
            streamData.append(endData)
            
            return (response, streamData)
        }
    }
    
    // MARK: - Error Scenarios
    
    /// Set up mock for various error scenarios
    public static func setupErrorMocks() {
        // Invalid API key
        MockURLProtocol.registerMock(
            endpoint: "invalid-key",
            response: MockResponse.httpError(statusCode: 401, message: "Invalid API key")
        )
        
        // Rate limit exceeded
        MockURLProtocol.registerMock(
            endpoint: "rate-limit",
            response: MockResponse.httpError(statusCode: 429, message: "Rate limit exceeded")
        )
        
        // Server error
        MockURLProtocol.registerMock(
            endpoint: "server-error",
            response: MockResponse.httpError(statusCode: 500, message: "Internal server error")
        )
        
        // Not found
        MockURLProtocol.registerMock(
            endpoint: "not-found",
            response: MockResponse.httpError(statusCode: 404, message: "Resource not found")
        )
        
        // Bad request
        MockURLProtocol.registerMock(
            endpoint: "bad-request",
            response: MockResponse.httpError(statusCode: 400, message: "Bad request - invalid parameters")
        )
    }
    
    // MARK: - Cleanup
    
    /// Clean up all mocks after tests
    public static func cleanup() {
        MockSessionManager.cleanup()
    }
}

// MARK: - Test Configuration

/// Mock test configuration that doesn't require environment variables
public struct MockTestConfig {
    public static let apiKey = "test-api-key-123"
    public static let baseURL = "https://mock-api.dify.ai/v1"
    public static let userId = "test-user-456"
    public static let datasetId = "test-dataset-789"
    public static let conversationId = "test-conversation-101"
    public static let messageId = "test-message-112"
    public static let workflowId = "test-workflow-131"
    public static let documentId = "test-document-415"
    public static let fileId = "test-file-161"
}

// MARK: - Assertion Helpers

/// Helper functions for common test assertions
public struct TestAssertions {
    
    /// Verify that a request was made with correct authorization header
    public static func verifyAuthHeader(request: URLRequest, expectedApiKey: String) {
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer \(expectedApiKey)")
    }
    
    /// Verify that a request has correct content type
    public static func verifyContentType(request: URLRequest, expectedType: String) {
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType == expectedType)
    }
    
    /// Verify that a request body contains expected JSON data
    public static func verifyJSONBody<T: Codable>(request: URLRequest, expectedData: T) throws {
        guard let httpBody = request.httpBody else {
            Issue.record("Request body is nil")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedData = try decoder.decode(T.self, from: httpBody)
        
        // For basic verification, we'll encode both and compare JSON strings
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys
        
        let expectedJson = try encoder.encode(expectedData)
        let actualJson = try encoder.encode(decodedData)
        
        #expect(String(data: actualJson, encoding: .utf8) == String(data: expectedJson, encoding: .utf8))
    }
}

// MARK: - Mock Request Capture

/// Utility to capture and verify requests made during tests
public class MockRequestCapture {
    private static let lock = NSLock()
    private static var _capturedRequests: [URLRequest] = []
    
    private static var capturedRequests: [URLRequest] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _capturedRequests
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _capturedRequests = newValue
        }
    }
    
    /// Start capturing requests
    public static func startCapturing() {
        lock.lock()
        defer { lock.unlock() }
        _capturedRequests.removeAll()
        
        MockURLProtocol.setRequestHandler { request in
            lock.lock()
            _capturedRequests.append(request)
            lock.unlock()
            
            // Return a default success response
            let url = request.url!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            
            let data = """
            {
                "message": "Mock response",
                "success": true
            }
            """.data(using: .utf8)!
            
            return (response, data)
        }
    }
    
    /// Get all captured requests
    public static func getCapturedRequests() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return _capturedRequests
    }
    
    /// Get the last captured request
    public static func getLastRequest() -> URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return _capturedRequests.last
    }
    
    /// Clear captured requests
    public static func clearCapturedRequests() {
        lock.lock()
        defer { lock.unlock() }
        _capturedRequests.removeAll()
    }
    
    /// Stop capturing and clean up
    public static func stopCapturing() {
        lock.lock()
        defer { lock.unlock() }
        _capturedRequests.removeAll()
        MockURLProtocol.clearMocks()
    }
}