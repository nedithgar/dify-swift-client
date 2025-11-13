import Testing
import Foundation
@testable import DifySwiftClient

// MARK: - Open String Wrapper Tests

struct OpenStringWrapperTests {
    @Test func testResponseModeRawValues() throws {
        #expect(ResponseMode.blocking.rawValue == "blocking")
        #expect(ResponseMode.streaming.rawValue == "streaming")

        let unknown = ResponseMode(rawValue: "future_mode")
        // round-trip through codable
        let data = try JSONEncoder.difyEncoder.encode(["response_mode": unknown.rawValue])
        let decoded = try JSONDecoder.difyDecoder.decode([String: String].self, from: data)
        #expect(decoded["response_mode"] == "future_mode")
    }

    @Test func testFileTransferMethodRawValues() throws {
        #expect(FileTransferMethod.remoteUrl.rawValue == "remote_url")
        #expect(FileTransferMethod.localFile.rawValue == "local_file")

        let unknown = FileTransferMethod(rawValue: "new_method")
        let data = try JSONEncoder.difyEncoder.encode(["transfer_method": unknown.rawValue])
        let decoded = try JSONDecoder.difyDecoder.decode([String: String].self, from: data)
        #expect(decoded["transfer_method"] == "new_method")
    }

    @Test func testFileTypeRawValues() throws {
        #expect(FileType.document.rawValue == "document")
        #expect(FileType.image.rawValue == "image")
        #expect(FileType.audio.rawValue == "audio")
        #expect(FileType.video.rawValue == "video")
        #expect(FileType.custom.rawValue == "custom")

        let unknown = FileType(rawValue: "vector")
        let data = try JSONEncoder.difyEncoder.encode(["type": unknown.rawValue])
        let decoded = try JSONDecoder.difyDecoder.decode([String: String].self, from: data)
        #expect(decoded["type"] == "vector")
    }
}

// MARK: - Simple Model Tests

struct SimpleModelTests {
    @Test func testAPIFileEncodingDecoding() throws {
        // Test with all properties
        let file = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/image.jpg",
            uploadFileId: "file123"
        )
        
        let encoded = try JSONEncoder.difyEncoder.encode(file)
        let decoded = try JSONDecoder.difyDecoder.decode(APIFile.self, from: encoded)
        
        #expect(decoded.type == .image)
        #expect(decoded.transferMethod == .remoteUrl)
        #expect(decoded.url == "https://example.com/image.jpg")
        #expect(decoded.uploadFileId == "file123")
        
        // Test JSON key mapping
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        #expect(json?["type"] as? String == "image")
        #expect(json?["transfer_method"] as? String == "remote_url")
        #expect(json?["url"] as? String == "https://example.com/image.jpg")
        #expect(json?["upload_file_id"] as? String == "file123")
        
        // Test with optional properties nil
        let minimalFile = APIFile(type: .document, transferMethod: .localFile)
        let minimalEncoded = try JSONEncoder.difyEncoder.encode(minimalFile)
        let minimalDecoded = try JSONDecoder.difyDecoder.decode(APIFile.self, from: minimalEncoded)
        
        #expect(minimalDecoded.type == .document)
        #expect(minimalDecoded.transferMethod == .localFile)
        #expect(minimalDecoded.url == nil)
        #expect(minimalDecoded.uploadFileId == nil)
    }
    
    @Test func testBaseResponse() throws {
        let response = BaseResponse(result: "success")
        let encoded = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(BaseResponse.self, from: encoded)
        
        #expect(decoded.result == "success")
        
        // Test with nil result
        let nilResponse = BaseResponse(result: nil)
        let nilEncoded = try JSONEncoder.difyEncoder.encode(nilResponse)
        let nilDecoded = try JSONDecoder.difyDecoder.decode(BaseResponse.self, from: nilEncoded)
        
        #expect(nilDecoded.result == nil)
    }
    
    @Test func testProcessRule() throws {
        let rule = ProcessRule(mode: "auto", rules: ["key": "value"])
        let encoded = try JSONEncoder.difyEncoder.encode(rule)
        let decoded = try JSONDecoder.difyDecoder.decode(ProcessRule.self, from: encoded)
        
        #expect(decoded.mode == "auto")
        #expect(decoded.rules?["key"] == "value")
        
        // Test with nil rules
        let simpleRule = ProcessRule(mode: "manual")
        let simpleEncoded = try JSONEncoder.difyEncoder.encode(simpleRule)
        let simpleDecoded = try JSONDecoder.difyDecoder.decode(ProcessRule.self, from: simpleEncoded)
        
        #expect(simpleDecoded.mode == "manual")
        #expect(simpleDecoded.rules == nil)
    }
}

// MARK: - Application Info Tests

struct ApplicationInfoTests {
    @Test func testApplicationInfoResponse() throws {
        let json = """
        {
            "name": "Test App",
            "description": "Test Description",
            "tags": ["tag1", "tag2"],
            "mode": "chat",
            "author_name": "Test Author"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: json)
        
        #expect(response.name == "Test App")
        #expect(response.description == "Test Description")
        #expect(response.tags == ["tag1", "tag2"])
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test func testApplicationParametersResponse() throws {
        let json = """
        {
            "opening_statement": "Welcome!",
            "suggested_questions": ["Question 1", "Question 2"],
            "suggested_questions_after_answer": {"enabled": true},
            "speech_to_text": {"enabled": false},
            "retriever_resource": {"enabled": true},
            "annotation_reply": {"enabled": false},
            "user_input_form": [
                {
                    "text-input": {
                        "label": "Name",
                        "variable": "name",
                        "required": true,
                        "default": "John"
                    }
                },
                {
                    "select": {
                        "label": "Country",
                        "variable": "country",
                        "required": false,
                        "default": "US",
                        "options": ["US", "UK", "CA"]
                    }
                }
            ],
            "file_upload": {
                "document": {"enabled": true, "number_limits": 2, "transfer_methods": ["remote_url"]},
                "image": {"enabled": true, "number_limits": 5, "transfer_methods": ["remote_url", "local_file"]},
                "audio": {"enabled": false, "number_limits": 0, "transfer_methods": []},
                "video": {"enabled": true, "number_limits": 1, "transfer_methods": ["local_file"]},
                "custom": {"enabled": false, "number_limits": 0, "transfer_methods": []}
            },
            "system_parameters": {
                "file_size_limit": 10485760,
                "image_file_size_limit": 5242880,
                "audio_file_size_limit": 15728640,
                "video_file_size_limit": 104857600
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationParametersResponse.self, from: json)
        
        #expect(response.openingStatement == "Welcome!")
        #expect(response.suggestedQuestions == ["Question 1", "Question 2"])
        #expect(response.suggestedQuestionsAfterAnswer?.enabled == true)
        #expect(response.speechToText?.enabled == false)
        #expect(response.retrieverResource?.enabled == true)
        #expect(response.annotationReply?.enabled == false)
        
        // Test user input form
        #expect(response.userInputForm?.count == 2)
        #expect(response.userInputForm?[0].textInput?.label == "Name")
        #expect(response.userInputForm?[0].textInput?.variable == "name")
        #expect(response.userInputForm?[0].textInput?.required == true)
        #expect(response.userInputForm?[0].textInput?.defaultValue == "John")
        
        #expect(response.userInputForm?[1].select?.label == "Country")
        #expect(response.userInputForm?[1].select?.options == ["US", "UK", "CA"])
        
        // Test file upload
    #expect(response.fileUpload?.document?.enabled == true)
    #expect(response.fileUpload?.document?.numberLimits == 2)
    #expect(response.fileUpload?.image?.enabled == true)
    #expect(response.fileUpload?.image?.numberLimits == 5)
    #expect(response.fileUpload?.audio?.enabled == false)
    #expect(response.fileUpload?.video?.enabled == true)
        
        // Test system parameters
        #expect(response.systemParameters?.fileSizeLimit == 10485760)
        #expect(response.systemParameters?.imageFileSizeLimit == 5242880)
    }
    
    @Test func testApplicationSiteResponse() throws {
        let json = """
        {
            "title": "My App",
            "chat_color_theme": "blue",
            "chat_color_theme_inverted": true,
            "icon_type": "emoji",
            "icon": "🚀",
            "icon_background": "#FFFFFF",
            "icon_url": "https://example.com/icon.png",
            "description": "App description",
            "copyright": "© 2024",
            "privacy_policy": "Privacy policy text",
            "custom_disclaimer": "Disclaimer text",
            "default_language": "en",
            "show_workflow_steps": true,
            "use_icon_as_answer_icon": false
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationSiteResponse.self, from: json)
        
        #expect(response.title == "My App")
        #expect(response.chatColorTheme == "blue")
        #expect(response.chatColorThemeInverted == true)
        #expect(response.iconType == "emoji")
        #expect(response.icon == "🚀")
        #expect(response.iconBackground == "#FFFFFF")
        #expect(response.iconUrl == "https://example.com/icon.png")
        #expect(response.description == "App description")
        #expect(response.copyright == "© 2024")
        #expect(response.privacyPolicy == "Privacy policy text")
        #expect(response.customDisclaimer == "Disclaimer text")
        #expect(response.defaultLanguage == "en")
        #expect(response.showWorkflowSteps == true)
        #expect(response.useIconAsAnswerIcon == false)
    }
}

// MARK: - File Upload Tests

struct FileUploadTests {
    @Test func testFileUploadResponse() throws {
        let json = """
        {
            "id": "file123",
            "name": "document.pdf",
            "size": 1024,
            "extension": "pdf",
            "mime_type": "application/pdf",
            "created_by": "user123",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(FileUploadResponse.self, from: json)
        
        #expect(response.id == "file123")
        #expect(response.name == "document.pdf")
        #expect(response.size == 1024)
        #expect(response.fileExtension == "pdf")
        #expect(response.mimeType == "application/pdf")
        #expect(response.createdBy == "user123")
        #expect(response.createdAt == 1704067200)
    }
}

// MARK: - Completion Model Tests

struct CompletionModelTests {
    @Test func testCompletionMessageResponse() throws {
        let json = """
        {
            "event": "message",
            "message_id": "msg123",
            "mode": "blocking",
            "answer": "This is the answer",
            "metadata": {
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 20,
                    "total_tokens": 30,
                    "prompt_unit_price": "0.001",
                    "prompt_price_unit": "0.001",
                    "prompt_price": "0.01",
                    "completion_unit_price": "0.002",
                    "completion_price_unit": "0.001",
                    "completion_price": "0.04",
                    "total_price": "0.05",
                    "currency": "USD",
                    "latency": 1.5
                },
                "retriever_resources": [
                    {
                        "position": 1,
                        "dataset_id": "dataset123",
                        "dataset_name": "Test Dataset",
                        "document_id": "doc123",
                        "document_name": "Test Document",
                        "segment_id": "seg123",
                        "score": 0.95,
                        "content": "Retrieved content"
                    }
                ]
            },
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(CompletionMessageResponse.self, from: json)
        
        #expect(response.event == "message")
        #expect(response.messageId == "msg123")
        #expect(response.mode == "blocking")
        #expect(response.answer == "This is the answer")
        #expect(response.createdAt == 1704067200)
        
        // Test metadata
        #expect(response.metadata?.usage?.promptTokens == 10)
        #expect(response.metadata?.usage?.completionTokens == 20)
        #expect(response.metadata?.usage?.totalTokens == 30)
        #expect(response.metadata?.usage?.totalPrice == "0.05")
        #expect(response.metadata?.usage?.currency == "USD")
        #expect(response.metadata?.usage?.latency == 1.5)
        
        // Test retriever resources
        #expect(response.metadata?.retrieverResources?.count == 1)
        #expect(response.metadata?.retrieverResources?[0].position == 1)
        #expect(response.metadata?.retrieverResources?[0].datasetName == "Test Dataset")
        #expect(response.metadata?.retrieverResources?[0].score == 0.95)
    }
}

// MARK: - Streaming Response Tests

struct StreamingResponseTests {
    @Test func testStreamingCompletionResponse() throws {
        // Test message event
        let messageJson = """
        {
            "event": "message",
            "task_id": "task123",
            "message_id": "msg123",
            "answer": "Streaming answer",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let messageResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: messageJson)
        #expect(messageResponse.kind == .message)
        if let event = messageResponse.message {
            #expect(event.taskId == "task123")
            #expect(event.messageId == "msg123")
            #expect(event.answer == "Streaming answer")
        } else {
            Issue.record("Expected message event")
        }
        
        // Test message_end event
        let messageEndJson = """
        {
            "event": "message_end",
            "task_id": "task123",
            "message_id": "msg123",
            "metadata": {
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 20,
                    "total_tokens": 30
                }
            }
        }
        """.data(using: .utf8)!
        
        let messageEndResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: messageEndJson)
        #expect(messageEndResponse.kind == .messageEnd)
        if let event = messageEndResponse.messageEnd {
            #expect(event.taskId == "task123")
            #expect(event.metadata.usage?.totalTokens == 30)
        } else {
            Issue.record("Expected message_end event")
        }
        
        // Test error event
        let errorJson = """
        {
            "event": "error",
            "task_id": "task123",
            "message_id": "msg123",
            "status": 400,
            "code": "invalid_param",
            "message": "Invalid parameter"
        }
        """.data(using: .utf8)!
        
        let errorResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: errorJson)
        #expect(errorResponse.kind == .error)
        if let event = errorResponse.error {
            #expect(event.status == 400)
            #expect(event.code == "invalid_param")
            #expect(event.message == "Invalid parameter")
        } else {
            Issue.record("Expected error event")
        }
        
        // Test ping event
        let pingJson = """
        {"event": "ping"}
        """.data(using: .utf8)!
        
        let pingResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: pingJson)
        if pingResponse.kind == .ping {
            // Success
        } else {
            Issue.record("Expected ping event")
        }
        
