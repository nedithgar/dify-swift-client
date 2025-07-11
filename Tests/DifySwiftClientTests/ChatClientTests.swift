import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("ChatClient Tests")
struct ChatClientTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - Chat Message Tests
    
    @Test("Create chat message with required parameters")
    func testCreateChatMessageWithRequiredParameters() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.createChatMessage(
            inputs: ["query": "Hello"],
            query: "Hello world",
            user: "test-user"
        )
        
        #expect(response.answer == "Hello! How can I help you today?")
        #expect(response.messageId == "msg-123")
        #expect(response.conversationId == "conv-123")
    }
    
    @Test("Create chat message with optional parameters")
    func testCreateChatMessageWithOptionalParameters() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let files = [TestUtilities.createTestAPIFile()]
        let response = try await client.createChatMessage(
            inputs: ["query": "Hello"],
            query: "Hello world",
            user: "test-user",
            conversationId: "conv-123",
            files: files,
            autoGenerateName: true
        )
        
        #expect(response.answer == "Hello! How can I help you today?")
        #expect(response.conversationId == "conv-123")
    }
    
    @Test("Create chat message with files")
    func testCreateChatMessageWithFiles() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let files = [
            APIFile(type: .image, transferMethod: .remoteUrl, url: "https://example.com/image.jpg"),
            APIFile(type: .document, transferMethod: .localFile, uploadFileId: "file-123")
        ]
        
        let response = try await client.createChatMessage(
            inputs: ["query": "Analyze this image"],
            query: "What do you see in this image?",
            user: "test-user",
            files: files
        )
        
        #expect(response.answer == "Hello! How can I help you today?")
    }
    
    @Test("Create chat message with API error")
    func testCreateChatMessageWithAPIError() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Invalid request")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createChatMessage(
                inputs: ["query": "Hello"],
                query: "Hello world",
                user: "test-user"
            )
        }
    }
    
    // MARK: - Streaming Chat Message Tests
    
    @Test("Create streaming chat message")
    func testCreateStreamingChatMessage() async throws {
        let client = try TestUtilities.createMockChatClient()

        // Setup streaming mock on the main actor
        await MainActor.run {
            MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingChatData
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)

        let streamingClient = try ChatClient(apiKey: "test-api-key", session: streamingSession)

        let stream = try await streamingClient.createStreamingChatMessage(
            inputs: ["query": "Hello"],
            query: "Hello world",
            user: "test-user"
        )

        let events = try await TestUtilities.collectStreamItems(stream, limit: 2)

        #expect(events.count == 2)
    }

    
    @Test("Create streaming chat message with conversation ID")
    func testCreateStreamingChatMessageWithConversationID() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingChatData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try ChatClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.createStreamingChatMessage(
            inputs: ["query": "Hello"],
            query: "Hello world",
            user: "test-user",
            conversationId: "conv-123"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream, limit: 2)
        
        #expect(events.count == 2)
    }
    
    @Test("Create streaming chat message with error")
    func testCreateStreamingChatMessageWithError() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockStreamingURLProtocol.streamingError = DifyError.networkError(NSError(domain: "Test", code: 0, userInfo: nil))
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try ChatClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.createStreamingChatMessage(
            inputs: ["query": "Hello"],
            query: "Hello world",
            user: "test-user"
        )
        
        await TestUtilities.assertThrowsAnyError {
            _ = try await TestUtilities.collectStreamItems(stream)
        }
    }
    
    // MARK: - Stop Chat Generation Tests
    
    @Test("Stop chat generation")
    func testStopChatGeneration() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.stopChatGeneration(taskId: "task-123", user: "test-user")
        
        #expect(response.result == "success")
    }
    
    @Test("Stop chat generation with error")
    func testStopChatGenerationWithError() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Task not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.stopChatGeneration(taskId: "invalid-task", user: "test-user")
        }
    }
    
    // MARK: - Message History Tests
    
    @Test("Get conversation messages")
    func testGetConversationMessages() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockMessageHistory)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getConversationMessages(
            conversationId: "conv-123",
            user: "test-user"
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].query == "Hello")
        #expect(response.data[0].answer == "Hi there!")
    }
    
    @Test("Get conversation messages with pagination")
    func testGetConversationMessagesWithPagination() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockMessageHistory)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getConversationMessages(
            conversationId: "conv-123",
            user: "test-user",
            firstId: "msg-456",
            limit: 10
        )
        
        #expect(response.data.count == 1)
        #expect(response.limit == 20)
    }
    
    @Test("Get conversation messages with error")
    func testGetConversationMessagesWithError() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Conversation not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getConversationMessages(
                conversationId: "invalid-conv",
                user: "test-user"
            )
        }
    }
    
    // MARK: - Suggested Questions Tests
    
    @Test("Get suggested questions")
    func testGetSuggestedQuestions() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockSuggestedQuestions)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getSuggestedQuestions(messageId: "msg-123", user: "test-user")
        
        #expect(response.result == "success")
        #expect(response.data.count == 3)
        #expect(response.data[0] == "What is AI?")
    }
    
    @Test("Get suggested questions with error")
    func testGetSuggestedQuestionsWithError() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Message not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getSuggestedQuestions(messageId: "invalid-msg", user: "test-user")
        }
    }
    
    // MARK: - Message Feedback Tests
    
    @Test("Send message feedback with like rating")
    func testSendMessageFeedbackWithLikeRating() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.sendMessageFeedback(
            messageId: "msg-123",
            rating: "like",
            user: "test-user"
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Send message feedback with dislike rating and content")
    func testSendMessageFeedbackWithDislikeRatingAndContent() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.sendMessageFeedback(
            messageId: "msg-123",
            rating: "dislike",
            user: "test-user",
            content: "The answer was not helpful"
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Send message feedback to revoke rating")
    func testSendMessageFeedbackToRevokeRating() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.sendMessageFeedback(
            messageId: "msg-123",
            rating: nil,
            user: "test-user"
        )
        
        #expect(response.result == "success")
    }
    
    // MARK: - Application Feedbacks Tests
    
    @Test("Get application feedbacks")
    func testGetApplicationFeedbacks() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationFeedbacks)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationFeedbacks()
        
        #expect(response.data.count == 1)
        #expect(response.data[0].rating == "like")
    }
    
    @Test("Get application feedbacks with pagination")
    func testGetApplicationFeedbacksWithPagination() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationFeedbacks)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationFeedbacks(page: 2, limit: 10)
        
        #expect(response.data.count == 1)
    }
    
    // MARK: - Conversation Variables Tests
    
    @Test("Get conversation variables")
    func testGetConversationVariables() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockConversationVariables)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getConversationVariables(
            conversationId: "conv-123",
            user: "test-user"
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "user_name")
        #expect(response.data[0].value == "John Doe")
    }
    
    @Test("Get conversation variables with pagination")
    func testGetConversationVariablesWithPagination() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockConversationVariables)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getConversationVariables(
            conversationId: "conv-123",
            user: "test-user",
            lastId: "var-456",
            limit: 10
        )
        
        #expect(response.data.count == 1)
        #expect(response.limit == 20)
    }
    
    // MARK: - Audio Processing Tests
    
    @Test("Audio to text conversion")
    func testAudioToTextConversion() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAudioToText)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let audioData = TestUtilities.createTestAudioData()
        let response = try await client.audioToText(audioFile: audioData, user: "test-user")
        
        #expect(response.text == "Hello, this is a test transcription")
    }
    
    @Test("Audio to text conversion with error")
    func testAudioToTextConversionWithError() async throws {
        let client = try TestUtilities.createMockChatClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Invalid audio format")
        
        let audioData = TestUtilities.createTestAudioData()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.audioToText(audioFile: audioData, user: "test-user")
        }
    }
    
    @Test("Text to audio conversion with message ID")
    func testTextToAudioConversionWithMessageID() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockAudioData = TestUtilities.createTestAudioData()
        
        MockURLProtocol.setMockResponse(data: mockAudioData, statusCode: 200)
        
        let response = try await client.textToAudio(messageId: "msg-123", user: "test-user")
        
        #expect(response.count == mockAudioData.count)
    }
    
    @Test("Text to audio conversion with text")
    func testTextToAudioConversionWithText() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockAudioData = TestUtilities.createTestAudioData()
        
        MockURLProtocol.setMockResponse(data: mockAudioData, statusCode: 200)
        
        let response = try await client.textToAudio(text: "Hello world", user: "test-user")
        
        #expect(response.count == mockAudioData.count)
    }
    
    // MARK: - Application Information Tests
    
    @Test("Get application info")
    func testGetApplicationInfo() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationInfo)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "Test App")
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test("Get application parameters")
    func testGetApplicationParameters() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationParameters)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationParameters(user: "test-user")
        
        #expect(response.openingStatement == "Hello! How can I help you today?")
        #expect(response.suggestedQuestions?.count == 2)
    }
    
    @Test("Get application meta")
    func testGetApplicationMeta() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationMeta)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationMeta()
        
        #expect(response.toolIcons.count == 2)
        #expect(response.toolIcons["search"] != nil)
    }
    
    @Test("Get application WebApp settings")
    func testGetApplicationWebAppSettings() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationSite)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationWebAppSettings()
        
        #expect(response.title == "Test App")
        #expect(response.icon == "🤖")
        #expect(response.showWorkflowSteps == true)
    }
    
    // MARK: - Annotations Tests
    
    @Test("Get annotations")
    func testGetAnnotations() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAnnotationsList)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getAnnotations()
        
        #expect(response.data.count == 1)
        #expect(response.data[0].question == "What is AI?")
    }
    
    @Test("Get annotations with pagination")
    func testGetAnnotationsWithPagination() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAnnotationsList)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getAnnotations(page: 2, limit: 10)
        
        #expect(response.data.count == 1)
        #expect(response.page == 1)
        #expect(response.limit == 20)
    }
    
    @Test("Create annotation")
    func testCreateAnnotation() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAnnotation)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let response = try await client.createAnnotation(
            question: "What is AI?",
            answer: "AI stands for Artificial Intelligence"
        )
        
        #expect(response.question == "What is AI?")
        #expect(response.answer == "AI stands for Artificial Intelligence")
    }
    
    @Test("Update annotation")
    func testUpdateAnnotation() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAnnotation)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.updateAnnotation(
            annotationId: "annotation-123",
            question: "What is AI?",
            answer: "AI stands for Artificial Intelligence"
        )
        
        #expect(response.question == "What is AI?")
        #expect(response.answer == "AI stands for Artificial Intelligence")
    }
    
    @Test("Delete annotation")
    func testDeleteAnnotation() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.deleteAnnotation(annotationId: "annotation-123")
        
        #expect(response.result == "success")
    }
    
    @Test("Configure annotation reply")
    func testConfigureAnnotationReply() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAnnotationReplyJob)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.configureAnnotationReply(
            action: "enable",
            embeddingModelProvider: "openai",
            embeddingModel: "text-embedding-ada-002",
            scoreThreshold: 0.8
        )
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "pending")
    }
    
    @Test("Get annotation reply job status")
    func testGetAnnotationReplyJobStatus() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockAnnotationReplyJobStatus)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getAnnotationReplyJobStatus(action: "enable", jobId: "job-123")
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "completed")
    }
    
    // MARK: - Conversations Tests
    
    @Test("Get conversations")
    func testGetConversations() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockConversations)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getConversations(user: "test-user")
        
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "Test Conversation")
    }
    
    @Test("Get conversations with pagination")
    func testGetConversationsWithPagination() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockConversations)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getConversations(
            user: "test-user",
            lastId: "conv-456",
            limit: 10,
            sortBy: "-created_at"
        )
        
        #expect(response.data.count == 1)
        #expect(response.limit == 20)
    }
    
    @Test("Rename conversation")
    func testRenameConversation() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockConversations.data[0])
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.renameConversation(
            conversationId: "conv-123",
            name: "New Conversation Name",
            user: "test-user"
        )
        
        #expect(response.id == "conv-123")
        #expect(response.name == "Test Conversation")
    }
    
    @Test("Rename conversation with auto-generate")
    func testRenameConversationWithAutoGenerate() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockConversations.data[0])
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.renameConversation(
            conversationId: "conv-123",
            autoGenerate: true,
            user: "test-user"
        )
        
        #expect(response.id == "conv-123")
    }
    
    @Test("Delete conversation")
    func testDeleteConversation() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.deleteConversation(conversationId: "conv-123", user: "test-user")
        
        #expect(response.result == "success")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle empty inputs dictionary")
    func testHandleEmptyInputsDictionary() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.createChatMessage(
            inputs: [:],
            query: "Hello world",
            user: "test-user"
        )
        
        #expect(response.answer == "Hello! How can I help you today?")
    }
    
    @Test("Handle special characters in query")
    func testHandleSpecialCharactersInQuery() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.createChatMessage(
            inputs: ["query": "Test"],
            query: "Hello! @#$%^&*()_+ 你好",
            user: "test-user"
        )
        
        #expect(response.answer == "Hello! How can I help you today?")
    }
    
    @Test("Handle very long query")
    func testHandleVeryLongQuery() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let longQuery = String(repeating: "This is a very long query. ", count: 1000)
        
        let response = try await client.createChatMessage(
            inputs: ["query": "Test"],
            query: longQuery,
            user: "test-user"
        )
        
        #expect(response.answer == "Hello! How can I help you today?")
    }
    
    @Test("Handle concurrent chat requests")
    func testHandleConcurrentChatRequests() async throws {
        let client = try TestUtilities.createMockChatClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockChatMessage)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        async let request1 = client.createChatMessage(inputs: ["query": "Hello"], query: "Query 1", user: "user1")
        async let request2 = client.createChatMessage(inputs: ["query": "Hello"], query: "Query 2", user: "user2")
        async let request3 = client.createChatMessage(inputs: ["query": "Hello"], query: "Query 3", user: "user3")
        
        let (response1, response2, response3) = try await (request1, request2, request3)
        
        #expect(response1.answer == "Hello! How can I help you today?")
        #expect(response2.answer == "Hello! How can I help you today?")
        #expect(response3.answer == "Hello! How can I help you today?")
    }
}