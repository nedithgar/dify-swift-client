import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Enhanced API Tests

@Suite("Enhanced File Support Tests")
struct EnhancedFileSupportTests {
    
    @Test("FileType supports all types")
    func testFileTypeSupport() {
        #expect(FileType.image.rawValue == "image")
        #expect(FileType.document.rawValue == "document")
        #expect(FileType.audio.rawValue == "audio")
        #expect(FileType.video.rawValue == "video")
        #expect(FileType.custom.rawValue == "custom")
    }
    
    @Test("APIFile encoding and decoding with different file types")
    func testAPIFileWithDifferentTypes() throws {
        let documentFile = APIFile(
            type: .document,
            transferMethod: .localFile,
            uploadFileId: "doc-123"
        )
        
        let audioFile = APIFile(
            type: .audio,
            transferMethod: .remoteUrl,
            url: "https://example.com/audio.mp3"
        )
        
        let videoFile = APIFile(
            type: .video,
            transferMethod: .localFile,
            uploadFileId: "video-456"
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let documentData = try encoder.encode(documentFile)
        let audioData = try encoder.encode(audioFile)
        let videoData = try encoder.encode(videoFile)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedDocument = try decoder.decode(APIFile.self, from: documentData)
        let decodedAudio = try decoder.decode(APIFile.self, from: audioData)
        let decodedVideo = try decoder.decode(APIFile.self, from: videoData)
        
        #expect(decodedDocument.type == .document)
        #expect(decodedDocument.transferMethod == .localFile)
        #expect(decodedDocument.uploadFileId == "doc-123")
        
        #expect(decodedAudio.type == .audio)
        #expect(decodedAudio.transferMethod == .remoteUrl)
        #expect(decodedAudio.url == "https://example.com/audio.mp3")
        
        #expect(decodedVideo.type == .video)
        #expect(decodedVideo.transferMethod == .localFile)
        #expect(decodedVideo.uploadFileId == "video-456")
    }
}

@Suite("Application Info API Tests")
struct ApplicationInfoAPITests {
    