        // Test unknown event (should throw)
        let unknownJson = """
        {"event": "unknown_event"}
        """.data(using: .utf8)!
        
        let unknown = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: unknownJson)
        #expect(unknown.kind.rawValue == "unknown_event")
    }
    
    @Test func testStreamingChatMessageResponse() throws {
        // Test workflow_started event
        let workflowJson = """
        {
            "event": "workflow_started",
            "task_id": "task123",
            "workflow_run_id": "run123",
            "data": {
                "id": "workflow123",
                "workflow_id": "wf123",
                "status": "running",
                "outputs": {},
                "error": null,
                "elapsed_time": 0.0,
                "total_tokens": 0,
                "total_steps": 5,
                "created_at": 1704067200,
                "finished_at": null
            }
        }
        """.data(using: .utf8)!
        
        let workflowResponse = try JSONDecoder.difyDecoder.decode(StreamingChatMessageResponse.self, from: workflowJson)
        #expect(workflowResponse.kind == .workflowStarted)
        if let event = workflowResponse.workflowStarted {
            #expect(event.workflowRunId == "run123")
            #expect(event.data.status == "running")
            #expect(event.data.totalSteps == 5)
        } else {
            Issue.record("Expected workflow_started event")
        }
        
        // Test agent_message event
        let agentMessageJson = """
        {
            "event": "agent_message",
            "task_id": "task123",
            "message_id": "msg123",
            "conversation_id": "conv123",
            "answer": "Agent response",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let agentResponse = try JSONDecoder.difyDecoder.decode(StreamingChatMessageResponse.self, from: agentMessageJson)
        #expect(agentResponse.kind == .agentMessage)
        if let event = agentResponse.agentMessage {
            #expect(event.conversationId == "conv123")
            #expect(event.answer == "Agent response")
        } else {
            Issue.record("Expected agent_message event")
        }
    }
    
    @Test func testStreamingWorkflowResponse() throws {
        // Test text_chunk event
        let textChunkJson = """
        {
            "event": "text_chunk",
            "task_id": "task123",
            "workflow_run_id": "run123",
            "data": {
                "text": "Chunk of text",
                "from_variable_selector": ["node1", "output"]
            }
        }
        """.data(using: .utf8)!
        
        let textChunkResponse = try JSONDecoder.difyDecoder.decode(StreamingWorkflowResponse.self, from: textChunkJson)
        #expect(textChunkResponse.kind == .textChunk)
        if let event = textChunkResponse.textChunk {
            #expect(event.data.text == "Chunk of text")
            #expect(event.data.fromVariableSelector == ["node1", "output"])
        } else {
            Issue.record("Expected text_chunk event")
        }
        
        // Test node_started event
        let nodeStartedJson = """
        {
            "event": "node_started",
            "task_id": "task123",
            "data": {
                "id": "node123",
                "node_id": "n123",
                "node_type": "llm",
                "index": 0,
                "title": "LLM Node",
                "predecessor_node_id": null,
                "inputs": {},
                "process_data": {},
                "outputs": {},
                "status": "running",
                "error": null,
                "elapsed_time": 0.0,
                "execution_metadata": {
                    "total_tokens": 0,
                    "total_price": 0.0,
                    "currency": "USD"
                },
                "created_at": 1704067200
            }
        }
        """.data(using: .utf8)!
        
        let nodeResponse = try JSONDecoder.difyDecoder.decode(StreamingWorkflowResponse.self, from: nodeStartedJson)
        #expect(nodeResponse.kind == .nodeStarted)
        if let event = nodeResponse.nodeStarted {
            #expect(event.data.nodeType == "llm")
            #expect(event.data.title == "LLM Node")
            #expect(event.data.executionMetadata?.currency == "USD")
        } else {
            Issue.record("Expected node_started event")
        }
    }
}

// MARK: - Chat Model Tests

struct ChatModelTests {
    @Test func testChatMessageResponse() throws {
        let json = """
        {
            "event": "message",
            "task_id": "task123",
            "id": "id123",
            "message_id": "msg123",
            "conversation_id": "conv123",
            "mode": "streaming",
            "answer": "Chat answer",
            "metadata": null,
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ChatMessageResponse.self, from: json)
        
        #expect(response.event == "message")
        #expect(response.taskId == "task123")
        #expect(response.id == "id123")
        #expect(response.messageId == "msg123")
        #expect(response.conversationId == "conv123")
        #expect(response.mode == "streaming")
        #expect(response.answer == "Chat answer")
        #expect(response.metadata == nil)
        #expect(response.createdAt == 1704067200)
    }
    
    @Test func testConversationsResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "conv123",
                    "name": "Test Conversation",
                    "inputs": {"key": "value"},
                    "status": "active",
                    "introduction": "Welcome message",
                    "created_at": 1704067200
                }
            ],
            "has_more": false,
            "limit": 20
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ConversationsResponse.self, from: json)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "conv123")
        #expect(response.data[0].name == "Test Conversation")
        #expect(response.data[0].inputs?["key"] == "value")
        #expect(response.data[0].status == "active")
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
    }
    
    @Test func testMessageHistoryResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "msg123",
                    "conversation_id": "conv123",
                    "inputs": {},
                    "query": "User question",
                    "message_files": [
                        {
                            "id": "file123",
                            "type": "image",
                            "url": "https://example.com/image.jpg",
                            "belongs_to": "user"
                        }
                    ],
                    "agent_thoughts": [
                        {
                            "id": "thought123",
                            "message_id": "msg123",
                            "position": 1,
                            "thought": "Thinking...",
                            "observation": "Observed...",
                            "tool": "web_search",
                            "tool_input": "query",
                            "created_at": 1704067200,
                            "message_files": []
                        }
                    ],
                    "answer": "AI response",
                    "created_at": 1704067200,
                    "feedback": {
                        "rating": "like"
                    },
                    "retriever_resources": []
                }
            ],
            "has_more": false,
            "limit": 20
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(MessageHistoryResponse.self, from: json)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].query == "User question")
        #expect(response.data[0].messageFiles.count == 1)
        #expect(response.data[0].messageFiles[0].type == "image")
        #expect(response.data[0].agentThoughts.count == 1)
        #expect(response.data[0].agentThoughts[0].thought == "Thinking...")
        #expect(response.data[0].feedback?.rating == "like")
    }
}

// MARK: - Workflow Model Tests

