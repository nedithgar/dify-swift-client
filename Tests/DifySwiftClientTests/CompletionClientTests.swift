import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("CompletionClient Tests")
struct CompletionClientTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - Completion Message Tests
    
    @Test("Create completion message with required parameters")
    func testCreateCompletionMessageWithRequiredParameters() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockCompletionMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.createCompletionMessage(
            inputs: ["query": "What is AI?"],
            user: "test-user"
        )
        
        #expect(response.answer == "This is a completion response")
        #expect(response.messageId == "msg-123")
        #expect(response.mode == "completion")
    }
    
    @Test("Create completion message with files")
    func testCreateCompletionMessageWithFiles() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockCompletionMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let files = [
            APIFile(type: .image, transferMethod: .remoteUrl, url: "https://example.com/image.jpg"),
            APIFile(type: .document, transferMethod: .localFile, uploadFileId: "file-123")
        ]
        
        let response = try await client.createCompletionMessage(
            inputs: ["query": "Analyze this image"],
            user: "test-user",
            files: files
        )
        
        #expect(response.answer == "This is a completion response")
        #expect(response.metadata != nil)
    }
    
    @Test("Create completion message with empty inputs")
    func testCreateCompletionMessageWithEmptyInputs() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockCompletionMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.createCompletionMessage(
            inputs: [:],
            user: "test-user"
        )
        
        #expect(response.answer == "This is a completion response")
    }
    
    @Test("Create completion message with API error")
    func testCreateCompletionMessageWithAPIError() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Invalid request")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createCompletionMessage(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    @Test("Create completion message with rate limit error")
    func testCreateCompletionMessageWithRateLimitError() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 429, message: "Rate limit exceeded")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createCompletionMessage(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    // MARK: - Streaming Completion Message Tests
    
    @Test("Create streaming completion message")
    func testCreateStreamingCompletionMessage() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        // Setup streaming mock
        await MainActor.run {
            MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingCompletionData
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try CompletionClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.createStreamingCompletionMessage(
            inputs: ["query": "What is AI?"],
            user: "test-user"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream, limit: 2)
        
        #expect(events.count == 2)
    }
    
    @Test("Create streaming completion message with files")
    func testCreateStreamingCompletionMessageWithFiles() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingCompletionData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try CompletionClient(apiKey: "test-api-key", session: streamingSession)
        
        let files = [TestUtilities.createTestAPIFile(type: .image)]
        
        let stream = try await streamingClient.createStreamingCompletionMessage(
            inputs: ["query": "Analyze this image"],
            user: "test-user",
            files: files
        )
        
        let events = try await TestUtilities.collectStreamItems(stream, limit: 2)
        
        #expect(events.count == 2)
    }
    
    @Test("Create streaming completion message with error")
    func testCreateStreamingCompletionMessageWithError() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockStreamingURLProtocol.streamingError = DifyError.networkError(NSError(domain: "Test", code: 0, userInfo: nil))
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try CompletionClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.createStreamingCompletionMessage(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        await TestUtilities.assertThrowsAnyError {
            _ = try await TestUtilities.collectStreamItems(stream)
        }
    }
    
    @Test("Create streaming completion message with malformed data")
    func testCreateStreamingCompletionMessageWithMalformedData() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockStreamingURLProtocol.streamingData = ["data: {invalid json}\n"]
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try CompletionClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.createStreamingCompletionMessage(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        // Should not throw error but should handle malformed data gracefully
        let events = try await TestUtilities.collectStreamItems(stream, limit: 1)
        
        #expect(events.count == 0)
    }
    
    // MARK: - Stop Completion Message Tests
    
    @Test("Stop completion message")
    func testStopCompletionMessage() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockResponse = StopCompletionResponse(result: "success")
        let mockData = MockDataProvider.jsonData(mockResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.stopCompletionMessage(taskId: "task-123", user: "test-user")
        
        #expect(response.result == "success")
    }
    
    @Test("Stop completion message with invalid task ID")
    func testStopCompletionMessageWithInvalidTaskID() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Task not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.stopCompletionMessage(taskId: "invalid-task", user: "test-user")
        }
    }
    
    @Test("Stop completion message that's already completed")
    func testStopCompletionMessageAlreadyCompleted() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Task already completed")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.stopCompletionMessage(taskId: "completed-task", user: "test-user")
        }
    }
    
    // MARK: - File Upload Tests
    
    @Test("Upload file with PNG image")
    func testUploadFileWithPNGImage() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockFileUpload)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test.png",
            user: "test-user"
        )
        
        #expect(response.id == "file-123")
        #expect(response.name == "test.png")
        #expect(response.fileExtension == "png")
        #expect(response.mimeType == "image/png")
    }
    
    @Test("Upload file with JPEG image")
    func testUploadFileWithJPEGImage() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockFileUpload)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test.jpg",
            user: "test-user"
        )
        
        #expect(response.id == "file-123")
        #expect(response.name == "test.png")
    }
    
    @Test("Upload file with custom MIME type")
    func testUploadFileWithCustomMimeType() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockFileUpload)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test.custom",
            user: "test-user",
            mimeType: "image/custom"
        )
        
        #expect(response.id == "file-123")
    }
    
    @Test("Upload file with unsupported format")
    func testUploadFileWithUnsupportedFormat() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Unsupported file format")
        
        let fileData = TestUtilities.createTestFileData()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.uploadFile(
                fileData: fileData,
                fileName: "test.exe",
                user: "test-user"
            )
        }
    }
    
    @Test("Upload file that's too large")
    func testUploadFileThatsTooLarge() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 413, message: "File too large")
        
        let largeFileData = TestUtilities.createTestFileData(size: 50_000_000) // 50MB
        
        await TestUtilities.assertThrowsAnyError {
            try await client.uploadFile(
                fileData: largeFileData,
                fileName: "large.png",
                user: "test-user"
            )
        }
    }
    
    @Test("Upload empty file")
    func testUploadEmptyFile() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Empty file")
        
        let emptyFileData = Data()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.uploadFile(
                fileData: emptyFileData,
                fileName: "empty.png",
                user: "test-user"
            )
        }
    }
    
    // MARK: - Feedback Tests
    
    @Test("Give message feedback with like rating")
    func testGiveMessageFeedbackWithLikeRating() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockMessageFeedback)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.giveMessageFeedback(
            messageId: "msg-123",
            rating: "like",
            user: "test-user"
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Give message feedback with dislike rating and content")
    func testGiveMessageFeedbackWithDislikeRatingAndContent() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockMessageFeedback)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.giveMessageFeedback(
            messageId: "msg-123",
            rating: "dislike",
            user: "test-user",
            content: "Not accurate"
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Give message feedback to revoke rating")
    func testGiveMessageFeedbackToRevokeRating() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockMessageFeedback)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.giveMessageFeedback(
            messageId: "msg-123",
            rating: nil,
            user: "test-user"
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Give message feedback with invalid message ID")
    func testGiveMessageFeedbackWithInvalidMessageID() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Message not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.giveMessageFeedback(
                messageId: "invalid-msg",
                rating: "like",
                user: "test-user"
            )
        }
    }
    
    @Test("Get application feedbacks")
    func testGetApplicationFeedbacks() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationFeedbacks)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationFeedbacks()
        
        #expect(response.data.count == 1)
        #expect(response.data[0].rating == "like")
    }
    
    @Test("Get application feedbacks with custom pagination")
    func testGetApplicationFeedbacksWithCustomPagination() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationFeedbacks)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationFeedbacks(page: 2, limit: 10)
        
        #expect(response.data.count == 1)
    }
    
    // MARK: - Text-to-Audio Tests
    
    @Test("Get text to audio with message ID")
    func testGetTextToAudioWithMessageID() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockAudioData = TestUtilities.createTestAudioData()
        
        MockURLProtocol.setMockResponse(data: mockAudioData, statusCode: 200)
        
        let response = try await client.getTextToAudio(messageId: "msg-123", user: "test-user")
        
        #expect(response.count == mockAudioData.count)
    }
    
    @Test("Get text to audio with text content")
    func testGetTextToAudioWithTextContent() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockAudioData = TestUtilities.createTestAudioData()
        
        MockURLProtocol.setMockResponse(data: mockAudioData, statusCode: 200)
        
        let response = try await client.getTextToAudio(text: "Hello, world!", user: "test-user")
        
        #expect(response.count == mockAudioData.count)
    }
    
    @Test("Get text to audio with both message ID and text")
    func testGetTextToAudioWithBothMessageIDAndText() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockAudioData = TestUtilities.createTestAudioData()
        
        MockURLProtocol.setMockResponse(data: mockAudioData, statusCode: 200)
        
        // When both are provided, message ID should take precedence
        let response = try await client.getTextToAudio(
            messageId: "msg-123",
            text: "This should be ignored",
            user: "test-user"
        )
        
        #expect(response.count == mockAudioData.count)
    }
    
    @Test("Get text to audio with neither message ID nor text")
    func testGetTextToAudioWithNeitherMessageIDNorText() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Either message_id or text is required")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getTextToAudio(user: "test-user")
        }
    }
    
    @Test("Get text to audio with invalid message ID")
    func testGetTextToAudioWithInvalidMessageID() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Message not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getTextToAudio(messageId: "invalid-msg", user: "test-user")
        }
    }
    
    @Test("Get text to audio with empty text")
    func testGetTextToAudioWithEmptyText() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Text cannot be empty")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getTextToAudio(text: "", user: "test-user")
        }
    }
    
    // MARK: - Application Information Tests
    
    @Test("Get application info")
    func testGetApplicationInfo() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationInfo)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "Test App")
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test("Get application parameters")
    func testGetApplicationParameters() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationParameters)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationParameters()
        
        #expect(response.openingStatement == "Hello! How can I help you today?")
        #expect(response.suggestedQuestions?.count == 2)
        #expect(response.fileUpload?.image?.enabled == true)
    }
    
    @Test("Get application site settings")
    func testGetApplicationSiteSettings() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationSite)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationSiteSettings()
        
        #expect(response.title == "Test App")
        #expect(response.icon == "🤖")
        #expect(response.showWorkflowSteps == true)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle large inputs dictionary")
    func testHandleLargeInputsDictionary() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockCompletionMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        var largeInputs: [String: String] = [:]
        for i in 0..<1000 {
            largeInputs["key\(i)"] = "value\(i)"
        }
        
        let response = try await client.createCompletionMessage(
            inputs: largeInputs,
            user: "test-user"
        )
        
        #expect(response.answer == "This is a completion response")
    }
    
    @Test("Handle special characters in inputs")
    func testHandleSpecialCharactersInInputs() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockCompletionMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.createCompletionMessage(
            inputs: [
                "query": "Hello! @#$%^&*()_+ 你好 🚀",
                "context": "Special chars: \n\t\r\\\"'",
                "json": "{\"nested\": \"value\"}"
            ],
            user: "test-user"
        )
        
        #expect(response.answer == "This is a completion response")
    }
    
    @Test("Handle concurrent completion requests")
    func testHandleConcurrentCompletionRequests() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockCompletionMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        async let request1 = client.createCompletionMessage(inputs: ["query": "Query 1"], user: "user1")
        async let request2 = client.createCompletionMessage(inputs: ["query": "Query 2"], user: "user2")
        async let request3 = client.createCompletionMessage(inputs: ["query": "Query 3"], user: "user3")
        
        let (response1, response2, response3) = try await (request1, request2, request3)
        
        #expect(response1.answer == "This is a completion response")
        #expect(response2.answer == "This is a completion response")
        #expect(response3.answer == "This is a completion response")
    }
    
    @Test("Handle network timeout")
    func testHandleNetworkTimeout() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        
        MockURLProtocol.setMockError(timeoutError)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createCompletionMessage(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    @Test("Handle server error")
    func testHandleServerError() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 500, message: "Internal Server Error")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createCompletionMessage(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    @Test("Handle malformed JSON response")
    func testHandleMalformedJSONResponse() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let malformedJSON = Data("{ invalid json }".utf8)
        
        MockURLProtocol.setMockResponse(data: malformedJSON, statusCode: 200)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createCompletionMessage(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    // MARK: - Performance and Load Tests
    
    @Test("Handle multiple file uploads")
    func testHandleMultipleFileUploads() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockFileUpload)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let imageData = TestUtilities.createTestImageData()
        
        async let upload1 = client.uploadFile(fileData: imageData, fileName: "test1.png", user: "user1")
        async let upload2 = client.uploadFile(fileData: imageData, fileName: "test2.png", user: "user2")
        async let upload3 = client.uploadFile(fileData: imageData, fileName: "test3.png", user: "user3")
        
        let (response1, response2, response3) = try await (upload1, upload2, upload3)
        
        #expect(response1.id == "file-123")
        #expect(response2.id == "file-123")
        #expect(response3.id == "file-123")
    }
    
    @Test("Handle streaming with many events")
    func testHandleStreamingWithManyEvents() async throws {
        let client = try TestUtilities.createMockCompletionClient()
        
        var streamingData: [String] = []
        for i in 0..<100 {
            streamingData.append("data: {\"event\":\"message\",\"task_id\":\"task-123\",\"message_id\":\"msg-\(i)\",\"answer\":\"Response \(i)\",\"created_at\":1640995200}\n")
        }
        streamingData.append("data: {\"event\":\"message_end\",\"task_id\":\"task-123\",\"message_id\":\"msg-final\",\"metadata\":{\"usage\":{\"prompt_tokens\":10,\"completion_tokens\":20,\"total_tokens\":30}}}\n")
        
        MockStreamingURLProtocol.streamingData = streamingData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try CompletionClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.createStreamingCompletionMessage(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream)
        
        #expect(events.count == 101) // 100 message events + 1 message_end event
    }
}