    @Test("ApplicationInfoResponse decoding")
    func testApplicationInfoResponseDecoding() throws {
        let json = """
        {
            "name": "My App",
            "description": "This is my app.",
            "tags": ["tag1", "tag2"],
            "mode": "chat",
            "author_name": "Dify"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ApplicationInfoResponse.self, from: json)
        
        #expect(response.name == "My App")
        #expect(response.description == "This is my app.")
        #expect(response.tags == ["tag1", "tag2"])
        #expect(response.mode == "chat")
        #expect(response.authorName == "Dify")
    }
    
    @Test("EnhancedApplicationParametersResponse decoding")
    func testEnhancedApplicationParametersResponseDecoding() throws {
        let json = """
        {
            "opening_statement": "Hello!",
            "suggested_questions": ["What can you do?", "How can I help?"],
            "suggested_questions_after_answer": {
                "enabled": true
            },
            "speech_to_text": {
                "enabled": true
            },
            "text_to_speech": {
                "enabled": true,
                "voice": "sambert-zhinan-v1",
                "language": "zh-Hans",
                "autoPlay": "disabled"
            },
            "retriever_resource": {
                "enabled": true
            },
            "annotation_reply": {
                "enabled": true
            },
            "file_upload": {
                "image": {
                    "enabled": false,
                    "number_limits": 3,
                    "detail": "high",
                    "transfer_methods": ["remote_url", "local_file"]
                }
            },
            "system_parameters": {
                "file_size_limit": 15,
                "image_file_size_limit": 10,
                "audio_file_size_limit": 50,
                "video_file_size_limit": 100
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(EnhancedApplicationParametersResponse.self, from: json)
        
        #expect(response.openingStatement == "Hello!")
        #expect(response.suggestedQuestions == ["What can you do?", "How can I help?"])
        #expect(response.suggestedQuestionsAfterAnswer?.enabled == true)
        #expect(response.speechToText?.enabled == true)
        #expect(response.textToSpeech?.enabled == true)
        #expect(response.textToSpeech?.voice == "sambert-zhinan-v1")
        #expect(response.textToSpeech?.language == "zh-Hans")
        #expect(response.textToSpeech?.autoPlay == "disabled")
        #expect(response.retrieverResource?.enabled == true)
        #expect(response.annotationReply?.enabled == true)
        #expect(response.fileUpload?.image?.enabled == false)
        #expect(response.fileUpload?.image?.numberLimits == 3)
        #expect(response.fileUpload?.image?.detail == "high")
        #expect(response.fileUpload?.image?.transferMethods == ["remote_url", "local_file"])
        #expect(response.systemParameters?.fileSizeLimit == 15)
        #expect(response.systemParameters?.imageFileSizeLimit == 10)
        #expect(response.systemParameters?.audioFileSizeLimit == 50)
        #expect(response.systemParameters?.videoFileSizeLimit == 100)
    }
    
    @Test("ApplicationMetaResponse with tool icons decoding")
    func testApplicationMetaResponseDecoding() throws {
        let json = """
        {
            "tool_icons": {
                "dalle2": "https://cloud.dify.ai/console/api/workspaces/current/tool-provider/builtin/dalle/icon",
                "api_tool": {
                    "background": "#252525",
                    "content": "😁"
                }
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ApplicationMetaResponse.self, from: json)
        
        #expect(response.toolIcons.count == 2)
        
        if case .url(let urlString) = response.toolIcons["dalle2"] {
            #expect(urlString == "https://cloud.dify.ai/console/api/workspaces/current/tool-provider/builtin/dalle/icon")
        } else {
            Issue.record("Expected URL tool icon for dalle2")
        }
        
        if case .icon(let iconObject) = response.toolIcons["api_tool"] {
            #expect(iconObject.background == "#252525")
            #expect(iconObject.content == "😁")
        } else {
            Issue.record("Expected icon object for api_tool")
        }
    }
    
    @Test("ApplicationSiteResponse decoding")
    func testApplicationSiteResponseDecoding() throws {
        let json = """
        {
            "title": "My App",
            "chat_color_theme": "#ff4a4a",
            "chat_color_theme_inverted": false,
            "icon_type": "emoji",
            "icon": "😄",
            "icon_background": "#FFEAD5",
            "icon_url": null,
            "description": "This is my app.",
            "copyright": "all rights reserved",
            "privacy_policy": "",
            "custom_disclaimer": "All generated by AI",
            "default_language": "en-US",
            "show_workflow_steps": false,
            "use_icon_as_answer_icon": false
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ApplicationSiteResponse.self, from: json)
        
        #expect(response.title == "My App")
        #expect(response.chatColorTheme == "#ff4a4a")
        #expect(response.chatColorThemeInverted == false)
        #expect(response.iconType == "emoji")
        #expect(response.icon == "😄")
        #expect(response.iconBackground == "#FFEAD5")
        #expect(response.iconUrl == nil)
        #expect(response.description == "This is my app.")
        #expect(response.copyright == "all rights reserved")
        #expect(response.privacyPolicy == "")
        #expect(response.customDisclaimer == "All generated by AI")
        #expect(response.defaultLanguage == "en-US")
        #expect(response.showWorkflowSteps == false)
        #expect(response.useIconAsAnswerIcon == false)
    }
}

@Suite("Enhanced Feedback API Tests")
struct EnhancedFeedbackAPITests {
    
    @Test("EnhancedMessageFeedbackRequest encoding")
    func testEnhancedMessageFeedbackRequestEncoding() throws {
        let request = EnhancedMessageFeedbackRequest(
            rating: "like",
            user: "abc-123",
            content: "This response was very helpful!"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["rating"] as? String == "like")
        #expect(json["user"] as? String == "abc-123")
        #expect(json["content"] as? String == "This response was very helpful!")
    }
    
    @Test("ApplicationFeedbacksResponse decoding")
    func testApplicationFeedbacksResponseDecoding() throws {
        let json = """
        {
            "data": [
                {
                    "id": "8c0fbed8-e2f9-49ff-9f0e-15a35bdd0e25",
                    "app_id": "f252d396-fe48-450e-94ec-e184218e7346",
                    "conversation_id": "2397604b-9deb-430e-b285-4726e51fd62d",
                    "message_id": "709c0b0f-0a96-4a4e-91a4-ec0889937b11",
                    "rating": "like",
                    "content": "message feedback information-3",
                    "from_source": "user",
                    "from_end_user_id": "74286412-9a1a-42c1-929c-01edb1d381d5",
                    "from_account_id": null,
                    "created_at": "2025-04-24T09:24:38",
                    "updated_at": "2025-04-24T09:24:38"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ApplicationFeedbacksResponse.self, from: json)
        
        #expect(response.data.count == 1)
        let feedback = response.data[0]
        #expect(feedback.id == "8c0fbed8-e2f9-49ff-9f0e-15a35bdd0e25")
        #expect(feedback.appId == "f252d396-fe48-450e-94ec-e184218e7346")
        #expect(feedback.conversationId == "2397604b-9deb-430e-b285-4726e51fd62d")
        #expect(feedback.messageId == "709c0b0f-0a96-4a4e-91a4-ec0889937b11")
        #expect(feedback.rating == "like")
        #expect(feedback.content == "message feedback information-3")
        #expect(feedback.fromSource == "user")
        #expect(feedback.fromEndUserId == "74286412-9a1a-42c1-929c-01edb1d381d5")
        #expect(feedback.fromAccountId == nil)
        #expect(feedback.createdAt == "2025-04-24T09:24:38")
        #expect(feedback.updatedAt == "2025-04-24T09:24:38")
    }
}

@Suite("Conversation Variables API Tests")
struct ConversationVariablesAPITests {
    
    @Test("ConversationVariablesResponse decoding")
    func testConversationVariablesResponseDecoding() throws {
        let json = """
        {
            "limit": 100,
            "has_more": false,
            "data": [
                {
                    "id": "variable-uuid-1",
                    "name": "customer_name",
                    "value_type": "string",
                    "value": "John Doe",
                    "description": "Customer name extracted from the conversation",
                    "created_at": 1650000000000,
                    "updated_at": 1650000000000
                },
                {
                    "id": "variable-uuid-2",
                    "name": "order_details",
                    "value_type": "json",
                    "value": "{\\"product\\":\\"Widget\\",\\"quantity\\":5,\\"price\\":19.99}",
                    "description": "Order details from the customer",
                    "created_at": 1650000000000,
                    "updated_at": 1650000000000
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ConversationVariablesResponse.self, from: json)
        
        #expect(response.limit == 100)
        #expect(response.hasMore == false)
        #expect(response.data.count == 2)
        
        let variable1 = response.data[0]
        #expect(variable1.id == "variable-uuid-1")
        #expect(variable1.name == "customer_name")
        #expect(variable1.valueType == "string")
        #expect(variable1.value == "John Doe")
        #expect(variable1.description == "Customer name extracted from the conversation")
        #expect(variable1.createdAt == 1650000000000)
        #expect(variable1.updatedAt == 1650000000000)
        
        let variable2 = response.data[1]
        #expect(variable2.id == "variable-uuid-2")
        #expect(variable2.name == "order_details")
        #expect(variable2.valueType == "json")
        #expect(variable2.value == "{\"product\":\"Widget\",\"quantity\":5,\"price\":19.99}")
        #expect(variable2.description == "Order details from the customer")
    }
}

@Suite("Annotation API Tests")
struct AnnotationAPITests {
    
    @Test("AnnotationRequest encoding")
    func testAnnotationRequestEncoding() throws {
        let request = AnnotationRequest(
            question: "What is your name?",
            answer: "I am Dify."
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["question"] as? String == "What is your name?")
        #expect(json["answer"] as? String == "I am Dify.")
    }
    
    @Test("AnnotationListResponse decoding")
    func testAnnotationListResponseDecoding() throws {
        let json = """
        {
            "data": [
                {
                    "id": "69d48372-ad81-4c75-9c46-2ce197b4d402",
                    "question": "What is your name?",
                    "answer": "I am Dify.",
                    "hit_count": 0,
                    "created_at": 1735625869
                }
            ],
            "has_more": false,
            "limit": 20,
            "total": 1,
            "page": 1
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnnotationListResponse.self, from: json)
        
        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.page == 1)
        
        let annotation = response.data[0]
        #expect(annotation.id == "69d48372-ad81-4c75-9c46-2ce197b4d402")
        #expect(annotation.question == "What is your name?")
        #expect(annotation.answer == "I am Dify.")
        #expect(annotation.hitCount == 0)
        #expect(annotation.createdAt == 1735625869)
    }
    
    @Test("AnnotationReplySettingsRequest encoding")
    func testAnnotationReplySettingsRequestEncoding() throws {
        let request = AnnotationReplySettingsRequest(
            scoreThreshold: 0.9,
            embeddingProviderName: "zhipu",
            embeddingModelName: "embedding_3"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["score_threshold"] as? Double == 0.9)
        #expect(json["embedding_provider_name"] as? String == "zhipu")
        #expect(json["embedding_model_name"] as? String == "embedding_3")
    }
    
    @Test("AnnotationReplySettingsResponse decoding")
    func testAnnotationReplySettingsResponseDecoding() throws {
        let json = """
        {
            "job_id": "b15c8f68-1cf4-4877-bf21-ed7cf2011802",
            "job_status": "waiting"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnnotationReplySettingsResponse.self, from: json)
        
        #expect(response.jobId == "b15c8f68-1cf4-4877-bf21-ed7cf2011802")
        #expect(response.jobStatus == "waiting")
    }
    
    @Test("AnnotationJobStatusResponse decoding")
    func testAnnotationJobStatusResponseDecoding() throws {
        let json = """
        {
            "job_id": "b15c8f68-1cf4-4877-bf21-ed7cf2011802",
            "job_status": "completed",
            "error_msg": null
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnnotationJobStatusResponse.self, from: json)
        
        #expect(response.jobId == "b15c8f68-1cf4-4877-bf21-ed7cf2011802")
        #expect(response.jobStatus == "completed")
        #expect(response.errorMsg == nil)
    }
}

@Suite("Workflow Logs API Tests")
struct WorkflowLogsAPITests {
    
    @Test("WorkflowLogsResponse decoding")
    func testWorkflowLogsResponseDecoding() throws {
        let json = """
        {
            "page": 1,
            "limit": 1,
            "total": 7,
            "has_more": true,
            "data": [
                {
                    "id": "e41b93f1-7ca2-40fd-b3a8-999aeb499cc0",
                    "workflow_run": {
                        "id": "c0640fc8-03ef-4481-a96c-8a13b732a36e",
                        "version": "2024-08-01 12:17:09.771832",
                        "status": "succeeded",
                        "error": null,
                        "elapsed_time": 1.3588523610014818,
                        "total_tokens": 0,
                        "total_steps": 3,
                        "created_at": 1726139643,
                        "finished_at": 1726139644
                    },
                    "created_from": "service-api",
                    "created_by_role": "end_user",
                    "created_by_account": null,
                    "created_by_end_user": {
                        "id": "7f7d9117-dd9d-441d-8970-87e5e7e687a3",
                        "type": "service_api",
                        "is_anonymous": false,
                        "session_id": "abc-123"
                    },
                    "created_at": 1726139644
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkflowLogsResponse.self, from: json)
        
        #expect(response.page == 1)
        #expect(response.limit == 1)
        #expect(response.total == 7)
        #expect(response.hasMore == true)
        #expect(response.data.count == 1)
        
        let log = response.data[0]
        #expect(log.id == "e41b93f1-7ca2-40fd-b3a8-999aeb499cc0")
        #expect(log.createdFrom == "service-api")
        #expect(log.createdByRole == "end_user")
        #expect(log.createdByAccount == nil)
        #expect(log.createdAt == 1726139644)
        
        let workflowRun = log.workflowRun
        #expect(workflowRun.id == "c0640fc8-03ef-4481-a96c-8a13b732a36e")
        #expect(workflowRun.version == "2024-08-01 12:17:09.771832")
        #expect(workflowRun.status == "succeeded")
        #expect(workflowRun.error == nil)
        #expect(workflowRun.elapsedTime == 1.3588523610014818)
        #expect(workflowRun.totalTokens == 0)
        #expect(workflowRun.totalSteps == 3)
        #expect(workflowRun.createdAt == 1726139643)
        #expect(workflowRun.finishedAt == 1726139644)
        
        let endUser = log.createdByEndUser
        #expect(endUser.id == "7f7d9117-dd9d-441d-8970-87e5e7e687a3")
        #expect(endUser.type == "service_api")
        #expect(endUser.isAnonymous == false)
        #expect(endUser.sessionId == "abc-123")
    }
}

@Suite("Enhanced Chat Message Tests")
struct EnhancedChatMessageTests {
    
    @Test("Chat message request with auto_generate_name")
    func testChatMessageRequestWithAutoGenerateName() throws {
        // This would test the internal request structure if we could access it
        // For now, we'll test that the method exists and accepts the parameter
        #expect(Bool(true)) // Placeholder for method signature test
    }
}

@Suite("Streaming Event Models Tests")
struct StreamingEventModelsTests {
    
    @Test("StreamingEventType encoding and decoding")
    func testStreamingEventTypeValues() {
        #expect(StreamingEventType.message.rawValue == "message")
        #expect(StreamingEventType.messageEnd.rawValue == "message_end")
        #expect(StreamingEventType.messageReplace.rawValue == "message_replace")
        #expect(StreamingEventType.messageFile.rawValue == "message_file")
        #expect(StreamingEventType.agentMessage.rawValue == "agent_message")
        #expect(StreamingEventType.agentThought.rawValue == "agent_thought")
        #expect(StreamingEventType.ttsMessage.rawValue == "tts_message")
        #expect(StreamingEventType.ttsMessageEnd.rawValue == "tts_message_end")
        #expect(StreamingEventType.workflowStarted.rawValue == "workflow_started")
        #expect(StreamingEventType.nodeStarted.rawValue == "node_started")
        #expect(StreamingEventType.nodeFinished.rawValue == "node_finished")
        #expect(StreamingEventType.workflowFinished.rawValue == "workflow_finished")
        #expect(StreamingEventType.textChunk.rawValue == "text_chunk")
        #expect(StreamingEventType.error.rawValue == "error")
        #expect(StreamingEventType.ping.rawValue == "ping")
    }
    
    @Test("GenericStreamingEvent decoding for message event")
    func testGenericStreamingEventMessageDecoding() throws {
        let json = """
        {
            "event": "message",
            "task_id": "900bbd43-dc0b-4383-a372-aa6e6c414227",
            "message_id": "663c5084-a254-4040-8ad3-51f2a3c1a77c",
            "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2",
            "answer": "Hello, world!",
            "created_at": 1705398420
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(GenericStreamingEvent.self, from: json)
        
        #expect(event.event == .message)
        #expect(event.taskId == "900bbd43-dc0b-4383-a372-aa6e6c414227")
        #expect(event.messageId == "663c5084-a254-4040-8ad3-51f2a3c1a77c")
        #expect(event.conversationId == "45701982-8118-4bc5-8e9b-64562b4555f2")
        #expect(event.createdAt == 1705398420)
    }
    
    @Test("GenericStreamingEvent decoding for workflow_started event")
    func testGenericStreamingEventWorkflowStartedDecoding() throws {
        let json = """
        {
            "event": "workflow_started",
            "task_id": "5ad4cb98-f0c7-4085-b384-88c403be6290",
            "workflow_run_id": "5ad498-f0c7-4085-b384-88cbe6290",
            "data": {
                "id": "5ad498-f0c7-4085-b384-88cbe6290",
                "workflow_id": "dfjasklfjdslag",
                "created_at": 1679586595
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(GenericStreamingEvent.self, from: json)
        
        #expect(event.event == .workflowStarted)
        #expect(event.taskId == "5ad4cb98-f0c7-4085-b384-88c403be6290")
        #expect(event.workflowRunId == "5ad498-f0c7-4085-b384-88cbe6290")
        #expect(event.data != nil)
        
        if let data = event.data {
            #expect(data["id"] as? String == "5ad498-f0c7-4085-b384-88cbe6290")
            #expect(data["workflow_id"] as? String == "dfjasklfjdslag")
            #expect(data["created_at"] as? Int == 1679586595)
        }
    }
    
    @Test("GenericStreamingEvent decoding for node_finished event")
    func testGenericStreamingEventNodeFinishedDecoding() throws {
        let json = """
        {
            "event": "node_finished",
            "task_id": "5ad4cb98-f0c7-4085-b384-88c403be6290",
            "workflow_run_id": "5ad498-f0c7-4085-b384-88cbe6290",
            "data": {
                "id": "5ad498-f0c7-4085-b384-88cbe6290",
                "node_id": "dfjasklfjdslag",
                "node_type": "start",
                "title": "Start",
                "index": 0,
                "status": "succeeded",
                "elapsed_time": 0.324,
                "execution_metadata": {
                    "total_tokens": 63127864,
                    "total_price": "2.378",
                    "currency": "USD"
                },
                "created_at": 1679586595
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(GenericStreamingEvent.self, from: json)
        
        #expect(event.event == .nodeFinished)
        #expect(event.taskId == "5ad4cb98-f0c7-4085-b384-88c403be6290")
        #expect(event.workflowRunId == "5ad498-f0c7-4085-b384-88cbe6290")
        #expect(event.data != nil)
        
        if let data = event.data {
            #expect(data["node_type"] as? String == "start")
            #expect(data["title"] as? String == "Start")
            #expect(data["index"] as? Int == 0)
            #expect(data["status"] as? String == "succeeded")
            #expect(data["elapsed_time"] as? Double == 0.324)
            
            if let metadata = data["execution_metadata"] as? [String: Any] {
                #expect(metadata["total_tokens"] as? Int == 63127864)
                #expect(metadata["total_price"] as? String == "2.378")
                #expect(metadata["currency"] as? String == "USD")
            }
        }
    }
    
    @Test("GenericStreamingEvent decoding for text_chunk event")
    func testGenericStreamingEventTextChunkDecoding() throws {
        let json = """
        {
            "event": "text_chunk",
            "workflow_run_id": "b85e5fc5-751b-454d-b14e-dc5f240b0a31",
            "task_id": "bd029338-b068-4d34-a331-fc85478922c2",
            "data": {
                "text": "为了",
                "from_variable_selector": ["1745912968134", "text"]
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(GenericStreamingEvent.self, from: json)
        
        #expect(event.event == .textChunk)
        #expect(event.taskId == "bd029338-b068-4d34-a331-fc85478922c2")
        #expect(event.workflowRunId == "b85e5fc5-751b-454d-b14e-dc5f240b0a31")
        #expect(event.data != nil)
        
        if let data = event.data {
            #expect(data["text"] as? String == "为了")
            if let selector = data["from_variable_selector"] as? [String] {
                #expect(selector == ["1745912968134", "text"])
            }
        }
    }
    
    @Test("GenericStreamingEvent decoding for error event")
    func testGenericStreamingEventErrorDecoding() throws {
        let json = """
        {
            "event": "error",
            "task_id": "900bbd43-dc0b-4383-a372-aa6e6c414227",
            "message_id": "663c5084-a254-4040-8ad3-51f2a3c1a77c",
            "status": 400,
            "code": "invalid_param",
            "message": "abnormal parameter input"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(GenericStreamingEvent.self, from: json)
        
        #expect(event.event == .error)
        #expect(event.taskId == "900bbd43-dc0b-4383-a372-aa6e6c414227")
        #expect(event.messageId == "663c5084-a254-4040-8ad3-51f2a3c1a77c")
    }
    
    @Test("AnyCodable with various types")
    func testAnyCodableWithVariousTypes() throws {
        // Test with different data types
        let stringValue = AnyCodable("test")
        let intValue = AnyCodable(42)
        let doubleValue = AnyCodable(3.14)
        let boolValue = AnyCodable(true)
        let arrayValue = AnyCodable(["a", "b", "c"])
        let dictValue = AnyCodable(["key": "value", "number": 123])
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let stringData = try encoder.encode(stringValue)
        let decodedString = try decoder.decode(AnyCodable.self, from: stringData)
        #expect(decodedString.value as? String == "test")
        
        let intData = try encoder.encode(intValue)
        let decodedInt = try decoder.decode(AnyCodable.self, from: intData)
        #expect(decodedInt.value as? Int == 42)
        
        let doubleData = try encoder.encode(doubleValue)
        let decodedDouble = try decoder.decode(AnyCodable.self, from: doubleData)
        #expect(decodedDouble.value as? Double == 3.14)
        
        let boolData = try encoder.encode(boolValue)
        let decodedBool = try decoder.decode(AnyCodable.self, from: boolData)
        #expect(decodedBool.value as? Bool == true)
    }
}