struct WorkflowModelTests {
    @Test func testWorkflowResponse() throws {
        let json = """
        {
            "workflow_run_id": "run123",
            "task_id": "task123",
            "data": {
                "id": "workflow123",
                "workflow_id": "wf123",
                "status": "completed",
                "outputs": {
                    "result": "Success",
                    "count": 42
                },
                "error": null,
                "elapsed_time": 2.5,
                "total_tokens": 100,
                "total_steps": 5,
                "created_at": 1704067200,
                "finished_at": 1704067205
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(WorkflowResponse.self, from: json)
        
        #expect(response.workflowRunId == "run123")
        #expect(response.taskId == "task123")
        #expect(response.data.status == "completed")
        #expect(response.data.elapsedTime == 2.5)
        #expect(response.data.totalTokens == 100)
        
        // Test AnyCodable outputs
        if let result = response.data.outputs?["result"]?.value as? String {
            #expect(result == "Success")
        }
        if let count = response.data.outputs?["count"]?.value as? Int {
            #expect(count == 42)
        }
    }
    
    @Test func testWorkflowLogsResponse() throws {
        let json = """
        {
            "page": 1,
            "limit": 20,
            "total": 50,
            "has_more": true,
            "data": [
                {
                    "id": "log123",
                    "workflow_run": {
                        "id": "run123",
                        "version": "1.0",
                        "status": "completed",
                        "error": null,
                        "elapsed_time": 2.5,
                        "total_tokens": 100,
                        "total_steps": 5,
                        "created_at": 1704067200,
                        "finished_at": 1704067205
                    },
                    "created_from": "api",
                    "created_by_role": "end_user",
                    "created_by_account": null,
                    "created_by_end_user": {
                        "id": "user123",
                        "type": "service_api",
                        "is_anonymous": false,
                        "session_id": "session123"
                    },
                    "created_at": 1704067200
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(WorkflowLogsResponse.self, from: json)
        
        #expect(response.page == 1)
        #expect(response.total == 50)
        #expect(response.hasMore == true)
        #expect(response.data.count == 1)
        #expect(response.data[0].workflowRun.status == "completed")
        #expect(response.data[0].createdByEndUser.isAnonymous == false)
    }
}

// MARK: - Knowledge Base Model Tests

struct KnowledgeBaseModelTests {
    @Test func testDatasetResponse() throws {
        let json = """
        {
            "id": "dataset123",
            "name": "Test Dataset",
            "description": "A test dataset",
            "permission": "read_write",
            "data_source_type": "upload_file",
            "indexing_technique": "high_quality",
            "app_count": 3,
            "document_count": 10,
            "word_count": 5000,
            "created_by": "user123",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(DatasetResponse.self, from: json)
        
        #expect(response.id == "dataset123")
        #expect(response.name == "Test Dataset")
        #expect(response.description == "A test dataset")
        #expect(response.permission == "read_write")
        #expect(response.dataSourceType == "upload_file")
        #expect(response.indexingTechnique == .highQuality)
        #expect(response.appCount == 3)
        #expect(response.documentCount == 10)
        #expect(response.wordCount == 5000)
    }
    
    @Test func testDocumentsResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "doc123",
                    "position": 1,
                    "name": "document.pdf",
                    "tokens": 1500,
                    "indexing_status": "completed",
                    "created_by": "user123",
                    "created_at": 1704067200
                }
            ],
            "has_more": false,
            "limit": 20,
            "total": 1,
            "page": 1
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(DocumentsResponse.self, from: json)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "doc123")
        #expect(response.data[0].position == 1)
        #expect(response.data[0].tokens == 1500)
        #expect(response.data[0].indexingStatus == "completed")
        #expect(response.total == 1)
    }

    @Test func testDocLanguageRequiredOnlyForQAModel_TextRequest() throws {
        // When doc_form is qa_model, doc_language must be present and non-empty
        let reqMissing = KBCreateDocumentByTextRequest(
            name: "n", text: "t", indexingTechnique: nil, docForm: .qaModel, docLanguage: nil, processRule: nil, retrievalModel: nil, embeddingModel: nil, embeddingModelProvider: nil
        )
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder.difyEncoder.encode(reqMissing)
        }

        // When doc_form is text_model, doc_language should be omitted even if provided
        let reqText = KBCreateDocumentByTextRequest(
            name: "n", text: "t", indexingTechnique: nil, docForm: .textModel, docLanguage: "English", processRule: nil, retrievalModel: nil, embeddingModel: nil, embeddingModelProvider: nil
        )
        let data = try JSONEncoder.difyEncoder.encode(reqText)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(obj?["doc_language"] == nil)
        #expect(obj?["doc_form"] as? String == KBDocumentForm.textModel.rawValue)
    }

    @Test func testDocLanguageRequiredOnlyForQAModel_FileData() throws {
        // FileData variant: enforce same rules
        let reqMissing = KBCreateDocumentByFileData(
            originalDocumentId: nil, indexingTechnique: nil, docForm: .qaModel, docLanguage: nil, processRule: nil, retrievalModel: nil, embeddingModel: nil, embeddingModelProvider: nil
        )
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder.difyEncoder.encode(reqMissing)
        }

        let reqText = KBCreateDocumentByFileData(
            originalDocumentId: nil, indexingTechnique: nil, docForm: .textModel, docLanguage: "English", processRule: nil, retrievalModel: nil, embeddingModel: nil, embeddingModelProvider: nil
        )
        let data = try JSONEncoder.difyEncoder.encode(reqText)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(obj?["doc_language"] == nil)
        #expect(obj?["doc_form"] as? String == KBDocumentForm.textModel.rawValue)
    }
}

// MARK: - Feedback Model Tests

struct FeedbackModelTests {
    @Test func testMessageFeedbackRequest() throws {
        let request = MessageFeedbackRequest(rating: "like", user: "user123", content: "Great response!")
        let encoded = try JSONEncoder.difyEncoder.encode(request)
        let decoded = try JSONDecoder.difyDecoder.decode(MessageFeedbackRequest.self, from: encoded)
        
        #expect(decoded.rating == "like")
        #expect(decoded.user == "user123")
        #expect(decoded.content == "Great response!")
        
        // Test with nil content
        let minimalRequest = MessageFeedbackRequest(rating: nil, user: "user123")
        let minimalEncoded = try JSONEncoder.difyEncoder.encode(minimalRequest)
        let minimalDecoded = try JSONDecoder.difyDecoder.decode(MessageFeedbackRequest.self, from: minimalEncoded)
        
        #expect(minimalDecoded.rating == nil)
        #expect(minimalDecoded.content == nil)
    }
    
    @Test func testApplicationFeedbacksResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "feedback123",
                    "app_id": "app123",
                    "conversation_id": "conv123",
                    "message_id": "msg123",
                    "rating": "like",
                    "content": "Helpful response",
                    "from_source": "api",
                    "from_end_user_id": "user123",
                    "from_account_id": null,
                    "created_at": "2024-01-01T00:00:00Z",
                    "updated_at": "2024-01-01T00:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationFeedbacksResponse.self, from: json)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "feedback123")
        #expect(response.data[0].rating == "like")
        #expect(response.data[0].fromAccountId == nil)
    }
}

// MARK: - Text to Audio Tests

struct TextToAudioTests {
    @Test func testTextToAudioRequest() throws {
        let request = TextToAudioRequest(messageId: "msg123", text: "Convert this", user: "user123")
        let encoded = try JSONEncoder.difyEncoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        
        #expect(json?["message_id"] as? String == "msg123")
        #expect(json?["text"] as? String == "Convert this")
        #expect(json?["user"] as? String == "user123")
    }
    
    @Test func testAudioToTextResponse() throws {
        let json = """
        {"text": "Transcribed text"}
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(AudioToTextResponse.self, from: json)
        #expect(response.text == "Transcribed text")
    }
}

// MARK: - AnyCodable Tests

struct AnyCodableTests {
    @Test func testAnyCodableInt() throws {
        let value = AnyCodable(42)
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        #expect(decoded.value as? Int == 42)
    }
    
    @Test func testAnyCodableDouble() throws {
        let value = AnyCodable(3.14)
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        #expect(decoded.value as? Double == 3.14)
    }
    
    @Test func testAnyCodableBool() throws {
        let value = AnyCodable(true)
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        #expect(decoded.value as? Bool == true)
    }
    
    @Test func testAnyCodableString() throws {
        let value = AnyCodable("Hello, world!")
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        #expect(decoded.value as? String == "Hello, world!")
    }
    
    @Test func testAnyCodableArray() throws {
        let value = AnyCodable([1, 2, 3])
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        if let array = decoded.value as? [Any] {
            #expect(array.count == 3)
            #expect(array[0] as? Int == 1)
            #expect(array[1] as? Int == 2)
            #expect(array[2] as? Int == 3)
        } else {
            Issue.record("Expected array")
        }
    }
    
    @Test func testAnyCodableDictionary() throws {
        let value = AnyCodable(["key": "value", "number": 42])
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        if let dict = decoded.value as? [String: Any] {
            #expect(dict["key"] as? String == "value")
            #expect(dict["number"] as? Int == 42)
        } else {
            Issue.record("Expected dictionary")
        }
    }
    
    @Test func testAnyCodableNested() throws {
        let value = AnyCodable([
            "string": "Hello",
            "number": 42,
            "bool": true,
            "array": [1, 2, 3],
            "nested": ["key": "value"]
        ])
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        if let dict = decoded.value as? [String: Any] {
            #expect(dict["string"] as? String == "Hello")
            #expect(dict["number"] as? Int == 42)
            #expect(dict["bool"] as? Bool == true)
            if let array = dict["array"] as? [Any] {
                #expect(array.count == 3)
            }
            if let nested = dict["nested"] as? [String: Any] {
                #expect(nested["key"] as? String == "value")
            }
        } else {
            Issue.record("Expected dictionary")
        }
    }
    
    @Test func testAnyCodableDecodingError() throws {
        // Test with null value (should throw)
        let nullJson = "null".data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: nullJson)
        }
    }
    
    @Test func testAnyCodableEncodingError() throws {
        // Test with unsupported type
        class UnsupportedType {}
        let value = AnyCodable(UnsupportedType())
        
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder.difyEncoder.encode(value)
        }
    }
    
