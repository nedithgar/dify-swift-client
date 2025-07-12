import Foundation
import Testing
@testable import DifySwiftClient

@Suite("ChatClient Tests", .serialized)
final class ChatClientTests: DifyTestCase {
    
    @Test("Client Initialization")
    func testChatClientInitialization() async throws {
        let client = try ChatClient(apiKey: "test-key")
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create Chat Message")
    func testCreateChatMessage() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.createChatMessage(
            inputs: ["name": "Alice"],
            query: "Hello, how are you?",
            user: "user-123",
            conversationId: "conv-456"
        )
        
        #expect(response.event == "message")
        #expect(response.taskId == "900bbd43-dc0b-4383-a372-aa6e6c414227")
        #expect(response.messageId == "663c5084-a254-4040-8ad3-51f2a3c1a77c")
        #expect(response.conversationId == "45701982-8118-4bc5-8e9b-64562b4555f2")
        #expect(response.answer == "Hello! I'm here to help you with any questions you have.")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            method: "POST",
            urlPattern: "/chat-messages",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Create Chat Message with Files")
    func testCreateChatMessageWithFiles() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let files = [
            APIFile(
                type: .image,
                transferMethod: .remoteUrl,
                url: "https://example.com/image.png"
            )
        ]
        
        let response = try await client.createChatMessage(
            inputs: [:],
            query: "What's in this image?",
            user: "user-123",
            files: files
        )
        
        #expect(!response.messageId.isEmpty)
        
        // Verify request body contains files
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/chat-messages") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
           let filesArray = bodyJSON["files"] as? [[String: Any]] {
            #expect(filesArray.count == 1)
            #expect(filesArray[0]["type"] as? String == "image")
            #expect(filesArray[0]["transfer_method"] as? String == "remote_url")
        }
    }
    
    @Test("Create Streaming Chat Message")
    func testCreateStreamingChatMessage() async throws {
        // Register streaming mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(MockDataProvider.streamingChatEvents)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let stream = try await client.createStreamingChatMessage(
            inputs: [:],
            query: "Hello",
            user: "user-123"
        )
        
        var events: [StreamingChatMessageResponse] = []
        do {
            for try await event in stream {
                events.append(event)
                if events.count >= 7 { // We have 7 events in the mock data
                    break
                }
            }
        } catch {
            print("Streaming error: \(error)")
            throw error
        }
        
        #expect(events.count == 7)
        
        // Verify message events
        let messageEvents = events.compactMap { event -> MessageStreamEvent? in
            if case .message(let msg) = event { return msg }
            return nil
        }
        #expect(messageEvents.count == 6)
        
        // Verify the accumulated answer
        let fullAnswer = messageEvents.map { $0.answer }.joined()
        #expect(fullAnswer == "Hello! How can I help?")
        
