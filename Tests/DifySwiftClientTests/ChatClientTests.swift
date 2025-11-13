import Foundation
import Testing
@testable import DifySwiftClient

@Suite("ChatClient Tests")
final class ChatClientTests: DifyTestCase, @unchecked Sendable {
    
    @Test("Client Initialization")
    func testChatClientInitialization() async throws {
        let client = try ChatClient(apiKey: "test-key")
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create Chat Message")
    func testCreateChatMessage() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
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
            in: mockSession,
            method: "POST",
            urlPattern: "/chat-messages",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Create Chat Message with Files")
    func testCreateChatMessageWithFiles() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
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
        let capturedRequests = mockSession.getCapturedRequests()
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
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register streaming mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(MockDataProvider.streamingChatEvents)
        )
        
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
        let messageEvents = events.compactMap { $0.message }
        #expect(messageEvents.count == 6)
        
        // Verify the accumulated answer
        let fullAnswer = messageEvents.map { $0.answer }.joined()
        #expect(fullAnswer == "Hello! How can I help?")
        
        // Verify message_end event
        let endEvents = events.compactMap { $0.messageEnd }
        #expect(endEvents.count == 1)
        #expect(endEvents.first?.metadata.usage?.totalTokens == 1168)
    }
    
    @Test("Stop Chat Generation")
    func testStopChatGeneration() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages/task-123/stop",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.stopChatGeneration(
            taskId: "task-123",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/chat-messages/task-123/stop"
        )
    }
    
    @Test("Get Conversation Messages")
    func testGetConversationMessages() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/messages",
            response: MockResponse.json(MockDataProvider.messageHistory)
        )
        
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
            in: mockSession,
            method: "GET",
            urlPattern: "/messages"
        )
    }
    
    @Test("Get Suggested Questions")
    func testGetSuggestedQuestions() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/messages/msg-123/suggested",
            response: MockResponse.json(MockDataProvider.suggestedQuestions)
        )
        
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
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/messages/msg-123/feedbacks",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.sendMessageFeedback(
            messageId: "msg-123",
            rating: "like",
            user: "user-123",
            content: "Very helpful response!"
        )
        
        #expect(response.result == "success")
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
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
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
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
        mockSession.register(
            method: "GET",
            urlPattern: "/app/feedbacks",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationFeedbacks(page: 1, limit: 20)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "feedback-123")
        #expect(response.data[0].rating == "like")
    }
    
    @Test("Get Conversation Variables")
    func testGetConversationVariables() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
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
        mockSession.register(
            method: "GET",
            urlPattern: "/conversations/conv-123/variables",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getConversationVariables(
            conversationId: "conv-123",
            user: "user-123"
        )
        
        #expect(response.data.count == 2)
        #expect(response.data[0].name == "user_name")
        #expect(response.data[0].value.value as? String == "Alice")
        #expect(response.hasMore == false)
    }

    @Test("Create Chat Message encodes workflow_id and trace_id")
    func testCreateChatMessage_encodesWorkflowAndTraceIds() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        mockSession.register(method: "POST", urlPattern: "/chat-messages", response: MockResponse.json(MockDataProvider.chatMessageResponse))
        _ = try await client.createChatMessage(
            inputs: ["name": "Alice"],
            query: "Hello",
            user: "user-123",
            workflowId: "wf-001",
            traceId: "trace-abc"
        )
        let req = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/chat-messages") ?? false }
        #expect(req != nil)
        if let req = req, let body = req.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            #expect(json["workflow_id"] as? String == "wf-001")
            #expect(json["trace_id"] as? String == "trace-abc")
        }
    }

    @Test("Create Streaming Chat Message encodes workflow_id and trace_id")
    func testCreateStreamingChatMessage_encodesWorkflowAndTraceIds() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(MockDataProvider.streamingChatEvents)
        )
        _ = try await client.createStreamingChatMessage(
            inputs: [:],
            query: "Hello",
            user: "user-123",
            workflowId: "wf-002",
            traceId: "trace-def"
        )
        let req = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/chat-messages") ?? false }
        #expect(req != nil)
        if let req = req, let body = req.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            #expect(json["workflow_id"] as? String == "wf-002")
            #expect(json["trace_id"] as? String == "trace-def")
        }
    }

    @Test("Update Conversation Variable - success")
    func testUpdateConversationVariable_success() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        let mockResponse: [String: Any] = [
            "id": "var-1",
            "name": "user_name",
            "value_type": "string",
            "value": "Bob",
            "description": "User's name",
            "created_at": 1234567890,
            "updated_at": 1234567891
        ]
        mockSession.register(method: "PUT", urlPattern: "/conversations/conv-1/variables/var-1", response: MockResponse.json(mockResponse))
        let updated = try await client.updateConversationVariable(conversationId: "conv-1", variableId: "var-1", value: AnyCodable("Bob"), user: "user-123")
        #expect(updated.id == "var-1")
        #expect(updated.value.value as? String == "Bob")
        // Verify body
        let req = mockSession.getCapturedRequests().first { $0.httpMethod == "PUT" && ($0.url?.absoluteString.contains("/conversations/conv-1/variables/var-1") ?? false) }
        #expect(req != nil)
        if let req = req, let body = req.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            #expect(json["value"] as? String == "Bob")
            #expect(json["user"] as? String == "user-123")
        }
    }

    @Test("Update Conversation Variable - type mismatch error")
    func testUpdateConversationVariable_typeMismatchError() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        mockSession.register(
            method: "PUT",
            urlPattern: "/conversations/conv-1/variables/var-2",
            response: MockResponse.error(statusCode: 400, code: "invalid_variable_type", message: "Value type mismatch")
        )
        await assertThrowsError({
            _ = try await client.updateConversationVariable(conversationId: "conv-1", variableId: "var-2", value: AnyCodable(["x": 1]), user: "user-123")
        }, expectedError: DifyError.httpError(400, "Value type mismatch"))
    }

    @Test("Get Conversation Variables with variable_name filter")
    func testGetConversationVariables_withVariableNameFilter() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        let mockResponse: [String: Any] = [
            "data": [],
            "has_more": false,
            "limit": 20
        ]
        mockSession.register(method: "GET", urlPattern: "/conversations/conv-2/variables", response: MockResponse.json(mockResponse))
        _ = try await client.getConversationVariables(conversationId: "conv-2", user: "user-123", variableName: "user_name")
        let req = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/conversations/conv-2/variables") ?? false }
        if let url = req?.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let items = components.queryItems {
            #expect(items.contains { $0.name == "variable_name" && $0.value == "user_name" })
        }
    }

    @Test("AgentThoughtStreamEvent decoding")
    func testAgentThoughtStreamEvent_decoding() throws {
        let json = """
        {
          "event": "agent_thought",
          "id": "thought-1",
          "task_id": "task-1",
          "message_id": "msg-1",
          "position": 1,
          "thought": "Searching docs",
          "observation": "Found 2 docs",
          "tool": "search",
          "tool_input": "keyword=swift",
          "created_at": 1700000000,
          "message_files": ["file-1", "file-2"],
          "conversation_id": "conv-1"
        }
        """.data(using: .utf8)!
        let event = try JSONDecoder.difyDecoder.decode(StreamingChatMessageResponse.self, from: json)
        #expect(event.kind == .agentThought)
        #expect(event.agentThought?.id == "thought-1")
        #expect(event.agentThought?.tool == "search")
        #expect(event.agentThought?.messageFiles?.count == 2)
    }

    @Test("Upload File")
    func testUploadFile() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()

        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )

        let payload = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: payload,
            fileName: "grounding.png",
            user: "user-123"
        )

        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
        #expect(response.mimeType == "image/png")

        // Ensure request hit the correct endpoint
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/files/upload"
        )
    }

    @Test("Upload File Custom MIME")
    func testUploadFileCustomMimeType() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()

        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )

        let payload = TestUtilities.createTestImageData()
        _ = try await client.uploadFile(
            fileData: payload,
            fileName: "vector.svg",
            user: "user-123",
            mimeType: "image/svg+xml"
        )

        // Verify the multipart request carries our explicit MIME type
        let request = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/files/upload") ?? false }
        #expect(request != nil)
        if let req = request,
           let contentType = req.value(forHTTPHeaderField: "Content-Type") {
            #expect(contentType.contains("multipart/form-data"))
        }
    }

    @Test("Preview File via ChatClient")
    func testPreviewFile_viaChatClient() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        let bytes = Data([0x01, 0x02, 0x03])
        mockSession.register(method: "GET", urlPattern: "/files/file-123/preview", response: MockResponse(statusCode: 200, headers: [:], data: bytes))
        let data = try await client.previewFile(fileId: "file-123", asAttachment: true)
        #expect(data == bytes)
        // Verify as_attachment param present
        let req = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/files/file-123/preview") ?? false }
        if let url = req?.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let items = components.queryItems {
            #expect(items.contains { $0.name == "as_attachment" && $0.value == "true" })
        }
    }
    
    @Test("Audio to Text")
    func testAudioToText() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/audio-to-text",
            response: MockResponse.json(["text": "Hello, this is the transcribed text."])
        )
        
        let audioData = TestUtilities.createTestAudioData()
        let response = try await client.audioToText(
            audioFile: audioData,
            user: "user-123"
        )
        
        #expect(response.text == "Hello, this is the transcribed text.")
    }
    
    @Test("Text to Audio")
    func testTextToAudio() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response with audio data
        let mockAudioData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // Simplified audio data
        mockSession.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "audio/mpeg"],
                data: mockAudioData
            )
        )
        
        let audioData = try await client.textToAudio(
            text: "Hello, world!",
            user: "user-123"
        )
        
        #expect(audioData.count == 4)
        #expect(audioData == mockAudioData)
    }
    
    @Test("Error Handling - Invalid Conversation")
    func testErrorHandlingInvalidConversation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register error response
        mockSession.register(
            method: "GET",
            urlPattern: "/messages",
            response: MockResponse.error(
                statusCode: 404,
                code: "conversation_not_found",
                message: "Conversation not found"
            )
        )
        
        await assertThrowsError({
            _ = try await client.getConversationMessages(
                conversationId: "invalid-conv",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(404, "Conversation not found"))
    }
    
    @Test("Error Handling - Rate Limit")
    func testErrorHandlingRateLimit() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register rate limit error
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.error(
                statusCode: 429,
                code: "rate_limit_exceeded",
                message: "Rate limit exceeded"
            )
        )
        
        await assertThrowsError({
            _ = try await client.createChatMessage(
                inputs: [:],
                query: "Hello",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(429, "Rate limit exceeded"))
    }
    
    @Test("Get Application Info")
    func testGetApplicationInfo() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "name": "Test App",
            "description": "A test application",
            "tags": ["ai", "chat"],
            "mode": "chat",
            "author_name": "Test Author"
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/info",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "Test App")
        #expect(response.description == "A test application")
        #expect(response.tags.count == 2)
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test("Get Application Parameters")
    func testGetApplicationParameters() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "opening_statement": "Welcome to our app!",
            "suggested_questions": ["What can you do?", "How does this work?"],
            "suggested_questions_after_answer": ["enabled": true],
            "speech_to_text": ["enabled": true],
            "text_to_speech": ["enabled": false],
            "retriever_resource": ["enabled": true],
            "annotation_reply": ["enabled": false],
            "user_input_form": [
                ["paragraph": [
                    "label": "Query",
                    "variable": "query",
                    "required": true,
                    "max_length": 1000,
                    "default": ""
                ]]
            ],
            "file_upload": [
                "image": [
                    "enabled": true,
                    "number_limits": 5,
                    "transfer_methods": ["local_file", "remote_url"]
                ]
            ],
            "system_parameters": [
                "image_file_size_limit": 10,
                "video_file_size_limit": 50,
                "audio_file_size_limit": 20,
                "file_size_limit": 15
            ]
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/parameters",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationParameters(user: "user-123")
        
        #expect(response.openingStatement == "Welcome to our app!")
        #expect(response.suggestedQuestions?.count == 2)
        #expect(response.speechToText?.enabled == true)
        #expect(response.fileUpload?.image?.enabled == true)
        #expect(response.fileUpload?.image?.numberLimits == 5)
        #expect(response.systemParameters?.imageFileSizeLimit == 10)
    }
    
    @Test("Get Application Meta")
    func testGetApplicationMeta() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "tool_icons": [
                "dalle2": ["background": "#FEE2E2", "content": "🎨"],
                "api_tool": "https://example.com/icon.png"
            ]
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/meta",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationMeta()
        
        #expect(response.toolIcons.count == 2)
        
        // Check emoji icon
        if let icon = response.toolIcons["dalle2"] {
            #expect(icon.emoji?.background == "#FEE2E2")
            #expect(icon.emoji?.content == "🎨")
        } else { throw TestError("Expected emoji icon for dalle2") }
        
        // Check URL icon
        if let icon = response.toolIcons["api_tool"] {
            #expect(icon.url == "https://example.com/icon.png")
        } else { throw TestError("Expected URL icon for api_tool") }
    }
    
    @Test("Get Application WebApp Settings")
    func testGetApplicationWebAppSettings() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "title": "My App",
            "icon": "🤖",
            "icon_background": "#FF6B6B",
            "description": "An AI assistant",
            "copyright": "© 2024 My Company",
            "privacy_policy": "https://example.com/privacy",
            "custom_disclaimer": "Use at your own risk",
            "show_workflow_steps": true,
            "chat_color_theme": "#4C9AFF",
            "chat_color_theme_inverted": false,
            "icon_type": "emoji",
            "default_language": "en-US",
            "use_icon_as_answer_icon": false
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/site",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationWebAppSettings()
        
        #expect(response.title == "My App")
        #expect(response.icon == "🤖")
        #expect(response.iconBackground == "#FF6B6B")
        #expect(response.description == "An AI assistant")
        #expect(response.copyright == "© 2024 My Company")
        #expect(response.privacyPolicy == "https://example.com/privacy")
        #expect(response.customDisclaimer == "Use at your own risk")
        #expect(response.showWorkflowSteps == true)
        #expect(response.chatColorTheme == "#4C9AFF")
        #expect(response.chatColorThemeInverted == false)
        #expect(response.iconType == "emoji")
        #expect(response.defaultLanguage == "en-US")
        #expect(response.useIconAsAnswerIcon == false)
    }
    
    @Test("Get Annotations")
    func testGetAnnotations() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "annotation-1",
                    "app_id": "app-123",
                    "account_id": "account-1",
                    "question": "What is AI?",
                    "answer": "AI stands for Artificial Intelligence",
                    "hit_count": 5,
                    "created_at": 1234567890,
                    "updated_at": 1234567890
                ],
                [
                    "id": "annotation-2",
                    "app_id": "app-123",
                    "account_id": "account-1",
                    "question": "How does machine learning work?",
                    "answer": "Machine learning is a subset of AI...",
                    "hit_count": 10,
                    "created_at": 1234567890,
                    "updated_at": 1234567890
                ]
            ],
            "has_more": false,
            "page": 1,
            "limit": 20,
            "total": 2
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/apps/annotations",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getAnnotations(page: 1, limit: 20)
        
        #expect(response.data.count == 2)
        #expect(response.data[0].id == "annotation-1")
        #expect(response.data[0].question == "What is AI?")
        #expect(response.data[0].answer == "AI stands for Artificial Intelligence")
        #expect(response.data[0].hitCount == 5)
        #expect(response.data[1].id == "annotation-2")
        #expect(response.data[1].hitCount == 10)
        #expect(response.hasMore == false)
        #expect(response.total == 2)
    }
    
    @Test("Create Annotation")
    func testCreateAnnotation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "id": "new-annotation",
            "app_id": "app-123",
            "account_id": "account-1",
            "question": "What is Swift?",
            "answer": "Swift is a programming language by Apple",
            "hit_count": 0,
            "created_at": 1234567890,
            "updated_at": 1234567890
        ]
        mockSession.register(
            method: "POST",
            urlPattern: "/apps/annotations",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.createAnnotation(
            question: "What is Swift?",
            answer: "Swift is a programming language by Apple"
        )
        
        #expect(response.id == "new-annotation")
        #expect(response.question == "What is Swift?")
        #expect(response.answer == "Swift is a programming language by Apple")
        #expect(response.hitCount == 0)
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/apps/annotations") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["question"] as? String == "What is Swift?")
            #expect(bodyJSON["answer"] as? String == "Swift is a programming language by Apple")
        }
    }
    
    @Test("Update Annotation")
    func testUpdateAnnotation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "id": "annotation-1",
            "app_id": "app-123",
            "account_id": "account-1",
            "question": "What is Swift?",
            "answer": "Swift is a modern programming language developed by Apple",
            "hit_count": 5,
            "created_at": 1234567890,
            "updated_at": 1234567900
        ]
        mockSession.register(
            method: "PUT",
            urlPattern: "/apps/annotations/annotation-1",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.updateAnnotation(
            annotationId: "annotation-1",
            question: "What is Swift?",
            answer: "Swift is a modern programming language developed by Apple"
        )
        
        #expect(response.id == "annotation-1")
        #expect(response.answer == "Swift is a modern programming language developed by Apple")
        #expect(response.createdAt == 1234567890)
    }
    
    @Test("Delete Annotation")
    func testDeleteAnnotation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "DELETE",
            urlPattern: "/apps/annotations/annotation-1",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.deleteAnnotation(annotationId: "annotation-1")
        
        #expect(response.result == "success")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "DELETE",
            urlPattern: "/apps/annotations/annotation-1"
        )
    }
    
    @Test("Configure Annotation Reply")
    func testConfigureAnnotationReply() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "job_id": "job-123",
            "job_status": "processing"
        ]
        mockSession.register(
            method: "POST",
            urlPattern: "/apps/annotation-reply/enable",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.configureAnnotationReply(
            action: "enable",
            embeddingModelProvider: "openai",
            embeddingModel: "text-embedding-ada-002",
            scoreThreshold: 0.8
        )
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "processing")
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/annotation-reply/enable") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["embedding_model_provider"] as? String == "openai")
            #expect(bodyJSON["embedding_model"] as? String == "text-embedding-ada-002")
            #expect(bodyJSON["score_threshold"] as? Double == 0.8)
        }
    }
    
    @Test("Configure Annotation Reply - Disable")
    func testConfigureAnnotationReplyDisable() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "job_id": "job-456",
            "job_status": "completed"
        ]
        mockSession.register(
            method: "POST",
            urlPattern: "/apps/annotation-reply/disable",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.configureAnnotationReply(action: "disable")
        
        #expect(response.jobId == "job-456")
        #expect(response.jobStatus == "completed")
    }
    
    @Test("Get Annotation Reply Job Status")
    func testGetAnnotationReplyJobStatus() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "job_id": "job-123",
            "job_status": "completed",
            "created_at": 1234567890,
            "completed_at": 1234567900,
            "error_msg": ""
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/apps/annotation-reply/enable/status/job-123",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getAnnotationReplyJobStatus(
            action: "enable",
            jobId: "job-123"
        )
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "completed")
        #expect(response.errorMsg == "")
    }
    
    @Test("Get Conversations")
    func testGetConversations() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "conv-1",
                    "name": "First Conversation",
                    "inputs": ["user_name": "Alice"],
                    "introduction": "Hello!",
                    "status": "normal",
                    "created_at": 1234567890
                ],
                [
                    "id": "conv-2",
                    "name": "Second Conversation",
                    "inputs": ["user_name": "Bob"],
                    "introduction": "Hi there!",
                    "status": "normal",
                    "created_at": 1234567880
                ]
            ],
            "has_more": true,
            "limit": 20
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/conversations",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getConversations(
            user: "user-123",
            limit: 20,
            sortBy: "-updated_at"
        )
        
        #expect(response.data.count == 2)
        #expect(response.data[0].id == "conv-1")
        #expect(response.data[0].name == "First Conversation")
        #expect(response.data[0].inputs?["user_name"] == "Alice")
        #expect(response.data[1].id == "conv-2")
        #expect(response.hasMore == true)
        
        // Verify request parameters
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/conversations") ?? false }
        #expect(request != nil)
        
        if let url = request?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            #expect(queryItems.contains { $0.name == "user" && $0.value == "user-123" })
            #expect(queryItems.contains { $0.name == "limit" && $0.value == "20" })
            #expect(queryItems.contains { $0.name == "sort_by" && $0.value == "-updated_at" })
        }
    }
    
    @Test("Get Conversations with Last ID")
    func testGetConversationsWithLastId() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "conv-3",
                    "name": "Third Conversation",
                    "inputs": [:],
                    "introduction": "",
                    "status": "normal",
                    "created_at": 1234567870
                ]
            ],
            "has_more": false,
            "limit": 20
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/conversations",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getConversations(
            user: "user-123",
            lastId: "conv-2"
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "conv-3")
        #expect(response.hasMore == false)
        
        // Verify last_id parameter
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/conversations") ?? false }
        if let url = request?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            #expect(queryItems.contains { $0.name == "last_id" && $0.value == "conv-2" })
        }
    }
    
    @Test("Rename Conversation")
    func testRenameConversation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "id": "conv-1",
            "name": "Renamed Conversation",
            "inputs": [:],
            "introduction": "",
            "created_at": 1234567890,
            "status": "normal"
        ]
        mockSession.register(
            method: "POST",
            urlPattern: "/conversations/conv-1/name",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.renameConversation(
            conversationId: "conv-1",
            name: "Renamed Conversation",
            user: "user-123"
        )
        
        #expect(response.id == "conv-1")
        #expect(response.name == "Renamed Conversation")
        #expect(response.createdAt == 1234567890)
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/conversations/conv-1/name") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["name"] as? String == "Renamed Conversation")
            #expect(bodyJSON["user"] as? String == "user-123")
        }
    }
    
    @Test("Rename Conversation with Auto Generate")
    func testRenameConversationAutoGenerate() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "id": "conv-1",
            "name": "Auto-generated Title",
            "inputs": [:],
            "introduction": "",
            "created_at": 1234567890,
            "status": "normal"
        ]
        mockSession.register(
            method: "POST",
            urlPattern: "/conversations/conv-1/name",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.renameConversation(
            conversationId: "conv-1",
            autoGenerate: true,
            user: "user-123"
        )
        
        #expect(response.name == "Auto-generated Title")
        #expect(response.createdAt == 1234567890)
        
        // Verify request body has auto_generate
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/conversations/conv-1/name") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["auto_generate"] as? Bool == true)
            #expect(bodyJSON["user"] as? String == "user-123")
        }
    }
    
    @Test("Delete Conversation")
    func testDeleteConversation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "DELETE",
            urlPattern: "/conversations/conv-1",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.deleteConversation(
            conversationId: "conv-1",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/conversations/conv-1") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["user"] as? String == "user-123")
        }
    }
    
    @Test("Create Chat Message with Auto Generate Name")
    func testCreateChatMessageWithAutoGenerateName() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
        let response = try await client.createChatMessage(
            inputs: [:],
            query: "Hello",
            user: "user-123",
            autoGenerateName: false
        )
        
        #expect(!response.messageId.isEmpty)
        
        // Verify request body contains autoGenerateName
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/chat-messages") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["auto_generate_name"] as? Bool == false)
        }
    }
    
    @Test("Get Conversation Messages with First ID")
    func testGetConversationMessagesWithFirstId() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/messages",
            response: MockResponse.json(MockDataProvider.messageHistory)
        )
        
        let response = try await client.getConversationMessages(
            conversationId: "conv-123",
            user: "user-123",
            firstId: "msg-first"
        )
        
        #expect(response.data.count > 0)
        
        // Verify first_id parameter
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/messages") ?? false }
        if let url = request?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            #expect(queryItems.contains { $0.name == "first_id" && $0.value == "msg-first" })
        }
    }
    
    @Test("Get Conversation Variables with Last ID")
    func testGetConversationVariablesWithLastId() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "var-3",
                    "name": "next_variable",
                    "value_type": "string",
                    "value": "next value",
                    "description": "Next variable",
                    "created_at": 1234567890,
                    "updated_at": 1234567890
                ]
            ],
            "has_more": false,
            "limit": 20
        ]
        mockSession.register(
            method: "GET",
            urlPattern: "/conversations/conv-123/variables",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getConversationVariables(
            conversationId: "conv-123",
            user: "user-123",
            lastId: "var-2"
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "var-3")
        
        // Verify last_id parameter
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/variables") ?? false }
        if let url = request?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            #expect(queryItems.contains { $0.name == "last_id" && $0.value == "var-2" })
        }
    }
    
    @Test("Text to Audio with Message ID")
    func testTextToAudioWithMessageId() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response with audio data
        let mockAudioData = Data([0xFF, 0xFB, 0x90, 0x00]) // MP3 header
        mockSession.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "audio/mpeg"],
                data: mockAudioData
            )
        )
        
        let audioData = try await client.textToAudio(
            messageId: "msg-123",
            user: "user-123"
        )
        
        #expect(audioData == mockAudioData)
        
        // Verify request body contains messageId
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/text-to-audio") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["message_id"] as? String == "msg-123")
            #expect(bodyJSON["text"] == nil)
            #expect(bodyJSON["user"] as? String == "user-123")
        }
    }
    
    @Test("Send Message Feedback with Null Rating")
    func testSendMessageFeedbackWithNullRating() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/messages/msg-123/feedbacks",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.sendMessageFeedback(
            messageId: "msg-123",
            rating: nil,
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request body has null rating
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/feedbacks") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["rating"] == nil || bodyJSON["rating"] is NSNull)
            #expect(bodyJSON["user"] as? String == "user-123")
            #expect(bodyJSON["content"] == nil || bodyJSON["content"] is NSNull)
        }
    }
    
    @Test("Create Streaming Chat Message with Auto Generate Name")
    func testCreateStreamingChatMessageWithAutoGenerateName() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register streaming mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/chat-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(MockDataProvider.streamingChatEvents)
        )
        
        let stream = try await client.createStreamingChatMessage(
            inputs: [:],
            query: "Hello",
            user: "user-123",
            autoGenerateName: true
        )
        
        var eventCount = 0
        for try await _ in stream {
            eventCount += 1
            if eventCount >= 7 { break }
        }
        
        #expect(eventCount == 7)
        
        // Verify request body contains autoGenerateName
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/chat-messages") ?? false }
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["auto_generate_name"] as? Bool == true)
        }
    }
    
    @Test("Error Handling - Invalid Annotation")
    func testErrorHandlingInvalidAnnotation() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register error response
        mockSession.register(
            method: "DELETE",
            urlPattern: "/apps/annotations/invalid-id",
            response: MockResponse.error(
                statusCode: 404,
                code: "annotation_not_found",
                message: "Annotation not found"
            )
        )
        
        await assertThrowsError({
            _ = try await client.deleteAnnotation(annotationId: "invalid-id")
        }, expectedError: DifyError.httpError(404, "Annotation not found"))
    }
    
    @Test("Error Handling - Invalid Application")
    func testErrorHandlingInvalidApplication() async throws {
        let (client, mockSession) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register error response
        mockSession.register(
            method: "GET",
            urlPattern: "/info",
            response: MockResponse.error(
                statusCode: 403,
                code: "forbidden",
                message: "Access denied"
            )
        )
        
        await assertThrowsError({
            _ = try await client.getApplicationInfo()
        }, expectedError: DifyError.httpError(403, "Access denied"))
    }
}