    @Test func testAnyCodableFloatingPointOnly() throws {
        // Test with a floating point number that cannot be represented as an integer
        // This ensures the Double branch in the decoder is tested
        let jsonString = "3.14159265359"
        let jsonData = jsonString.data(using: .utf8)!
        
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: jsonData)
        #expect(decoded.value as? Double == 3.14159265359)
        
        // Also test with scientific notation
        let scientificJson = "1.23e-10".data(using: .utf8)!
        let scientificDecoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: scientificJson)
        #expect(scientificDecoded.value as? Double == 1.23e-10)
    }
}

// MARK: - Additional Model Tests

struct AdditionalModelTests {
    @Test func testSuggestedQuestionsResponse() throws {
        let json = """
        {
            "result": "success",
            "data": ["Question 1", "Question 2", "Question 3"]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(SuggestedQuestionsResponse.self, from: json)
        
        #expect(response.result == "success")
        #expect(response.data == ["Question 1", "Question 2", "Question 3"])
    }
    
    @Test func testConversationVariablesResponse() throws {
        let json = """
        {
            "limit": 20,
            "has_more": false,
            "data": [
                {
                    "id": "var123",
                    "name": "user_name",
                    "value_type": "string",
                    "value": "John Doe",
                    "description": "User's name",
                    "created_at": 1704067200,
                    "updated_at": 1704067200
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ConversationVariablesResponse.self, from: json)
        
        #expect(response.limit == 20)
        #expect(response.hasMore == false)
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "user_name")
        #expect(response.data[0].valueType == "string")
        #expect(response.data[0].value.value as? String == "John Doe")
    }

    @Test func testConversationVariable_AllValueTypesDecoding() throws {
        let json = """
        {
            "limit": 20,
            "has_more": false,
            "data": [
                {"id":"v1","name":"s","value_type":"string","value":"hello","description":"","created_at":1,"updated_at":1},
                {"id":"v2","name":"n","value_type":"number","value":42,"description":"","created_at":1,"updated_at":1},
                {"id":"v3","name":"o","value_type":"object","value":{"a":1},"description":"","created_at":1,"updated_at":1}
            ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder.difyDecoder.decode(ConversationVariablesResponse.self, from: json)
        #expect(response.data[0].value.value as? String == "hello")
        #expect(response.data[1].value.value as? Int == 42)
        if let dict = response.data[2].value.value as? [String: Any] {
            #expect(dict["a"] as? Int == 1)
        } else {
            Issue.record("Expected object for v3")
        }
    }
    
    @Test func testAnnotationsListResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "ann123",
                    "question": "What is AI?",
                    "answer": "Artificial Intelligence",
                    "hit_count": 10,
                    "created_at": 1704067200
                }
            ],
            "has_more": false,
            "limit": 20,
            "total": 1,
            "page": 1
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(AnnotationsListResponse.self, from: json)
        
        #expect(response.data.count == 1)
        #expect(response.data[0].question == "What is AI?")
        #expect(response.data[0].hitCount == 10)
        #expect(response.total == 1)
    }
    
    @Test func testAnnotationReplyJobResponse() throws {
        let json = """
        {
            "job_id": "job123",
            "job_status": "processing"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(AnnotationReplyJobResponse.self, from: json)
        
        #expect(response.jobId == "job123")
        #expect(response.jobStatus == "processing")
    }
    
    @Test func testAnnotationReplyJobStatusResponse() throws {
        let json = """
        {
            "job_id": "job123",
            "job_status": "completed",
            "error_msg": ""
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(AnnotationReplyJobStatusResponse.self, from: json)
        
        #expect(response.jobId == "job123")
        #expect(response.jobStatus == "completed")
        #expect(response.errorMsg == "")
    }
}

// MARK: - ToolIcon Tests

struct ToolIconTests {
    @Test func testToolIconUrl() throws {
        // Test URL case
        let urlJson = """
        "https://example.com/icon.png"
        """.data(using: .utf8)!
        
        let urlIcon = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: urlJson)
        #expect(urlIcon.url == "https://example.com/icon.png")
        
        // Test encoding
        let encoded = try JSONEncoder.difyEncoder.encode(urlIcon)
        let decoded = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: encoded)
        #expect(decoded.url == "https://example.com/icon.png")
    }
    
    @Test func testToolIconEmoji() throws {
        // Test emoji case
        let emojiJson = """
        {
            "background": "#FF0000",
            "content": "🚀"
        }
        """.data(using: .utf8)!
        
        let emojiIcon = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: emojiJson)
        #expect(emojiIcon.emoji?.background == "#FF0000")
        #expect(emojiIcon.emoji?.content == "🚀")
        
        // Test encoding
        let encoded = try JSONEncoder.difyEncoder.encode(emojiIcon)
        let decoded = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: encoded)
        #expect(decoded.emoji?.background == "#FF0000")
        #expect(decoded.emoji?.content == "🚀")
    }
    
    @Test func testApplicationMetaResponse() throws {
        let json = """
        {
            "tool_icons": {
                "web_search": "https://example.com/search.png",
                "calculator": {
                    "background": "#0000FF",
                    "content": "🧮"
                }
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationMetaResponse.self, from: json)
        
        #expect(response.toolIcons.count == 2)
        
        if let icon = response.toolIcons["web_search"] { #expect(icon.url == "https://example.com/search.png") } else { Issue.record("Missing web_search icon") }
        
        if let icon = response.toolIcons["calculator"] { #expect(icon.emoji?.background == "#0000FF"); #expect(icon.emoji?.content == "🧮") } else { Issue.record("Missing calculator icon") }
    }
}

// MARK: - Edge Case Tests

struct EdgeCaseTests {
    @Test func testEmptyArraysAndOptionals() throws {
        // Test with minimal data
        let json = """
        {
            "data": [],
            "has_more": false,
            "limit": 0
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ConversationsResponse.self, from: json)
        
        #expect(response.data.isEmpty)
        #expect(response.hasMore == false)
        #expect(response.limit == 0)
    }
    
    @Test func testPartialResponses() throws {
        // Test WorkflowData with minimal fields
        let json = """
        {
            "id": "wf123",
            "workflow_id": "workflow123",
            "status": "running",
            "outputs": null,
            "error": null,
            "elapsed_time": 0.0,
            "total_tokens": 0,
            "total_steps": 0,
            "created_at": 1704067200,
            "finished_at": null
        }
        """.data(using: .utf8)!
        
        let data = try JSONDecoder.difyDecoder.decode(WorkflowData.self, from: json)
        
        #expect(data.id == "wf123")
        #expect(data.outputs == nil)
        #expect(data.error == nil)
        #expect(data.finishedAt == nil)
    }
    
    @Test func testSpecialCharactersInStrings() throws {
        let json = """
        {
            "result": "Test with special chars: \\n\\t\\\"\\\\🚀"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(BaseResponse.self, from: json)
        
        #expect(response.result == "Test with special chars: \n\t\"\\🚀")
    }
    
    @Test func testLargeNumbers() throws {
        let json = """
        {
            "prompt_tokens": 9223372036854775807,
            "completion_tokens": 0,
            "total_tokens": 9223372036854775807
        }
        """.data(using: .utf8)!
        
        let usage = try JSONDecoder.difyDecoder.decode(Usage.self, from: json)
        
        #expect(usage.promptTokens == Int.max)
        #expect(usage.totalTokens == Int.max)
    }
    
    @Test func testNestedOptionals() throws {
        // Test ApplicationParametersResponse with all nil optionals
        let json = """
        {
            "opening_statement": null,
            "suggested_questions": null,
            "suggested_questions_after_answer": null,
            "speech_to_text": null,
            "retriever_resource": null,
            "annotation_reply": null,
            "user_input_form": null,
            "file_upload": null,
            "system_parameters": null
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationParametersResponse.self, from: json)
        
        #expect(response.openingStatement == nil)
        #expect(response.suggestedQuestions == nil)
        #expect(response.suggestedQuestionsAfterAnswer == nil)
        #expect(response.speechToText == nil)
        #expect(response.retrieverResource == nil)
        #expect(response.annotationReply == nil)
        #expect(response.userInputForm == nil)
        #expect(response.fileUpload == nil)
        #expect(response.systemParameters == nil)
    }
}

// MARK: - CodingKeys Coverage Tests

struct CodingKeysTests {
    @Test func testAllCodingKeysAreMapped() throws {
        // This test ensures all snake_case to camelCase mappings work correctly
        // by creating JSON with all snake_case keys and verifying proper decoding
        
        // Test ApplicationInfoResponse CodingKeys
        let appInfoJson = """
        {
            "name": "App",
            "description": "Desc",
            "tags": [],
            "mode": "chat",
            "author_name": "Author"
        }
        """.data(using: .utf8)!
        
        let appInfo = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: appInfoJson)
        #expect(appInfo.authorName == "Author")
        
        // Test FileUploadResponse CodingKeys
        let fileUploadJson = """
        {
            "id": "123",
            "name": "file.pdf",
            "size": 1024,
            "extension": "pdf",
            "mime_type": "application/pdf",
            "created_by": "user",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let fileUpload = try JSONDecoder.difyDecoder.decode(FileUploadResponse.self, from: fileUploadJson)
        #expect(fileUpload.fileExtension == "pdf")
        #expect(fileUpload.mimeType == "application/pdf")
        #expect(fileUpload.createdBy == "user")
        #expect(fileUpload.createdAt == 1704067200)
        
        // Test Usage CodingKeys
        let usageJson = """
        {
            "prompt_tokens": 10,
            "completion_tokens": 20,
            "total_tokens": 30,
            "prompt_unit_price": "0.001",
            "prompt_price_unit": "0.001",
            "prompt_price": "0.01",
            "completion_unit_price": "0.002",
            "completion_price_unit": "0.001",
            "completion_price": "0.04",
            "total_price": "0.05",
            "currency": "USD",
            "latency": 1.5
        }
        """.data(using: .utf8)!
        
        let usage = try JSONDecoder.difyDecoder.decode(Usage.self, from: usageJson)
        #expect(usage.promptTokens == 10)
        #expect(usage.completionTokens == 20)
        #expect(usage.totalTokens == 30)
        #expect(usage.promptUnitPrice == "0.001")
        #expect(usage.promptPriceUnit == "0.001")
        #expect(usage.promptPrice == "0.01")
        #expect(usage.completionUnitPrice == "0.002")
        #expect(usage.completionPriceUnit == "0.001")
        #expect(usage.completionPrice == "0.04")
        #expect(usage.totalPrice == "0.05")
        
        // Test RetrieverResource CodingKeys
        let retrieverJson = """
        {
            "position": 1,
            "dataset_id": "ds123",
            "dataset_name": "Dataset",
            "document_id": "doc123",
            "document_name": "Document",
            "segment_id": "seg123",
            "score": 0.95,
            "content": "Content"
        }
        """.data(using: .utf8)!
        
        let retriever = try JSONDecoder.difyDecoder.decode(RetrieverResource.self, from: retrieverJson)
        #expect(retriever.datasetId == "ds123")
        #expect(retriever.datasetName == "Dataset")
        #expect(retriever.documentId == "doc123")
        #expect(retriever.documentName == "Document")
        #expect(retriever.segmentId == "seg123")
    }
    
    @Test func testComplexNestedCodingKeys() throws {
        // Test UserInputFormItem with text-input CodingKey
        let json = """
        {
            "text-input": {
                "label": "Input",
                "variable": "var",
                "required": true,
                "default": "value"
            }
        }
        """.data(using: .utf8)!
        
        let item = try JSONDecoder.difyDecoder.decode(UserInputFormItem.self, from: json)
        #expect(item.textInput?.label == "Input")
        #expect(item.textInput?.defaultValue == "value")
        
        // Test ImageUploadConfig CodingKeys
        let imageJson = """
        {
            "enabled": true,
            "number_limits": 10,
            "transfer_methods": ["remote_url"]
        }
        """.data(using: .utf8)!
        
        let image = try JSONDecoder.difyDecoder.decode(ImageUploadConfig.self, from: imageJson)
        #expect(image.numberLimits == 10)
        #expect(image.transferMethods == ["remote_url"])
        
        // Test SystemParameters CodingKeys
        let sysParamsJson = """
        {
            "file_size_limit": 100,
            "image_file_size_limit": 200,
            "audio_file_size_limit": 300,
            "video_file_size_limit": 400
        }
        """.data(using: .utf8)!
        
        let sysParams = try JSONDecoder.difyDecoder.decode(SystemParameters.self, from: sysParamsJson)
        #expect(sysParams.fileSizeLimit == 100)
        #expect(sysParams.imageFileSizeLimit == 200)
        #expect(sysParams.audioFileSizeLimit == 300)
        #expect(sysParams.videoFileSizeLimit == 400)
    }
}

// MARK: - All Initializers Tests

struct InitializerTests {
    @Test func testAPIFileInitializer() {
        let file1 = APIFile(type: .document, transferMethod: .remoteUrl)
        #expect(file1.type == .document)
        #expect(file1.transferMethod == .remoteUrl)
        #expect(file1.url == nil)
        #expect(file1.uploadFileId == nil)
        
        let file2 = APIFile(
            type: .image,
            transferMethod: .localFile,
            url: "https://example.com",
            uploadFileId: "123"
        )
        #expect(file2.type == .image)
        #expect(file2.transferMethod == .localFile)
        #expect(file2.url == "https://example.com")
        #expect(file2.uploadFileId == "123")
    }
    
    @Test func testProcessRuleInitializer() {
        let rule1 = ProcessRule(mode: "auto")
        #expect(rule1.mode == "auto")
        #expect(rule1.rules == nil)
        
        let rule2 = ProcessRule(mode: "manual", rules: ["key": "value"])
        #expect(rule2.mode == "manual")
        #expect(rule2.rules?["key"] == "value")
    }
    
    @Test func testMessageFeedbackRequestInitializer() {
        let feedback1 = MessageFeedbackRequest(rating: "like", user: "user123")
        #expect(feedback1.rating == "like")
        #expect(feedback1.user == "user123")
        #expect(feedback1.content == nil)
        
        let feedback2 = MessageFeedbackRequest(rating: nil, user: "user456", content: "Great!")
        #expect(feedback2.rating == nil)
        #expect(feedback2.user == "user456")
        #expect(feedback2.content == "Great!")
    }
    
    @Test func testTextToAudioRequestInitializer() {
        let request1 = TextToAudioRequest(user: "user123")
        #expect(request1.messageId == nil)
        #expect(request1.text == nil)
        #expect(request1.user == "user123")
        
        let request2 = TextToAudioRequest(messageId: "msg123", text: "Hello", user: "user456")
        #expect(request2.messageId == "msg123")
        #expect(request2.text == "Hello")
        #expect(request2.user == "user456")
    }
    
    @Test func testAnyCodableInitializer() {
        let int = AnyCodable(42)
        #expect(int.value as? Int == 42)
        
        let string = AnyCodable("Hello")
        #expect(string.value as? String == "Hello")
        
        let array = AnyCodable([1, 2, 3])
        if let arr = array.value as? [Int] {
            #expect(arr == [1, 2, 3])
        }
        
        let dict = AnyCodable(["key": "value"])
        if let d = dict.value as? [String: String] {
            #expect(d["key"] == "value")
        }
    }
}

// MARK: - TTSMessage Tests

struct TTSMessageTests {
    @Test func testTTSMessageStreamEvent() throws {
        let json = """
        {
            "event": "tts_message",
            "task_id": "task123",
            "message_id": "msg123",
            "audio": "base64encodedaudio==",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(TTSMessageStreamEvent.self, from: json)
        
        #expect(event.event == "tts_message")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.audio == "base64encodedaudio==")
        #expect(event.createdAt == 1704067200)
    }
    
    @Test func testTTSMessageEndStreamEvent() throws {
        let json = """
        {
            "event": "tts_message_end",
            "task_id": "task123",
            "message_id": "msg123",
            "audio": "",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(TTSMessageEndStreamEvent.self, from: json)
        
        #expect(event.event == "tts_message_end")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.audio == "")
        #expect(event.createdAt == 1704067200)
    }
}

// MARK: - Agent Thought Tests

struct AgentThoughtTests {
    @Test func testAgentThoughtStreamEvent() throws {
        let json = """
        {
            "event": "agent_thought"
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(AgentThoughtStreamEvent.self, from: json)
        #expect(event.event == "agent_thought")
    }
    
    @Test func testAgentThought() throws {
        let json = """
        {
            "id": "thought123",
            "message_id": "msg123",
            "position": 1,
            "thought": "Analyzing the request...",
            "observation": "Found relevant information",
            "tool": "web_search",
            "tool_input": "search query",
            "created_at": 1704067200,
            "message_files": ["file1", "file2"]
        }
        """.data(using: .utf8)!
        
        let thought = try JSONDecoder.difyDecoder.decode(AgentThought.self, from: json)
        
        #expect(thought.id == "thought123")
        #expect(thought.messageId == "msg123")
        #expect(thought.position == 1)
        #expect(thought.thought == "Analyzing the request...")
        #expect(thought.observation == "Found relevant information")
        #expect(thought.tool == "web_search")
        #expect(thought.toolInput == "search query")
        #expect(thought.createdAt == 1704067200)
        #expect(thought.messageFiles == ["file1", "file2"])
    }
}

// MARK: - Message File Tests

struct MessageFileTests {
    @Test func testMessageFile() throws {
        let json = """
        {
            "id": "file123",
            "type": "image",
            "url": "https://example.com/image.jpg",
            "belongs_to": "user"
        }
        """.data(using: .utf8)!
        
        let file = try JSONDecoder.difyDecoder.decode(MessageFile.self, from: json)
        
        #expect(file.id == "file123")
        #expect(file.type == "image")
        #expect(file.url == "https://example.com/image.jpg")
        #expect(file.belongsTo == "user")
    }
    
    @Test func testMessageFileStreamEvent() throws {
        let json = """
        {
            "event": "message_file",
            "id": "file123",
            "type": "document",
            "belongs_to": "assistant",
            "url": "https://example.com/doc.pdf",
            "conversation_id": "conv123"
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(MessageFileStreamEvent.self, from: json)
        
        #expect(event.event == "message_file")
        #expect(event.id == "file123")
        #expect(event.type == "document")
        #expect(event.belongsTo == "assistant")
        #expect(event.url == "https://example.com/doc.pdf")
        #expect(event.conversationId == "conv123")
    }
}

// MARK: - Simple Response Tests

struct SimpleResponseTests {
    @Test func testMessageFeedbackResponse() throws {
        let json = """
        {"result": "success"}
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(MessageFeedbackResponse.self, from: json)
        #expect(response.result == "success")
    }
    
    @Test func testStopCompletionResponse() throws {
        let json = """
        {"result": "stopped"}
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(StopCompletionResponse.self, from: json)
        #expect(response.result == "stopped")
    }
    
    @Test func testMessageFeedback() throws {
        let json = """
        {"rating": "dislike"}
        """.data(using: .utf8)!
        
        let feedback = try JSONDecoder.difyDecoder.decode(MessageFeedback.self, from: json)
        #expect(feedback.rating == "dislike")
    }
}

// MARK: - WebApp Settings Tests

struct WebAppSettingsTests {
    @Test func testApplicationWebAppSettingsResponse() throws {
        let json = """
        {
            "title": "My WebApp",
            "icon_type": "emoji",
            "icon": "🚀",
            "icon_background": "#FF0000",
            "icon_url": null,
            "description": "WebApp description",
            "copyright": "© 2024",
            "privacy_policy": "Privacy text",
            "custom_disclaimer": "Disclaimer",
            "default_language": "en",
            "show_workflow_steps": true
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationWebAppSettingsResponse.self, from: json)
        
        #expect(response.title == "My WebApp")
        #expect(response.iconType == "emoji")
        #expect(response.icon == "🚀")
        #expect(response.iconBackground == "#FF0000")
        #expect(response.iconUrl == nil)
        #expect(response.description == "WebApp description")
        #expect(response.copyright == "© 2024")
        #expect(response.privacyPolicy == "Privacy text")
        #expect(response.customDisclaimer == "Disclaimer")
        #expect(response.defaultLanguage == "en")
        #expect(response.showWorkflowSteps == true)
    }
}

// MARK: - Workflow Detail Tests

struct WorkflowDetailTests {
    @Test func testWorkflowRunDetailResponse() throws {
        let json = """
        {
            "id": "run123",
            "workflow_id": "wf123",
            "status": "completed",
            "inputs": {"input": "value"},
            "outputs": {"result": "success"},
            "error": null,
            "total_steps": 5,
            "total_tokens": 100,
            "created_at": 1704067200,
            "finished_at": 1704067210,
            "elapsed_time": 10.0
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(WorkflowRunDetailResponse.self, from: json)
        
        #expect(response.id == "run123")
        #expect(response.workflowId == "wf123")
        #expect(response.status == "completed")
        #expect(response.totalSteps == 5)
        #expect(response.totalTokens == 100)
        #expect(response.elapsedTime == 10.0)
        #expect(response.error == nil)
        #expect(response.finishedAt == 1704067210)
    }
}

// MARK: - Execution Metadata Tests

struct ExecutionMetadataTests {
    @Test func testExecutionMetadata() throws {
        let json = """
        {
            "total_tokens": 150,
            "total_price": 0.15,
            "currency": "EUR"
        }
        """.data(using: .utf8)!
        
        let metadata = try JSONDecoder.difyDecoder.decode(ExecutionMetadata.self, from: json)
        
        #expect(metadata.totalTokens == 150)
        #expect(metadata.totalPrice == 0.15)
        #expect(metadata.currency == "EUR")
    }
    
    @Test func testExecutionMetadataWithNulls() throws {
        let json = """
        {
            "total_tokens": null,
            "total_price": null,
            "currency": null
        }
        """.data(using: .utf8)!
        
        let metadata = try JSONDecoder.difyDecoder.decode(ExecutionMetadata.self, from: json)
        
        #expect(metadata.totalTokens == nil)
        #expect(metadata.totalPrice == nil)
        #expect(metadata.currency == nil)
    }
}

// MARK: - Node Execution Tests

struct NodeExecutionTests {
    @Test func testNodeExecutionData() throws {
        let json = """
        {
            "id": "node123",
            "node_id": "n123",
            "node_type": "llm",
            "index": 2,
            "title": "LLM Processing",
            "predecessor_node_id": "n122",
            "inputs": {"prompt": "Hello"},
            "process_data": {"key": "value"},
            "outputs": {"response": "Hi"},
            "status": "succeeded",
            "error": null,
            "elapsed_time": 1.5,
            "execution_metadata": {
                "total_tokens": 50,
                "total_price": 0.05,
                "currency": "USD"
            },
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let node = try JSONDecoder.difyDecoder.decode(NodeExecutionData.self, from: json)
        
        #expect(node.id == "node123")
        #expect(node.nodeId == "n123")
        #expect(node.nodeType == "llm")
        #expect(node.index == 2)
        #expect(node.title == "LLM Processing")
        #expect(node.predecessorNodeId == "n122")
        #expect(node.status == "succeeded")
        #expect(node.error == nil)
        #expect(node.elapsedTime == 1.5)
        #expect(node.executionMetadata?.totalTokens == 50)
        #expect(node.createdAt == 1704067200)
    }
}

// MARK: - Text Chunk Tests

struct TextChunkTests {
    @Test func testTextChunkData() throws {
        let json = """
        {
            "text": "This is a chunk of text",
            "from_variable_selector": ["node1", "output", "text"]
        }
        """.data(using: .utf8)!
        
        let chunk = try JSONDecoder.difyDecoder.decode(TextChunkData.self, from: json)
        
        #expect(chunk.text == "This is a chunk of text")
        #expect(chunk.fromVariableSelector == ["node1", "output", "text"])
    }
    
    @Test func testTextChunkDataWithoutSelector() throws {
        let json = """
        {
            "text": "Simple text",
            "from_variable_selector": null
        }
        """.data(using: .utf8)!
        
        let chunk = try JSONDecoder.difyDecoder.decode(TextChunkData.self, from: json)
        
        #expect(chunk.text == "Simple text")
        #expect(chunk.fromVariableSelector == nil)
    }
}

// MARK: - Chat Application Feedback Tests

struct ChatApplicationFeedbackTests {
    @Test func testChatApplicationFeedbacksResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "feedback123",
                    "app_id": "app123",
                    "conversation_id": "conv123",
                    "message_id": "msg123",
                    "rating": "like",
                    "content": "Very helpful",
                    "from_source": "api",
                    "from_end_user_id": "user123",
                    "from_account_id": "account123",
                    "created_at": "2024-01-01T00:00:00Z",
                    "updated_at": "2024-01-01T00:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ChatApplicationFeedbacksResponse.self, from: json)
        
        #expect(response.data.count == 1)
        let feedback = response.data[0]
        #expect(feedback.id == "feedback123")
        #expect(feedback.appId == "app123")
        #expect(feedback.conversationId == "conv123")
        #expect(feedback.messageId == "msg123")
        #expect(feedback.rating == "like")
        #expect(feedback.content == "Very helpful")
        #expect(feedback.fromSource == "api")
        #expect(feedback.fromEndUserId == "user123")
        #expect(feedback.fromAccountId == "account123")
        #expect(feedback.createdAt == "2024-01-01T00:00:00Z")
        #expect(feedback.updatedAt == "2024-01-01T00:00:00Z")
    }
}

// MARK: - All Config Structs Tests

struct ConfigStructTests {
    @Test func testSuggestedQuestionsConfig() throws {
        let json = """
        {"enabled": true}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder.difyDecoder.decode(SuggestedQuestionsConfig.self, from: json)
        #expect(config.enabled == true)
    }
    
    @Test func testSpeechToTextConfig() throws {
        let json = """
        {"enabled": false}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder.difyDecoder.decode(SpeechToTextConfig.self, from: json)
        #expect(config.enabled == false)
    }
    
    @Test func testRetrieverResourceConfig() throws {
        let json = """
        {"enabled": true}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder.difyDecoder.decode(RetrieverResourceConfig.self, from: json)
        #expect(config.enabled == true)
    }
    
    @Test func testAnnotationReplyConfig() throws {
        let json = """
        {"enabled": false}
        """.data(using: .utf8)!
        
        let config = try JSONDecoder.difyDecoder.decode(AnnotationReplyConfig.self, from: json)
        #expect(config.enabled == false)
    }
}

// MARK: - Form Input Tests

struct FormInputTests {
    @Test func testFormInput() throws {
        let json = """
        {
            "label": "Your Name",
            "variable": "user_name",
            "required": true,
            "default": "Anonymous"
        }
        """.data(using: .utf8)!
        
        let input = try JSONDecoder.difyDecoder.decode(FormInput.self, from: json)
        
        #expect(input.label == "Your Name")
        #expect(input.variable == "user_name")
        #expect(input.required == true)
        #expect(input.defaultValue == "Anonymous")
    }
    
    @Test func testSelect() throws {
        let json = """
        {
            "label": "Country",
            "variable": "country",
            "required": false,
            "default": "US",
            "options": ["US", "UK", "CA", "AU"]
        }
        """.data(using: .utf8)!
        
        let select = try JSONDecoder.difyDecoder.decode(Select.self, from: json)
        
        #expect(select.label == "Country")
        #expect(select.variable == "country")
        #expect(select.required == false)
        #expect(select.defaultValue == "US")
        #expect(select.options == ["US", "UK", "CA", "AU"])
    }
}

// MARK: - Error Event Tests

struct ErrorEventTests {
    @Test func testErrorStreamEvent() throws {
        let json = """
        {
            "event": "error",
            "task_id": "task123",
            "message_id": "msg123",
            "status": 500,
            "code": "internal_error",
            "message": "An internal server error occurred"
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(ErrorStreamEvent.self, from: json)
        
        #expect(event.event == "error")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.status == 500)
        #expect(event.code == "internal_error")
        #expect(event.message == "An internal server error occurred")
    }
}

// MARK: - Message Replace Event Tests

struct MessageReplaceEventTests {
    @Test func testMessageReplaceStreamEvent() throws {
        let json = """
        {
            "event": "message_replace",
            "task_id": "task123",
            "message_id": "msg123",
            "conversation_id": "conv123",
            "answer": "This is the updated answer",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(MessageReplaceStreamEvent.self, from: json)
        
        #expect(event.event == "message_replace")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.conversationId == "conv123")
        #expect(event.answer == "This is the updated answer")
        #expect(event.createdAt == 1704067200)
    }
}

// MARK: - End User Info Tests

struct EndUserInfoTests {
    @Test func testEndUserInfo() throws {
        let json = """
        {
            "id": "user123",
            "type": "service_api",
            "is_anonymous": false,
            "session_id": "session456"
        }
        """.data(using: .utf8)!
        
        let user = try JSONDecoder.difyDecoder.decode(EndUserInfo.self, from: json)
        
        #expect(user.id == "user123")
        #expect(user.type == "service_api")
        #expect(user.isAnonymous == false)
        #expect(user.sessionId == "session456")
    }
}

// MARK: - Workflow Run Info Tests

struct WorkflowRunInfoTests {
    @Test func testWorkflowRunInfo() throws {
        let json = """
        {
            "id": "run123",
            "version": "1.2.3",
            "status": "succeeded",
            "error": null,
            "elapsed_time": 5.5,
            "total_tokens": 200,
            "total_steps": 10,
            "created_at": 1704067200,
            "finished_at": 1704067206
        }
        """.data(using: .utf8)!
        
        let run = try JSONDecoder.difyDecoder.decode(WorkflowRunInfo.self, from: json)
        
        #expect(run.id == "run123")
        #expect(run.version == "1.2.3")
        #expect(run.status == "succeeded")
        #expect(run.error == nil)
        #expect(run.elapsedTime == 5.5)
        #expect(run.totalTokens == 200)
        #expect(run.totalSteps == 10)
        #expect(run.createdAt == 1704067200)
        #expect(run.finishedAt == 1704067206)
    }
}

// MARK: - Conversation Variable Tests

struct ConversationVariableTests {
    @Test func testConversationVariable() throws {
        let json = """
        {
            "id": "var123",
            "name": "user_preference",
            "value_type": "string",
            "value": "dark_mode",
            "description": "User's theme preference",
            "created_at": 1704067200,
            "updated_at": 1704067300
        }
        """.data(using: .utf8)!
        
        let variable = try JSONDecoder.difyDecoder.decode(ConversationVariable.self, from: json)
        
        #expect(variable.id == "var123")
        #expect(variable.name == "user_preference")
        #expect(variable.valueType == "string")
    #expect(variable.value.value as? String == "dark_mode")
        #expect(variable.description == "User's theme preference")
        #expect(variable.createdAt == 1704067200)
        #expect(variable.updatedAt == 1704067300)
    }
}

// MARK: - Annotation Tests

struct AnnotationTests {
    @Test func testAnnotationResponse() throws {
        let json = """
        {
            "id": "ann123",
            "question": "What is Swift?",
            "answer": "Swift is a powerful programming language",
            "hit_count": 25,
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let annotation = try JSONDecoder.difyDecoder.decode(AnnotationResponse.self, from: json)
        
        #expect(annotation.id == "ann123")
        #expect(annotation.question == "What is Swift?")
        #expect(annotation.answer == "Swift is a powerful programming language")
        #expect(annotation.hitCount == 25)
        #expect(annotation.createdAt == 1704067200)
    }
}

// MARK: - File Upload Config Tests

struct FileUploadConfigTests {
    @Test func testFileUploadConfig() throws {
        let json = """
        {
            "image": {
                "enabled": true,
                "number_limits": 3,
                "transfer_methods": ["remote_url", "local_file"]
            }
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder.difyDecoder.decode(FileUploadConfig.self, from: json)
        
        #expect(config.image?.enabled == true)
        #expect(config.image?.numberLimits == 3)
        #expect(config.image?.transferMethods == ["remote_url", "local_file"])
    }
    
    @Test func testFileUploadConfigWithNilImage() throws {
        let json = """
        {
            "image": null
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder.difyDecoder.decode(FileUploadConfig.self, from: json)
        
        #expect(config.image == nil)
    }
}

// MARK: - Workflow Event Tests

struct WorkflowEventTests {
    @Test func testWorkflowStartedEvent() throws {
        let json = """
        {
            "event": "workflow_started",
            "task_id": "task123",
            "workflow_run_id": "run123",
            "data": {
                "id": "wf123",
                "workflow_id": "workflow123",
                "status": "running",
                "outputs": null,
                "error": null,
                "elapsed_time": 0.0,
                "total_tokens": 0,
                "total_steps": 0,
                "created_at": 1704067200,
                "finished_at": null
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(WorkflowStartedEvent.self, from: json)
        
        #expect(event.event == "workflow_started")
        #expect(event.taskId == "task123")
        #expect(event.workflowRunId == "run123")
        #expect(event.data.status == "running")
    }
    
    @Test func testWorkflowFinishedEvent() throws {
        let json = """
        {
            "event": "workflow_finished",
            "task_id": "task123",
            "workflow_run_id": "run123",
            "data": {
                "id": "wf123",
                "workflow_id": "workflow123",
                "status": "succeeded",
                "outputs": {"result": "done"},
                "error": null,
                "elapsed_time": 5.5,
                "total_tokens": 150,
                "total_steps": 5,
                "created_at": 1704067200,
                "finished_at": 1704067206
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(WorkflowFinishedEvent.self, from: json)
        
        #expect(event.event == "workflow_finished")
        #expect(event.taskId == "task123")
        #expect(event.workflowRunId == "run123")
        #expect(event.data.status == "succeeded")
        #expect(event.data.elapsedTime == 5.5)
    }
}

// MARK: - Comprehensive JSON Encoder/Decoder Tests

struct JSONCoderTests {
    @Test func testCustomEncoderDecoderConfiguration() throws {
        // Test that our custom encoders/decoders properly handle snake_case conversion
        struct TestModel: Codable {
            let firstName: String
            let lastName: String
            let createdAt: Int
            
            private enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
                case createdAt = "created_at"
            }
        }
        
        let model = TestModel(firstName: "John", lastName: "Doe", createdAt: 1704067200)
        
        // Encode
        let encoded = try JSONEncoder.difyEncoder.encode(model)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        
        #expect(json?["first_name"] as? String == "John")
        #expect(json?["last_name"] as? String == "Doe")
        #expect(json?["created_at"] as? Int == 1704067200)
        
        // Decode
        let jsonString = """
        {
            "first_name": "Jane",
            "last_name": "Smith",
            "created_at": 1704067300
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder.difyDecoder.decode(TestModel.self, from: jsonString)
        
        #expect(decoded.firstName == "Jane")
        #expect(decoded.lastName == "Smith")
        #expect(decoded.createdAt == 1704067300)
    }
}

// MARK: - Unicode and Special Characters Tests

struct UnicodeTests {
    @Test func testUnicodeInStrings() throws {
        let json = """
        {
            "name": "Test App 🚀",
            "description": "Unicode test: 中文 العربية 🎉",
            "tags": ["emoji-🔥", "unicode-测试"],
            "mode": "chat",
            "author_name": "作者"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: json)
        
        #expect(response.name == "Test App 🚀")
        #expect(response.description == "Unicode test: 中文 العربية 🎉")
        #expect(response.tags == ["emoji-🔥", "unicode-测试"])
        #expect(response.authorName == "作者")
    }
}

// MARK: - Empty Collections Tests

struct EmptyCollectionsTests {
    @Test func testEmptyArraysAndDictionaries() throws {
        let json = """
        {
            "name": "Empty Test",
            "description": "",
            "tags": [],
            "mode": "completion",
            "author_name": ""
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: json)
        
        #expect(response.name == "Empty Test")
        #expect(response.description == "")
        #expect(response.tags.isEmpty)
        #expect(response.mode == "completion")
        #expect(response.authorName == "")
    }
}

// MARK: - Deeply Nested Structure Tests

struct DeeplyNestedTests {
    @Test func testDeeplyNestedAnyCodable() throws {
        let value = AnyCodable([
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "level5": "deep value"
                        ]
                    ]
                ]
            ]
        ])
        
        let encoded = try JSONEncoder.difyEncoder.encode(value)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: encoded)
        
        if let dict1 = decoded.value as? [String: Any],
           let dict2 = dict1["level1"] as? [String: Any],
           let dict3 = dict2["level2"] as? [String: Any],
           let dict4 = dict3["level3"] as? [String: Any],
           let dict5 = dict4["level4"] as? [String: Any],
           let finalValue = dict5["level5"] as? String {
            #expect(finalValue == "deep value")
        } else {
            Issue.record("Failed to traverse deeply nested structure")
        }
    }
}

// MARK: - All Streaming Event Types Tests

struct AllStreamingEventTests {
    @Test func testAllStreamingCompletionEventTypes() throws {
        // Test message event
        let messageJson = """
        {
            "event": "message",
            "task_id": "task123",
            "message_id": "msg123",
            "answer": "test",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        let messageResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: messageJson)
        #expect(messageResponse.kind == .message)
        
        // Test message_end event
        let messageEndJson = """
        {
            "event": "message_end",
            "task_id": "task123",
            "message_id": "msg123",
            "metadata": {}
        }
        """.data(using: .utf8)!
        let messageEndResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: messageEndJson)
        #expect(messageEndResponse.kind == .messageEnd)
        
        // Test tts_message event
        let ttsMessageJson = """
        {
            "event": "tts_message",
            "task_id": "task123",
            "message_id": "msg123",
            "audio": "base64audio",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        let ttsMessageResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: ttsMessageJson)
        #expect(ttsMessageResponse.kind == .ttsMessage)
        
        // Test tts_message_end event
        let ttsMessageEndJson = """
        {
            "event": "tts_message_end",
            "task_id": "task123",
            "message_id": "msg123",
            "audio": "",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        let ttsMessageEndResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: ttsMessageEndJson)
        #expect(ttsMessageEndResponse.kind == .ttsMessageEnd)
        
        // Test message_replace event
        let messageReplaceJson = """
        {
            "event": "message_replace",
            "task_id": "task123",
            "message_id": "msg123",
            "conversation_id": "conv123",
            "answer": "replaced",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        let messageReplaceResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: messageReplaceJson)
        #expect(messageReplaceResponse.kind == .messageReplace)
        
        // Test error event
        let errorJson = """
        {
            "event": "error",
            "task_id": "task123",
            "message_id": "msg123",
            "status": 400,
            "code": "error",
            "message": "error message"
        }
        """.data(using: .utf8)!
        let errorResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: errorJson)
        #expect(errorResponse.kind == .error)
        
        // Test ping event
        let pingJson = """
        {"event": "ping"}
        """.data(using: .utf8)!
        let pingResponse = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: pingJson)
        #expect(pingResponse.kind == .ping)
        
        // Test unknown event (should not throw, preserves kind)
        let unknownJson = """
        {"event": "unknown_event"}
        """.data(using: .utf8)!
        let unknown = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: unknownJson)
        #expect(unknown.kind.rawValue == "unknown_event")
    }
    
    @Test func testAllStreamingChatEventTypes() throws {
        let eventTypes = [
            "message", "message_end", "agent_message", "agent_thought",
            "tts_message", "tts_message_end", "message_file", "message_replace",
            "workflow_started", "node_started", "node_finished", "workflow_finished",
            "error", "ping"
        ]
        
        for eventType in eventTypes {
            let json = """
            {"event": "\(eventType)"}
            """.data(using: .utf8)!
            
            _ = try? JSONDecoder.difyDecoder.decode(StreamingChatMessageResponse.self, from: json)
        }
    }
    
    @Test func testAllStreamingWorkflowEventTypes() throws {
        let eventTypes = [
            "workflow_started", "node_started", "node_finished",
            "workflow_finished", "text_chunk", "tts_message",
            "tts_message_end", "error", "ping"
        ]
        
        for eventType in eventTypes {
            let json = """
            {"event": "\(eventType)"}
            """.data(using: .utf8)!
            
            _ = try? JSONDecoder.difyDecoder.decode(StreamingWorkflowResponse.self, from: json)
        }
    }
    
    @Test func testUnknownEventKindsDoNotThrow() throws {
        let c = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: #"{"event":"new_kind"}"#.data(using: .utf8)!)
        #expect(c.kind.rawValue == "new_kind")
        let ch = try JSONDecoder.difyDecoder.decode(StreamingChatMessageResponse.self, from: #"{"event":"new_chat_kind"}"#.data(using: .utf8)!)
        #expect(ch.kind.rawValue == "new_chat_kind")
        let w = try JSONDecoder.difyDecoder.decode(StreamingWorkflowResponse.self, from: #"{"event":"new_workflow_kind"}"#.data(using: .utf8)!)
        #expect(w.kind.rawValue == "new_workflow_kind")
    }
}

// MARK: - Metadata Tests

struct MetadataTests {
    @Test func testMetadataWithAllFields() throws {
        let json = """
        {
            "usage": {
                "prompt_tokens": 100,
                "completion_tokens": 200,
                "total_tokens": 300,
                "prompt_unit_price": "0.001",
                "prompt_price_unit": "1K tokens",
                "prompt_price": "0.1",
                "completion_unit_price": "0.002",
                "completion_price_unit": "1K tokens",
                "completion_price": "0.4",
                "total_price": "0.5",
                "currency": "USD",
                "latency": 2.5
            },
            "retriever_resources": [
                {
                    "position": 1,
                    "dataset_id": "ds123",
                    "dataset_name": "Knowledge Base",
                    "document_id": "doc123",
                    "document_name": "Guide.pdf",
                    "segment_id": "seg123",
                    "score": 0.98,
                    "content": "Relevant content here"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let metadata = try JSONDecoder.difyDecoder.decode(Metadata.self, from: json)
        
        #expect(metadata.usage?.promptTokens == 100)
        #expect(metadata.usage?.completionTokens == 200)
        #expect(metadata.usage?.totalTokens == 300)
        #expect(metadata.usage?.currency == "USD")
        #expect(metadata.usage?.latency == 2.5)
        
        #expect(metadata.retrieverResources?.count == 1)
        #expect(metadata.retrieverResources?[0].score == 0.98)
    }
    
    @Test func testMetadataWithNullFields() throws {
        let json = """
        {
            "usage": null,
            "retriever_resources": null
        }
        """.data(using: .utf8)!
        
        let metadata = try JSONDecoder.difyDecoder.decode(Metadata.self, from: json)
        
        #expect(metadata.usage == nil)
        #expect(metadata.retrieverResources == nil)
    }
}

// MARK: - Boundary Value Tests

struct BoundaryValueTests {
    @Test func testZeroValues() throws {
        let json = """
        {
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "total_tokens": 0,
            "latency": 0.0
        }
        """.data(using: .utf8)!
        
        let usage = try JSONDecoder.difyDecoder.decode(Usage.self, from: json)
        
        #expect(usage.promptTokens == 0)
        #expect(usage.completionTokens == 0)
        #expect(usage.totalTokens == 0)
        #expect(usage.latency == 0.0)
    }
    
    @Test func testNegativeValues() throws {
        // Some fields might accidentally have negative values
        let json = """
        {
            "position": -1,
            "dataset_id": "ds123",
            "dataset_name": "Dataset",
            "document_id": "doc123",
            "document_name": "Doc",
            "segment_id": "seg123",
            "score": -0.5,
            "content": "Content"
        }
        """.data(using: .utf8)!
        
        let resource = try JSONDecoder.difyDecoder.decode(RetrieverResource.self, from: json)
        
        #expect(resource.position == -1)
        #expect(resource.score == -0.5)
    }
}

// MARK: - All Event Structs Tests

struct AllEventStructsTests {
    @Test func testMessageStreamEvent() throws {
        let json = """
        {
            "event": "message",
            "task_id": "task123",
            "message_id": "msg123",
            "answer": "Stream answer",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(MessageStreamEvent.self, from: json)
        
        #expect(event.event == "message")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.answer == "Stream answer")
        #expect(event.createdAt == 1704067200)
    }
    
    @Test func testMessageEndStreamEvent() throws {
        let json = """
        {
            "event": "message_end",
            "task_id": "task123",
            "message_id": "msg123",
            "metadata": {
                "usage": {
                    "prompt_tokens": 50,
                    "completion_tokens": 100,
                    "total_tokens": 150
                }
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(MessageEndStreamEvent.self, from: json)
        
        #expect(event.event == "message_end")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.metadata.usage?.totalTokens == 150)
    }
    
    @Test func testNodeStartedEvent() throws {
        let json = """
        {
            "event": "node_started",
            "task_id": "task123",
            "data": {
                "id": "node123",
                "node_id": "n123",
                "node_type": "llm",
                "index": 0,
                "title": "LLM Node",
                "predecessor_node_id": null,
                "inputs": {},
                "process_data": {},
                "outputs": {},
                "status": "running",
                "error": null,
                "elapsed_time": 0.0,
                "execution_metadata": null,
                "created_at": 1704067200
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(NodeStartedEvent.self, from: json)
        
        #expect(event.event == "node_started")
        #expect(event.taskId == "task123")
        #expect(event.data.nodeType == "llm")
        #expect(event.data.status == "running")
    }
    
    @Test func testNodeFinishedEvent() throws {
        let json = """
        {
            "event": "node_finished",
            "task_id": "task123",
            "data": {
                "id": "node123",
                "node_id": "n123",
                "node_type": "llm",
                "index": 0,
                "title": "LLM Node",
                "predecessor_node_id": null,
                "inputs": {"prompt": "Hello"},
                "process_data": {},
                "outputs": {"response": "Hi there"},
                "status": "succeeded",
                "error": null,
                "elapsed_time": 1.5,
                "execution_metadata": {
                    "total_tokens": 50,
                    "total_price": 0.05,
                    "currency": "USD"
                },
                "created_at": 1704067200
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(NodeFinishedEvent.self, from: json)
        
        #expect(event.event == "node_finished")
        #expect(event.data.status == "succeeded")
        #expect(event.data.elapsedTime == 1.5)
        #expect(event.data.executionMetadata?.totalTokens == 50)
    }
    
    @Test func testTextChunkEvent() throws {
        let json = """
        {
            "event": "text_chunk",
            "task_id": "task123",
            "workflow_run_id": "run123",
            "data": {
                "text": "This is a text chunk",
                "from_variable_selector": ["node1", "output"]
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(TextChunkEvent.self, from: json)
        
        #expect(event.event == "text_chunk")
        #expect(event.taskId == "task123")
        #expect(event.workflowRunId == "run123")
        #expect(event.data.text == "This is a text chunk")
        #expect(event.data.fromVariableSelector == ["node1", "output"])
    }
    
    @Test func testAgentMessageStreamEvent() throws {
        let json = """
        {
            "event": "agent_message",
            "task_id": "task123",
            "message_id": "msg123",
            "conversation_id": "conv123",
            "answer": "Agent is thinking...",
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder.difyDecoder.decode(AgentMessageStreamEvent.self, from: json)
        
        #expect(event.event == "agent_message")
        #expect(event.taskId == "task123")
        #expect(event.messageId == "msg123")
        #expect(event.conversationId == "conv123")
        #expect(event.answer == "Agent is thinking...")
        #expect(event.createdAt == 1704067200)
    }
}

// MARK: - Final Coverage Tests

struct FinalCoverageTests {
    @Test func testWorkflowLogEntry() throws {
        let json = """
        {
            "id": "log123",
            "workflow_run": {
                "id": "run123",
                "version": "1.0.0",
                "status": "succeeded",
                "error": null,
                "elapsed_time": 3.5,
                "total_tokens": 100,
                "total_steps": 5,
                "created_at": 1704067200,
                "finished_at": 1704067204
            },
            "created_from": "api",
            "created_by_role": "end_user",
            "created_by_account": null,
            "created_by_end_user": {
                "id": "user123",
                "type": "service_api",
                "is_anonymous": false,
                "session_id": "session123"
            },
            "created_at": 1704067200
        }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder.difyDecoder.decode(WorkflowLogEntry.self, from: json)
        
        #expect(entry.id == "log123")
        #expect(entry.workflowRun.id == "run123")
        #expect(entry.workflowRun.version == "1.0.0")
        #expect(entry.workflowRun.status == "succeeded")
        #expect(entry.createdFrom == "api")
        #expect(entry.createdByRole == "end_user")
        #expect(entry.createdByAccount == nil)
        #expect(entry.createdByEndUser.id == "user123")
        #expect(entry.createdAt == 1704067200)
    }
    
    @Test func testChatMessage() throws {
        let json = """
        {
            "id": "msg123",
            "conversation_id": "conv123",
            "inputs": {"user_input": "Hello"},
            "query": "What is the weather?",
            "message_files": [],
            "agent_thoughts": [],
            "answer": "I can help with weather information.",
            "created_at": 1704067200,
            "feedback": null,
            "retriever_resources": null
        }
        """.data(using: .utf8)!
        
        let message = try JSONDecoder.difyDecoder.decode(ChatMessage.self, from: json)
        
        #expect(message.id == "msg123")
        #expect(message.conversationId == "conv123")
        #expect(message.query == "What is the weather?")
        #expect(message.answer == "I can help with weather information.")
        #expect(message.messageFiles.isEmpty)
        #expect(message.agentThoughts.isEmpty)
        #expect(message.feedback == nil)
        #expect(message.retrieverResources == nil)
    }
    
    @Test func testApplicationFeedback() throws {
        let json = """
        {
            "id": "feedback123",
            "app_id": "app123",
            "conversation_id": "conv123",
            "message_id": "msg123",
            "rating": "dislike",
            "content": "Not helpful",
            "from_source": "webapp",
            "from_end_user_id": "user123",
            "from_account_id": null,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:01:00Z"
        }
        """.data(using: .utf8)!
        
        let feedback = try JSONDecoder.difyDecoder.decode(ApplicationFeedback.self, from: json)
        
        #expect(feedback.id == "feedback123")
        #expect(feedback.appId == "app123")
        #expect(feedback.conversationId == "conv123")
        #expect(feedback.messageId == "msg123")
        #expect(feedback.rating == "dislike")
        #expect(feedback.content == "Not helpful")
        #expect(feedback.fromSource == "webapp")
        #expect(feedback.fromEndUserId == "user123")
        #expect(feedback.fromAccountId == nil)
        #expect(feedback.createdAt == "2024-01-01T00:00:00Z")
        #expect(feedback.updatedAt == "2024-01-01T00:01:00Z")
    }
}