        // Verify message_end event
        let endEvents = events.compactMap { event -> MessageEndStreamEvent? in
            if case .messageEnd(let end) = event { return end }
            return nil
        }
        #expect(endEvents.count == 1)
        #expect(endEvents.first?.metadata.usage?.totalTokens == 1168)
    }
    
    @Test("Stop Chat Generation")
    func testStopChatGeneration() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages/task-123/stop",
            response: MockResponse.json(["result": "success"])
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.stopChatGeneration(
            taskId: "task-123",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            method: "POST",
            urlPattern: "/chat-messages/task-123/stop"
        )
    }
    
    @Test("Get Conversation Messages")
    func testGetConversationMessages() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/messages",
            response: MockResponse.json(MockDataProvider.messageHistory)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.getConversationMessages(
            conversationId: "conv-123",
            user: "user-123",
            limit: 20
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "a076a87f-31e5-48dc-b452-0061adbbc922")
        #expect(response.data[0].query == "Hello")
        #expect(response.data[0].answer == "Hi there! How can I help you today?")
        #expect(response.hasMore == false)
        
        // Verify request parameters
        TestUtilities.assertRequestCaptured(
            method: "GET",
            urlPattern: "/messages"
        )
    }
    
    @Test("Get Suggested Questions")
    func testGetSuggestedQuestions() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/messages/msg-123/suggested",
            response: MockResponse.json(MockDataProvider.suggestedQuestions)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.getSuggestedQuestions(
            messageId: "msg-123",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        #expect(response.data.count == 3)
        #expect(response.data[0] == "What is machine learning?")
        #expect(response.data[1] == "How does AI work?")
        #expect(response.data[2] == "Can you explain neural networks?")
    }
    
    @Test("Send Message Feedback")
    func testSendMessageFeedback() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/messages/msg-123/feedbacks",
            response: MockResponse.json(["result": "success"])
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.sendMessageFeedback(
            messageId: "msg-123",
            rating: "like",
            user: "user-123",
            content: "Very helpful response!"
        )
        
        #expect(response.result == "success")
        
        // Verify request body
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/feedbacks") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["rating"] as? String == "like")
            #expect(bodyJSON["user"] as? String == "user-123")
            #expect(bodyJSON["content"] as? String == "Very helpful response!")
        }
    }
    
    @Test("Get Application Feedbacks")
    func testGetApplicationFeedbacks() async throws {
        // Register mock response
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "feedback-123",
                    "app_id": "app-123",
                    "conversation_id": "conv-123",
                    "message_id": "msg-123",
                    "rating": "like",
                    "content": "Great app!",
                    "from_source": "api",
                    "from_end_user_id": "user-123",
                    "from_account_id": nil,
                    "created_at": "2024-01-01T00:00:00Z",
                    "updated_at": "2024-01-01T00:00:00Z"
                ]
            ]
        ]
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/app/feedbacks",
            response: MockResponse.json(mockResponse)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.getApplicationFeedbacks(page: 1, limit: 20)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "feedback-123")
        #expect(response.data[0].rating == "like")
    }
    
    @Test("Get Conversation Variables")
    func testGetConversationVariables() async throws {
        // Register mock response
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "var-1",
                    "name": "user_name",
                    "value_type": "string",
                    "value": "Alice",
                    "description": "User's name",
                    "created_at": 1234567890,
                    "updated_at": 1234567890
                ],
                [
                    "id": "var-2",
                    "name": "user_preference",
                    "value_type": "string",
                    "value": "dark_mode",
                    "description": "User's preference",
                    "created_at": 1234567890,
                    "updated_at": 1234567890
                ]
            ],
            "has_more": false,
            "limit": 20
        ]
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/conversations/conv-123/variables",
            response: MockResponse.json(mockResponse)
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let response = try await client.getConversationVariables(
            conversationId: "conv-123",
            user: "user-123"
        )
        
        #expect(response.data.count == 2)
        #expect(response.data[0].name == "user_name")
        #expect(response.data[0].value == "Alice")
        #expect(response.hasMore == false)
    }
    
    @Test("Audio to Text")
    func testAudioToText() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/audio-to-text",
            response: MockResponse.json(["text": "Hello, this is the transcribed text."])
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let audioData = TestUtilities.createTestAudioData()
        let response = try await client.audioToText(
            audioFile: audioData,
            user: "user-123"
        )
        
        #expect(response.text == "Hello, this is the transcribed text.")
    }
    
    @Test("Text to Audio")
    func testTextToAudio() async throws {
        // Register mock response with audio data
        let mockAudioData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // Simplified audio data
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "audio/mpeg"],
                data: mockAudioData
            )
        )
        
        let client = TestUtilities.createTestChatClient()
        
        let audioData = try await client.textToAudio(
            text: "Hello, world!",
            user: "user-123"
        )
        
        #expect(audioData.count == 4)
        #expect(audioData == mockAudioData)
    }
    
    @Test("Error Handling - Invalid Conversation")
    func testErrorHandlingInvalidConversation() async throws {
        // Register error response
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/messages",
            response: MockResponse.error(
                statusCode: 404,
                code: "conversation_not_found",
                message: "Conversation not found"
            )
        )
        
        let client = TestUtilities.createTestChatClient()
        
        await assertThrowsError({
            _ = try await client.getConversationMessages(
                conversationId: "invalid-conv",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(404, "Conversation not found"))
    }
    
    @Test("Error Handling - Rate Limit")
    func testErrorHandlingRateLimit() async throws {
        // Register rate limit error
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.error(
                statusCode: 429,
                code: "rate_limit_exceeded",
                message: "Rate limit exceeded"
            )
        )
        
        let client = TestUtilities.createTestChatClient()
        
        await assertThrowsError({
            _ = try await client.createChatMessage(
                inputs: [:],
                query: "Hello",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(429, "Rate limit exceeded"))
    }
}