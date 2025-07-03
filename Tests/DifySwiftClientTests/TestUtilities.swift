import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Test Utilities

/// Helper functions for creating mock clients and setting up tests
public final class TestUtilities {
    
    // MARK: - Mock Client Creation
    
    /// Create a mock DifyClient with URLSession configured to use MockURLProtocol
    public static func createMockDifyClient(apiKey: String = MockDataProvider.testApiKey) throws -> DifyClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        return try DifyClient(apiKey: apiKey, session: session)
    }
    
    /// Create a mock ChatClient
    public static func createMockChatClient(apiKey: String = MockDataProvider.testApiKey) throws -> ChatClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        return try ChatClient(apiKey: apiKey, session: session)
    }
    
    /// Create a mock CompletionClient
    public static func createMockCompletionClient(apiKey: String = MockDataProvider.testApiKey) throws -> CompletionClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        return try CompletionClient(apiKey: apiKey, session: session)
    }
    
    /// Create a mock WorkflowClient
    public static func createMockWorkflowClient(apiKey: String = MockDataProvider.testApiKey) throws -> WorkflowClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        return try WorkflowClient(apiKey: apiKey, session: session)
    }
    
    /// Create a mock KnowledgeBaseClient
    public static func createMockKnowledgeBaseClient(
        apiKey: String = MockDataProvider.testApiKey,
        datasetId: String? = MockDataProvider.testDatasetId
    ) throws -> KnowledgeBaseClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        return try KnowledgeBaseClient(apiKey: apiKey, datasetId: datasetId, session: session)
    }
    
    // MARK: - Test Setup and Cleanup
    
    /// Setup standard mocks for all endpoints
    public static func setupStandardMocks() {
        MockConfiguration.setupStandardMocks()
    }
    
    /// Setup error scenarios for testing
    public static func setupErrorMocks() {
        MockConfiguration.setupErrorMocks()
    }
    
    /// Clean up after tests
    public static func cleanup() {
        MockConfiguration.cleanup()
    }
    
    // MARK: - Test Data Helpers
    
    /// Create test file data
    public static func createTestFileData(size: Int = 1024) -> Data {
        return Data(repeating: 0x41, count: size) // Creates data filled with 'A' characters
    }
    
    /// Create test image data (simple PNG header)
    public static func createTestImageData() -> Data {
        // Simple PNG header for testing
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        return Data(pngHeader)
    }
    
    /// Create test audio data
    public static func createTestAudioData() -> Data {
        // Simple WAV header for testing
        let wavHeader: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x24, 0x08, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45]
        return Data(wavHeader)
    }
    
    /// Create test APIFile with remote URL
    public static func createTestAPIFileRemote() -> APIFile {
        return APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/test-image.jpg"
        )
    }
    
    /// Create test APIFile with local upload
    public static func createTestAPIFileLocal() -> APIFile {
        return APIFile(
            type: .document,
            transferMethod: .localFile,
            uploadFileId: "upload-file-123"
        )
    }
    
    // MARK: - Async Test Helpers
    
    /// Run an async test with timeout
    public static func withTimeout<T: Sendable>(_ timeout: TimeInterval = 5.0, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            guard let result = try await group.next() else {
                throw TestError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Request Validation Helpers
    
    /// Validate that a request was made with expected parameters
    public static func validateRequest(
        requests: [URLRequest],
        expectedEndpoint: String,
        expectedMethod: String = "POST",
        expectedApiKey: String = MockDataProvider.testApiKey
    ) throws -> URLRequest {
        guard let request = requests.first else {
            Issue.record("No requests captured")
            throw TestError.noRequestsCaptured
        }
        
        TestAssertions.verifyHTTPMethod(request: request, expectedMethod: expectedMethod)
        TestAssertions.verifyEndpoint(request: request, expectedEndpoint: expectedEndpoint)
        TestAssertions.verifyAuthHeader(request: request, expectedApiKey: expectedApiKey)
        
        return request
    }
    
    /// Validate JSON request body
    public static func validateJSONRequestBody<T: Codable>(
        request: URLRequest,
        expectedType: T.Type
    ) throws -> T {
        return try TestAssertions.verifyJSONBody(request: request, expectedType: expectedType)
    }
    
    // MARK: - Streaming Test Helpers
    
    /// Setup streaming mock response
    public static func setupStreamingMock(endpoint: String, events: [[String: Any]]) {
        MockURLProtocol.setRequestHandler { request in
            let urlPath = request.url?.path ?? ""
            if urlPath.contains(endpoint) {
                // Create a response that simulates server-sent events
                var responseData = Data()
                for event in events {
                    if let eventData = try? JSONSerialization.data(withJSONObject: event) {
                        let eventString = "data: \(String(data: eventData, encoding: .utf8) ?? "")\n\n"
                        responseData.append(eventString.data(using: .utf8) ?? Data())
                    }
                }
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: [
                        "Content-Type": "text/event-stream",
                        "Cache-Control": "no-cache"
                    ]
                )!
                
                return (response, responseData)
            }
            return nil
        }
    }
    
    /// Collect streaming response data
    public static func collectStreamingData(from streamingResponse: StreamingResponse, limit: Int = 10) async throws -> [Data] {
        var collectedData: [Data] = []
        var count = 0
        
        for try await data in streamingResponse {
            collectedData.append(data)
            count += 1
            if count >= limit {
                break
            }
        }
        
        return collectedData
    }
    
    // MARK: - Error Testing Helpers
    
    /// Setup mock to return specific HTTP error
    public static func setupHTTPErrorMock(endpoint: String, statusCode: Int, message: String? = nil) {
        MockURLProtocol.registerMock(
            endpoint: endpoint,
            response: MockURLProtocol.MockResponse.httpError(statusCode: statusCode, message: message)
        )
    }
    
    /// Setup mock to return network error
    public static func setupNetworkErrorMock(endpoint: String, error: Error) {
        MockURLProtocol.registerMock(
            endpoint: endpoint,
            response: MockURLProtocol.MockResponse.networkError(error)
        )
    }
    
    /// Test that a specific error is thrown
    public static func expectError<T: Sendable, E: Error>(
        _ errorType: E.Type,
        from operation: @Sendable () async throws -> T
    ) async {
        do {
            _ = try await operation()
            Issue.record("Expected error of type \(errorType) but no error was thrown")
        } catch let error as E {
            // Success - expected error type was thrown
            _ = error
        } catch {
            Issue.record("Expected error of type \(errorType) but got \(type(of: error)): \(error)")
        }
    }
    
    // MARK: - Performance Testing Helpers
    
    /// Measure the execution time of an operation
    public static func measureTime<T: Sendable>(operation: @Sendable () async throws -> T) async throws -> (result: T, duration: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        return (result, duration)
    }
    
    // MARK: - Concurrency Testing Helpers
    
    /// Run multiple concurrent operations and collect results
    public static func runConcurrentOperations<T: Sendable>(
        count: Int,
        operation: @escaping @Sendable (Int) async throws -> T
    ) async throws -> [T] {
        return try await withThrowingTaskGroup(of: T.self) { group in
            for i in 0..<count {
                group.addTask {
                    try await operation(i)
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// MARK: - Test Configuration

/// Configuration for mock tests
public struct MockTestConfig {
    public static let apiKey = MockDataProvider.testApiKey
    public static let baseURL = "https://api.dify.ai/v1"
    public static let user = MockDataProvider.testUser
    public static let conversationId = MockDataProvider.testConversationId
    public static let messageId = MockDataProvider.testMessageId
    public static let workflowRunId = MockDataProvider.testWorkflowRunId
    public static let datasetId = MockDataProvider.testDatasetId
    public static let documentId = MockDataProvider.testDocumentId
}

// MARK: - Additional Test Errors

public enum TestError: Error {
    case timeout
    case noRequestsCaptured
    case unexpectedResponseFormat
    case missingRequestBody
    case invalidRequestBody(Error)
    case unexpectedResponse
    case mockNotRegistered(String)
}