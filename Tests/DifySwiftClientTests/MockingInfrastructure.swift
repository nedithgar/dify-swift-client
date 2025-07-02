import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@preconcurrency import Foundation

// MARK: - Mock URL Protocol

/// URLProtocol subclass for intercepting and mocking HTTP requests in tests
public class MockURLProtocol: URLProtocol {
    
    // MARK: - Static Properties
    
    nonisolated(unsafe) private static var mockResponses: [String: MockResponse] = [:]
    nonisolated(unsafe) private static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?
    
    // MARK: - Mock Response Configuration
    
    /// Register a mock response for a specific endpoint
    public static func registerMock(endpoint: String, response: MockResponse) {
        mockResponses[endpoint] = response
    }
    
    /// Set a custom request handler for more complex mocking scenarios
    public static func setRequestHandler(_ handler: @escaping (URLRequest) -> (HTTPURLResponse, Data)) {
        requestHandler = handler
    }
    
    /// Clear all registered mocks
    public static func clearMocks() {
        mockResponses.removeAll()
        requestHandler = nil
    }
    
    // MARK: - URLProtocol Implementation
    
    public override class func canInit(with request: URLRequest) -> Bool {
        // Only handle requests that match our mock endpoints or have a custom handler
        guard let url = request.url?.absoluteString else { return false }
        return mockResponses.keys.contains { url.contains($0) } || requestHandler != nil
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        // Use custom request handler if available
        if let handler = MockURLProtocol.requestHandler {
            let (response, data) = handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Find matching mock response
        let urlString = url.absoluteString
        let matchingEndpoint = MockURLProtocol.mockResponses.keys.first { urlString.contains($0) }
        
        guard let endpoint = matchingEndpoint,
              let mockResponse = MockURLProtocol.mockResponses[endpoint] else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        // Create HTTP response
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )!
        
        // Send response
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        
        if let data = mockResponse.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let error = mockResponse.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    public override func stopLoading() {
        // Nothing to do here
    }
}

// MARK: - Mock Response Structure

/// Represents a mock HTTP response
public struct MockResponse {
    public let statusCode: Int
    public let data: Data?
    public let headers: [String: String]?
    public let error: Error?
    
    public init(statusCode: Int = 200, data: Data? = nil, headers: [String: String]? = nil, error: Error? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
        self.error = error
    }
    
    /// Create a mock response with JSON data
    public static func json<T: Codable>(_ object: T, statusCode: Int = 200, headers: [String: String]? = nil) -> MockResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(object)
        return MockResponse(
            statusCode: statusCode,
            data: data,
            headers: (headers ?? [:]).merging(["Content-Type": "application/json"]) { _, new in new }
        )
    }
    
    /// Create a mock error response
    public static func error(_ error: Error, statusCode: Int = 500) -> MockResponse {
        return MockResponse(statusCode: statusCode, error: error)
    }
    
    /// Create a mock HTTP error response with JSON error message
    public static func httpError(statusCode: Int, message: String) -> MockResponse {
        let errorData = """
        {
            "code": "error",
            "message": "\(message)",
            "status": \(statusCode)
        }
        """.data(using: .utf8)!
        
        return MockResponse(
            statusCode: statusCode,
            data: errorData,
            headers: ["Content-Type": "application/json"]
        )
    }
}

// MARK: - Mock Session Manager

/// Helper class for managing mock URLSession configurations
public class MockSessionManager {
    nonisolated(unsafe) private static var mockSession: URLSession?
    
    /// Create a URLSession configured to use MockURLProtocol
    public static func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        mockSession = session
        return session
    }
    
    /// Clean up mock session
    public static func cleanup() {
        mockSession?.invalidateAndCancel()
        mockSession = nil
        MockURLProtocol.clearMocks()
    }
}

// MARK: - Mock Data Provider

/// Provides predefined mock responses for common Dify API endpoints
@MainActor
public struct MockDataProvider {
    
    // MARK: - Chat Responses
    
    public static let chatMessageResponse = ChatMessageResponse(
        answer: "This is a mock response from the chat API.",
        messageId: "mock-message-123",
        conversationId: "mock-conversation-456",
        createdAt: Int(Date().timeIntervalSince1970)
    )
    
    // MARK: - Completion Responses
    
    public static let completionMessageResponse = CompletionMessageResponse(
        answer: "This is a mock completion response.",
        messageId: "mock-completion-789",
        conversationId: "mock-conversation-456",
        createdAt: Int(Date().timeIntervalSince1970)
    )
    
    // MARK: - Workflow Responses
    
    public static let workflowResponse = WorkflowResponse(
        workflowRunId: "mock-workflow-run-789",
        taskId: "mock-task-456",
        data: WorkflowData(
            id: "mock-workflow-data-101",
            workflowId: "mock-workflow-202",
            status: "succeeded",
            outputs: ["result": "Workflow completed successfully"],
            error: nil,
            elapsedTime: 2.5,
            totalTokens: 100,
            totalSteps: 3,
            createdAt: Int(Date().timeIntervalSince1970),
            finishedAt: Int(Date().timeIntervalSince1970) + 3
        )
    )
    
