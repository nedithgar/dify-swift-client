import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Advanced API Tests with Mocking

@Suite("Advanced Mock API Tests")
struct AdvancedMockAPITests {
    
    // MARK: - File Upload Tests
    
    @Test("File upload with mock response")
    func testFileUpload() async throws {
        // Setup file upload mock
        MockURLProtocol.registerMock(
            endpoint: "files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let client = try TestUtilities.createMockDifyClient()
        
        // Create test file data
        let testData = "Test file content".data(using: .utf8)!
        
        // Test file upload
        let response = try await client.uploadFile(
            user: MockTestConfig.userId,
            fileData: testData,
            filename: "test.txt",
            mimeType: "text/plain"
        )
        
        #expect(response.id == "mock-file-123")
        #expect(response.name == "test-document.pdf")
        #expect(response.size == 1024000)
        #expect(response.mimeType == "application/pdf")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("File upload with different file types")
    func testFileUploadDifferentTypes() async throws {
        // Setup mock that returns different responses based on file type
        MockURLProtocol.setRequestHandler { request in
            let url = request.url!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            
            // Determine file type from request
            var responseData: FileUploadResponse
            if url.absoluteString.contains("image") {
                responseData = FileUploadResponse(
                    id: "image-123",
                    name: "test.jpg",
                    size: 2048000,
                    fileExtension: "jpg",
                    mimeType: "image/jpeg",
                    createdBy: MockTestConfig.userId,
                    createdAt: Int(Date().timeIntervalSince1970)
                )
            } else {
                responseData = MockDataProvider.fileUploadResponse
            }
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try! encoder.encode(responseData)
            
            return (response, data)
        }
        
        let client = try TestUtilities.createMockDifyClient()
        
        // Test different file types
        let imageData = "fake image data".data(using: .utf8)!
        let imageResponse = try await client.uploadFile(
            user: MockTestConfig.userId,
            fileData: imageData,
            filename: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        #expect(imageResponse.id == "image-123")
        #expect(imageResponse.mimeType == "image/jpeg")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    // MARK: - Application Info Tests
    
    @Test("Get application info")
    func testGetApplicationInfo() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockDifyClient()
        
        // Test getting application info
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "Mock Dify App")
        #expect(response.description == "A mock application for testing")
        #expect(response.mode == "chat")
        #expect(response.icon == "🤖")
        #expect(response.authorName == "Test Developer")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Get enhanced application parameters")
    func testGetEnhancedApplicationParameters() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockDifyClient()
        
        // Test getting enhanced parameters
        let response = try await client.getEnhancedApplicationParameters(
            user: MockTestConfig.userId
        )
        
        #expect(response.openingStatement == "Welcome to our mock chat bot!")
        #expect(response.suggestedQuestions?.count == 2)
        #expect(response.speechToText?.enabled == true)
        #expect(response.textToSpeech?.enabled == true)
        #expect(response.fileUpload?.image?.enabled == true)
        #expect(response.systemParameters?.imageFileUploadLimit == 10)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    // MARK: - Feedback Tests
    
    @Test("Send message feedback")
    func testSendMessageFeedback() async throws {
        // Setup mock for feedback
        MockURLProtocol.registerMock(
            endpoint: "messages",
            response: MockResponse(statusCode: 201)
        )
        
        let client = try TestUtilities.createMockDifyClient()
        
        // Test sending feedback
        try await client.sendEnhancedMessageFeedback(
            messageId: MockTestConfig.messageId,
            rating: "like",
            user: MockTestConfig.userId,
            content: "This response was very helpful!"
        )
        
        // If we get here without throwing, the test passed
        #expect(true)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Get application feedbacks")
    func testGetApplicationFeedbacks() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockDifyClient()
        
        // Test getting feedbacks
        let response = try await client.getApplicationFeedbacks(page: 1, limit: 20)
        
        #expect(response.hasMore == false)
        #expect(response.data.count == 0) // MockDataProvider returns empty array
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    // MARK: - Streaming Tests
    
    @Test("Streaming chat message with multiple events")
    func testStreamingChatWithMultipleEvents() async throws {
        // Setup complex streaming mock
        MockURLProtocol.setRequestHandler { request in
            let url = request.url!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": "text/event-stream",
                    "Cache-Control": "no-cache"
                ]
            )!
            
            var streamData = Data()
            
            // Multiple streaming events
            let events = [
                ("message", ["id": "msg-1", "answer": "Hello"]),
                ("message", ["id": "msg-1", "answer": " there!"]),
                ("message_end", ["id": "msg-1", "metadata": ["usage": ["total_tokens": 5]]])
            ]
            
            for (eventType, eventData) in events {
                let data = MockDataProvider.streamingData(
                    for: StreamingEventType(rawValue: eventType) ?? .message,
                    data: eventData
                )
                streamData.append(data)
            }
            
            return (response, streamData)
        }
        
        let client = try TestUtilities.createMockChatClient()
        
        // Test streaming
        let streamingResponse = try await client.createStreamingChatMessage(
            inputs: [:],
            query: "Test streaming",
            user: MockTestConfig.userId
        )
        
        var eventCount = 0
        for try await chunk in streamingResponse {
            eventCount += 1
            #expect(chunk.count > 0)
            
            // Parse streaming data to verify format
            if let chunkString = String(data: chunk, encoding: .utf8) {
                #expect(chunkString.contains("data:"))
            }
            
            if eventCount >= 3 { break } // Don't run forever
        }
        
        #expect(eventCount >= 2)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    // MARK: - Conversation Management Tests
    
    @Test("Rename conversation")
    func testRenameConversation() async throws {
        // Setup mock for rename
        MockURLProtocol.registerMock(
            endpoint: "conversations",
            response: MockResponse(statusCode: 200)
        )
        
        let client = try TestUtilities.createMockChatClient()
        
        // Test renaming conversation
        try await client.renameConversation(
            conversationId: MockTestConfig.conversationId,
            name: "New Conversation Name",
            autoGenerate: false,
            user: MockTestConfig.userId
        )
        
        // If we get here without throwing, the test passed
        #expect(true)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Delete conversation")
    func testDeleteConversation() async throws {
        // Setup mock for delete
        MockURLProtocol.registerMock(
            endpoint: "conversations",
            response: MockResponse(statusCode: 204)
        )
        
        let client = try TestUtilities.createMockChatClient()
        
        // Test deleting conversation
        try await client.deleteConversation(
            conversationId: MockTestConfig.conversationId,
            user: MockTestConfig.userId
        )
        
        // If we get here without throwing, the test passed
        #expect(true)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    // MARK: - Knowledge Base Advanced Tests
    
    @Test("Create document by file")
    func testCreateDocumentByFile() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        // Create test file data
        let fileData = "Document content for knowledge base".data(using: .utf8)!
        
        // Test document creation by file
        let response = try await client.createDocumentByFile(
            fileData: fileData,
            filename: "knowledge.txt",
            mimeType: "text/plain"
        )
        
        #expect(response.document.id == "mock-document-123")
        #expect(response.document.name == "Test Document")
        #expect(response.batch == "mock-batch-789")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("List documents in dataset")
    func testListDocuments() async throws {
        // Setup mock for document list
        let documentsListResponse = DocumentsResponse(
            data: [MockDataProvider.documentResponse.document],
            hasMore: false,
            limit: 20,
            total: 1,
            page: 1
        )
        
        MockURLProtocol.registerMock(
            endpoint: "documents",
            response: MockResponse.json(documentsListResponse)
        )
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        // Test listing documents
        let response = try await client.listDocuments()
        
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "Test Document")
        #expect(response.hasMore == false)
        #expect(response.total == 1)
        
        // Cleanup
        TestUtilities.cleanup()
    }
}

// MARK: - Error Handling Tests

@Suite("Error Handling Mock Tests")
struct ErrorHandlingMockTests {
    
    @Test("Handle HTTP 401 unauthorized error")
    func testHTTP401Error() async throws {
        // Setup error mock
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockResponse.httpError(statusCode: 401, message: "Unauthorized: Invalid API key")
        )
        
        let client = try TestUtilities.createMockChatClient()
        
        // Test that 401 error is properly handled
        do {
            _ = try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.userId
            )
            Issue.record("Expected error was not thrown")
        } catch let error as DifyError {
            if case .httpError(let code, let message) = error {
                #expect(code == 401)
                #expect(message?.contains("Unauthorized") == true)
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Handle HTTP 429 rate limit error")
    func testHTTP429Error() async throws {
        // Setup rate limit error mock
        MockURLProtocol.registerMock(
            endpoint: "completion-messages",
            response: MockResponse.httpError(statusCode: 429, message: "Rate limit exceeded")
        )
        
        let client = try TestUtilities.createMockCompletionClient()
        
        // Test that 429 error is properly handled
        do {
            _ = try await client.createCompletionMessage(
                inputs: ["query": "Test"],
                responseMode: .blocking,
                user: MockTestConfig.userId
            )
            Issue.record("Expected error was not thrown")
        } catch let error as DifyError {
            if case .httpError(let code, let message) = error {
                #expect(code == 429)
                #expect(message?.contains("Rate limit") == true)
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Handle HTTP 500 server error")
    func testHTTP500Error() async throws {
        // Setup server error mock
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockResponse.httpError(statusCode: 500, message: "Internal server error")
        )
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        // Test that 500 error is properly handled
        do {
            _ = try await client.run(
                inputs: ["test": "data"],
                responseMode: .blocking,
                user: MockTestConfig.userId
            )
            Issue.record("Expected error was not thrown")
        } catch let error as DifyError {
            if case .httpError(let code, let message) = error {
                #expect(code == 500)
                #expect(message?.contains("Internal server") == true)
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Handle network error")
    func testNetworkError() async throws {
        // Setup network error mock
        MockURLProtocol.registerMock(
            endpoint: "info",
            response: MockResponse.error(URLError(.networkConnectionLost))
        )
        
        let client = try TestUtilities.createMockDifyClient()
        
        // Test that network error is properly handled
        do {
            _ = try await client.getApplicationInfo()
            Issue.record("Expected error was not thrown")
        } catch {
            // Network errors should be thrown as URLError, not DifyError
            #expect(error is URLError)
        }
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Handle malformed JSON response")
    func testMalformedJSONError() async throws {
        // Setup malformed JSON mock
        MockURLProtocol.registerMock(
            endpoint: "parameters",
            response: MockResponse(
                statusCode: 200,
                data: "{ invalid json }".data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        )
        
        let client = try TestUtilities.createMockDifyClient()
        
        // Test that JSON decoding error is properly handled
        do {
            _ = try await client.getEnhancedApplicationParameters(user: MockTestConfig.userId)
            Issue.record("Expected error was not thrown")
        } catch let error as DifyError {
            if case .decodingError = error {
                // This is expected
                #expect(true)
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
        
        // Cleanup
        TestUtilities.cleanup()
    }
}

// MARK: - Request Validation Tests

@Suite("Request Validation Mock Tests")
struct RequestValidationMockTests {
    
    @Test("Verify authorization header is set correctly")
    func testAuthorizationHeader() async throws {
        // Use request capture to verify headers
        MockRequestCapture.startCapturing()
        
        let client = try TestUtilities.createMockChatClient()
        
        // Make a request
        _ = try await client.createChatMessage(
            inputs: [:],
            query: "Test",
            user: MockTestConfig.userId
        )
        
        // Verify the request had correct auth header
        let capturedRequests = MockRequestCapture.getCapturedRequests()
        #expect(capturedRequests.count == 1)
        
        let request = capturedRequests[0]
        TestAssertions.verifyAuthHeader(request: request, expectedApiKey: MockTestConfig.apiKey)
        
        MockRequestCapture.stopCapturing()
    }
    
    @Test("Verify JSON content type is set")
    func testContentTypeHeader() async throws {
        // Use request capture
        MockRequestCapture.startCapturing()
        
        let client = try TestUtilities.createMockCompletionClient()
        
        // Make a request
        _ = try await client.createCompletionMessage(
            inputs: ["test": "data"],
            responseMode: .blocking,
            user: MockTestConfig.userId
        )
        
        // Verify content type
        let capturedRequests = MockRequestCapture.getCapturedRequests()
        #expect(capturedRequests.count == 1)
        
        let request = capturedRequests[0]
        TestAssertions.verifyContentType(request: request, expectedType: "application/json")
        
        MockRequestCapture.stopCapturing()
    }
    
    @Test("Verify request body is properly encoded")
    func testRequestBodyEncoding() async throws {
        // Use request capture
        MockRequestCapture.startCapturing()
        
        let client = try TestUtilities.createMockChatClient()
        
        // Make a request with specific data
        _ = try await client.createChatMessage(
            inputs: ["context": "test_context"],
            query: "Test query",
            user: "test_user_123"
        )
        
        // Verify request body
        let capturedRequests = MockRequestCapture.getCapturedRequests()
        #expect(capturedRequests.count == 1)
        
        let request = capturedRequests[0]
        #expect(request.httpBody != nil)
        
        // Parse the JSON body to verify structure
        if let bodyData = request.httpBody {
            let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            #expect(json?["query"] as? String == "Test query")
            #expect(json?["user"] as? String == "test_user_123")
            #expect((json?["inputs"] as? [String: String])?["context"] == "test_context")
        }
        
        MockRequestCapture.stopCapturing()
    }
}