    // MARK: - File Upload Responses
    
    public static let fileUploadResponse = FileUploadResponse(
        id: "mock-file-123",
        name: "test-document.pdf",
        size: 1024000,
        fileExtension: "pdf",
        mimeType: "application/pdf",
        createdBy: "mock-user-456",
        createdAt: Int(Date().timeIntervalSince1970)
    )
    
    // MARK: - Application Info Responses
    
    public static let applicationInfoResponse = ApplicationInfoResponse(
        name: "Mock Dify App",
        description: "A mock application for testing",
        tags: ["test", "mock"],
        mode: "chat",
        authorName: "Test Developer"
    )
    
    public static let enhancedApplicationParametersResponse = EnhancedApplicationParametersResponse(
        openingStatement: "Welcome to our mock chat bot!",
        suggestedQuestions: ["How can I help you?", "What would you like to know?"],
        suggestedQuestionsAfterAnswer: SuggestedQuestionsConfig(enabled: true),
        speechToText: SpeechToTextConfig(enabled: true),
        textToSpeech: TextToSpeechConfig(enabled: true, voice: "alloy", language: "en-US", autoPlay: "enabled"),
        retrieverResource: RetrieverResourceConfig(enabled: true),
        annotationReply: AnnotationReplyConfig(enabled: false),
        userInputForm: [],
        fileUpload: FileUploadConfig(
            image: ImageUploadConfig(
                enabled: true,
                numberLimits: 10,
                detail: "high",
                transferMethods: ["local_file", "remote_url"]
            )
        ),
        systemParameters: SystemParameters(
            fileSizeLimit: 50,
            imageFileSizeLimit: 10,
            audioFileSizeLimit: 5,
            videoFileSizeLimit: 100
        )
    )
    
    // MARK: - Feedback Responses
    
    public static let messageFeedbackResponse = MessageFeedbackResponse(
        result: "success"
    )
    
    // MARK: - Conversation Responses
    
    public static let conversationsResponse = ConversationsResponse(
        data: [
            Conversation(
                id: "mock-conversation-1",
                name: "Test Conversation 1",
                inputs: [:],
                status: "normal",
                introduction: "Welcome to conversation 1",
                createdAt: Int(Date().timeIntervalSince1970),
                updatedAt: Int(Date().timeIntervalSince1970)
            ),
            Conversation(
                id: "mock-conversation-2", 
                name: "Test Conversation 2",
                inputs: [:],
                status: "normal",
                introduction: "Welcome to conversation 2",
                createdAt: Int(Date().timeIntervalSince1970) - 3600,
                updatedAt: Int(Date().timeIntervalSince1970) - 3600
            )
        ],
        hasMore: false,
        limit: 20
    )
    
    // MARK: - Knowledge Base Responses
    
    public static let datasetResponse = DatasetResponse(
        id: "mock-dataset-123",
        name: "Mock Dataset",
        description: "A dataset for testing",
        permission: "only_me",
        dataSourceType: "upload_file",
        indexingTechnique: "high_quality",
        createdBy: "mock-user-456",
        createdAt: Int(Date().timeIntervalSince1970),
        updatedBy: "mock-user-456",
        updatedAt: Int(Date().timeIntervalSince1970)
    )
    
    public static let documentResponse = CreateDocumentResponse(
        document: DocumentResponse(
            id: "mock-document-123",
            position: 1,
            dataSource: DataSource(
                type: "upload_file",
                info: [
                    "upload_file_id": "mock-upload-456",
                    "original_filename": "test-document.pdf",
                    "mime_type": "application/pdf"
                ]
            ),
            datasetProcessRuleId: "default-rule-123",
            name: "Test Document",
            createdFrom: "api",
            createdBy: "mock-user-456",
            createdAt: Int(Date().timeIntervalSince1970),
            tokens: 500,
            indexingStatus: "completed",
            error: nil,
            enabled: true,
            disabledAt: nil,
            disabledBy: nil,
            archived: false,
            displayStatus: "available",
            wordCount: 250,
            hitCount: 10,
            docForm: "text_model"
        ),
        batch: "mock-batch-789"
    )
    
    // MARK: - Streaming Data
    
    public static func streamingData(for event: StreamingEventType, data: [String: Any]) -> Data {
        let eventData = [
            "event": event.rawValue,
            "data": data
        ] as [String: Any]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: eventData)
        let eventString = "data: \(String(data: jsonData, encoding: .utf8)!)\n\n"
        return eventString.data(using: .utf8)!
    }
    
    // MARK: - Error Responses
    
    public static func createErrorResponse(code: String = "error", message: String, status: Int = 400) -> [String: Any] {
        return [
            "code": code,
            "message": message,
            "status": status
        ]
    }
}