import Foundation
import Testing
@testable import DifySwiftClient

// MARK: - Mock Data Provider

/// Provides predefined mock responses for all Dify API endpoints
public final class MockDataProvider: @unchecked Sendable {
    
    // MARK: - Test Configuration
    
    public static let testApiKey = "app-test-api-key-12345"
    public static let testUser = "test-user-123"
    public static let testConversationId = "test-conversation-456"
    public static let testMessageId = "test-message-789"
    public static let testWorkflowRunId = "test-workflow-run-abc"
    public static let testDatasetId = "test-dataset-def"
    public static let testDocumentId = "test-document-ghi"
    
    // MARK: - Chat API Responses
    
    nonisolated(unsafe) public static let chatMessageResponse: [String: Any] = [
        "event": "message",
        "task_id": "test-task-123",
        "id": testMessageId,
        "message_id": testMessageId,
        "conversation_id": testConversationId,
        "mode": "chat",
        "answer": "Hello! How can I help you today?",
        "metadata": [
            "usage": [
                "prompt_tokens": 20,
                "prompt_unit_price": "0.001",
                "prompt_price_unit": "0.001",
                "prompt_price": "0.0002",
                "completion_tokens": 12,
                "completion_unit_price": "0.002", 
                "completion_price_unit": "0.001",
                "completion_price": "0.0024",
                "total_tokens": 32,
                "total_price": "0.0026",
                "currency": "USD",
                "latency": 0.7682376861572266
            ]
        ],
        "created_at": 1726139644
    ]
    
    nonisolated(unsafe)
    public static let chatStreamingChunk: [String: Any] = [
        "event": "message",
        "message_id": testMessageId,
        "conversation_id": testConversationId,
        "answer": "Hello",
        "created_at": 1726139644
    ]
    
    nonisolated(unsafe)
    public static let suggestedMessagesResponse: [String: Any] = [
        "data": [
            "What is the weather like today?",
            "Tell me a joke",
            "How can I improve my productivity?"
        ]
    ]
    
    nonisolated(unsafe)
    public static let conversationsResponse: [String: Any] = [
        "data": [
            [
                "id": testConversationId,
                "name": "Test Conversation",
                "inputs": [:],
                "status": "normal",
                "introduction": "This is a test conversation",
                "created_at": 1726139000,
                "updated_at": 1726139644
            ]
        ],
        "has_more": false,
        "limit": 20
    ]
    
    nonisolated(unsafe)
    public static let conversationMessagesResponse: [String: Any] = [
        "data": [
            [
                "id": testMessageId,
                "conversation_id": testConversationId,
                "inputs": [:],
                "query": "Hello",
                "answer": "Hi there! How can I help you?",
                "message_files": [],
                "feedback": NSNull(),
                "retriever_resources": [],
                "created_at": 1726139644,
                "agent_thoughts": []
            ]
        ],
        "has_more": false,
        "limit": 20
    ]
    
    // MARK: - New Chat API Responses (from template_chat.en.mdx)
    
    nonisolated(unsafe)
    public static let suggestedQuestionsResponse: [String: Any] = [
        "result": "success",
        "data": [
            "What can you help me with?",
            "How does this feature work?",
            "Can you provide more examples?"
        ]
    ]
    
    nonisolated(unsafe)
    public static let conversationVariablesResponse: [String: Any] = [
        "limit": 100,
        "has_more": false,
        "data": [
            [
                "id": "variable-uuid-1",
                "name": "customer_name",
                "value_type": "string",
                "value": "John Doe",
                "description": "Customer name extracted from the conversation",
                "created_at": 1650000000000,
                "updated_at": 1650000000000
            ],
            [
                "id": "variable-uuid-2",
                "name": "order_details",
                "value_type": "json",
                "value": "{\"product\":\"Widget\",\"quantity\":5,\"price\":19.99}",
                "description": "Order details from the customer",
                "created_at": 1650000000000,
                "updated_at": 1650000000000
            ]
        ]
    ]
    
    nonisolated(unsafe)
    public static let audioToTextResponse: [String: Any] = [
        "text": "Hello, this is a test audio transcription."
    ]
    
    nonisolated(unsafe)
    public static let chatApplicationFeedbacksResponse: [String: Any] = [
        "data": [
            [
                "id": "8c0fbed8-e2f9-49ff-9f0e-15a35bdd0e25",
                "app_id": "f252d396-fe48-450e-94ec-e184218e7346",
                "conversation_id": "2397604b-9deb-430e-b285-4726e51fd62d",
                "message_id": "709c0b0f-0a96-4a4e-91a4-ec0889937b11",
                "rating": "like",
                "content": "message feedback information-3",
                "from_source": "user",
                "from_end_user_id": "74286412-9a1a-42c1-929c-01edb1d381d5",
                "from_account_id": NSNull(),
                "created_at": "2025-04-24T09:24:38",
                "updated_at": "2025-04-24T09:24:38"
            ]
        ]
    ]
    
    nonisolated(unsafe)
    public static let annotationsListResponse: [String: Any] = [
        "data": [
            [
                "id": "69d48372-ad81-4c75-9c46-2ce197b4d402",
                "question": "What is your name?",
                "answer": "I am Dify.",
                "hit_count": 0,
                "created_at": 1735625869
            ]
        ],
        "has_more": false,
        "limit": 20,
        "total": 1,
        "page": 1
    ]
    
    nonisolated(unsafe)
    public static let annotationResponse: [String: Any] = [
        "id": "69d48372-ad81-4c75-9c46-2ce197b4d402",
        "question": "What is your name?",
        "answer": "I am Dify.",
        "hit_count": 0,
        "created_at": 1735625869
    ]
    
    nonisolated(unsafe)
    public static let annotationReplyJobResponse: [String: Any] = [
        "job_id": "b15c8f68-1cf4-4877-bf21-ed7cf2011802",
        "job_status": "waiting"
    ]
    
    nonisolated(unsafe)
    public static let annotationReplyJobStatusResponse: [String: Any] = [
        "job_id": "b15c8f68-1cf4-4877-bf21-ed7cf2011802",
        "job_status": "waiting",
        "error_msg": ""
    ]
    
    nonisolated(unsafe)
    public static let applicationInfoResponse: [String: Any] = [
        "name": "My App",
        "description": "This is my app.",
        "tags": [
            "tag1",
            "tag2"
        ],
        "mode": "advanced-chat",
        "author_name": "Dify"
    ]
    
    nonisolated(unsafe)
    public static let applicationParametersResponse: [String: Any] = [
        "opening_statement": "Hello!",
        "suggested_questions_after_answer": [
            "enabled": true
        ],
        "speech_to_text": [
            "enabled": true
        ],
        "text_to_speech": [
            "enabled": true,
            "voice": "sambert-zhinan-v1",
            "language": "zh-Hans",
            "autoPlay": "disabled"
        ],
        "retriever_resource": [
            "enabled": true
        ],
        "annotation_reply": [
            "enabled": true
        ],
        "user_input_form": [
            [
                "paragraph": [
                    "label": "Query",
                    "variable": "query",
                    "required": true,
                    "default": ""
                ]
            ]
        ],
        "file_upload": [
            "image": [
                "enabled": false,
                "number_limits": 3,
                "detail": "high",
                "transfer_methods": [
                    "remote_url",
                    "local_file"
                ]
            ]
        ],
        "system_parameters": [
            "file_size_limit": 15,
            "image_file_size_limit": 10,
            "audio_file_size_limit": 50,
            "video_file_size_limit": 100
        ]
    ]
    
    nonisolated(unsafe)
    public static let applicationMetaResponse: [String: Any] = [
        "tool_icons": [
            "dalle2": "https://cloud.dify.ai/console/api/workspaces/current/tool-provider/builtin/dalle/icon",
            "api_tool": [
                "background": "#252525",
                "content": "😁"
            ]
        ]
    ]
    
    nonisolated(unsafe)
    public static let applicationSiteResponse: [String: Any] = [
        "title": "My App",
        "chat_color_theme": "#ff4a4a",
        "chat_color_theme_inverted": false,
        "icon_type": "emoji",
        "icon": "😄",
        "icon_background": "#FFEAD5",
        "icon_url": NSNull(),
        "description": "This is my app.",
        "copyright": "all rights reserved",
        "privacy_policy": "",
        "custom_disclaimer": "All generated by AI",
        "default_language": "en-US",
        "show_workflow_steps": false,
        "use_icon_as_answer_icon": false
    ]
    
    // MARK: - Completion API Responses
    
    nonisolated(unsafe)
    public static let completionMessageResponse: [String: Any] = [
        "event": "message",
        "message_id": testMessageId,
        "mode": "completion",
        "answer": "Based on your input, here's my response...",
        "metadata": [
            "usage": [
                "prompt_tokens": 1033,
                "prompt_unit_price": "0.001",
                "prompt_price_unit": "0.001",
                "prompt_price": "0.0010330",
                "completion_tokens": 128,
                "completion_unit_price": "0.002",
                "completion_price_unit": "0.001",
                "completion_price": "0.0002560",
                "total_tokens": 1161,
                "total_price": "0.0012890",
                "currency": "USD",
                "latency": 0.7682376249867957
            ]
        ],
        "created_at": 1705407629
    ]
    
    // MARK: - Workflow API Responses
    
    nonisolated(unsafe)
    public static let workflowResponse: [String: Any] = [
        "workflow_run_id": testWorkflowRunId,
        "task_id": "test-task-123",
        "data": [
            "id": testWorkflowRunId,
            "workflow_id": "workflow-456",
            "status": "succeeded",
            "outputs": [
                "result": "Workflow completed successfully"
            ],
            "error": NSNull(),
            "elapsed_time": 1.5,
            "total_tokens": 100,
            "total_steps": 3,
            "created_at": 1726139644,
            "finished_at": 1726139645
        ]
    ]
    
    nonisolated(unsafe)
    public static let workflowLogsResponse: [String: Any] = [
        "page": 1,
        "limit": 20,
        "total": 1,
        "has_more": false,
        "data": [
            [
                "id": "log-123",
                "workflow_run": [
                    "id": testWorkflowRunId,
                    "version": "2024-08-01 12:17:09.771832",
                    "status": "succeeded",
                    "error": NSNull(),
                    "elapsed_time": 1.3588523610014818,
                    "total_tokens": 0,
                    "total_steps": 3,
                    "created_at": 1726139643,
                    "finished_at": 1726139644
                ],
                "created_from": "service-api",
                "created_by_role": "end_user",
                "created_by_account": NSNull(),
                "created_by_end_user": [
                    "id": "7f7d9117-dd9d-441d-8970-87e5e7e687a3",
                    "type": "service_api",
                    "is_anonymous": false,
                    "session_id": "abc-123"
                ],
                "created_at": 1726139644
            ]
        ]
    ]
    
    nonisolated(unsafe)
    public static let workflowRunDetailResponse: [String: Any] = [
        "id": testWorkflowRunId,
        "workflow_id": "workflow-456",
        "status": "succeeded",
        "inputs": [
            "query": "Hello world"
        ],
        "outputs": [
            "text": "Hello! How can I help you today?"
        ],
        "error": NSNull(),
        "total_steps": 3,
        "total_tokens": 150,
        "created_at": 1726139643,
        "finished_at": 1726139644,
        "elapsed_time": 1.3588523610014818
    ]
    
    nonisolated(unsafe)
    public static let baseResponse: [String: Any] = [
        "result": "success"
    ]
    
    // MARK: - File Upload Responses
    
    nonisolated(unsafe)
    public static let fileUploadResponse: [String: Any] = [
        "id": "file-upload-123",
        "name": "test-file.pdf",
        "size": 1024,
        "extension": "pdf",
        "mime_type": "application/pdf",
        "created_by": testUser,
        "created_at": 1726139644
    ]
    
    // MARK: - Application Info Responses
    
    nonisolated(unsafe)
    public static let applicationInfoResponse: [String: Any] = [
        "name": "Test Application",
        "description": "A test application for mock testing",
        "tags": ["test", "mock"],
        "mode": "chat",
        "author_name": "Test Author"
    ]
    
    nonisolated(unsafe)
    public static let applicationParametersResponse: [String: Any] = [
        "opening_statement": "Welcome to our test application!",
        "suggested_questions": [
            "How does this work?",
            "What can you help me with?"
        ],
        "suggested_questions_after_answer": [
            "enabled": true
        ],
        "speech_to_text": [
            "enabled": false
        ],
        "text_to_speech": [
            "enabled": true,
            "voice": "alloy",
            "language": "en-US"
        ],
        "retriever_resource": [
            "enabled": true
        ],
        "annotation_reply": [
            "enabled": false
        ],
        "user_input_form": [],
        "file_upload": [
            "image": [
                "enabled": true,
                "number_limits": 3,
                "detail": "high",
                "transfer_methods": ["remote_url", "local_file"]
            ]
        ],
        "system_parameters": [
            "file_size_limit": 15,
            "image_file_size_limit": 10,
            "audio_file_size_limit": 50,
            "video_file_size_limit": 100
        ]
    ]
    
    nonisolated(unsafe)
    public static let applicationMetaResponse: [String: Any] = [
        "tool_icons": [
            "dalle2": [
                "background": "#252530",
                "content": "🎨"
            ],
            "web_reader": "https://example.com/icon.png"
        ]
    ]
    
    nonisolated(unsafe)
    public static let applicationSiteResponse: [String: Any] = [
        "title": "Test Chat App",
        "chat_color_theme": "indigo",
        "chat_color_theme_inverted": false,
        "icon_type": "emoji",
        "icon": "🤖",
        "icon_background": "#FFEAD5",
        "description": "A test chat application",
        "copyright": "© 2024 Test Company",
        "privacy_policy": "https://example.com/privacy",
        "custom_disclaimer": "All generated by AI",
        "default_language": "en-US",
        "show_workflow_steps": false,
        "use_icon_as_answer_icon": false
    ]
    
    // MARK: - Feedback Responses
    
    nonisolated(unsafe)
    public static let messageFeedbackResponse: [String: Any] = [
        "result": "success"
    ]
    
    nonisolated(unsafe)
    public static let applicationFeedbacksResponse: [String: Any] = [
        "data": [
            [
                "id": "feedback-123",
                "app_id": "app-456",
                "conversation_id": testConversationId,
                "message_id": testMessageId,
                "rating": "like",
                "content": "This response was very helpful!",
                "from_source": "api",
                "from_end_user_id": testUser,
                "from_account_id": NSNull(),
                "created_at": "2024-09-12T10:00:44.000Z",
                "updated_at": "2024-09-12T10:00:44.000Z"
            ]
        ]
    ]
    
    // MARK: - Knowledge Base Responses
    
    nonisolated(unsafe)
    public static let datasetResponse: [String: Any] = [
        "id": testDatasetId,
        "name": "Test Dataset",
        "description": "A test dataset for mock testing",
        "permission": "only_me",
        "data_source_type": "upload_file",
        "indexing_technique": "high_quality",
        "created_by": testUser,
        "created_at": 1726139644,
        "updated_by": testUser,
        "updated_at": 1726139644
    ]
    
    nonisolated(unsafe)
    public static let datasetsResponse: [String: Any] = [
        "data": [datasetResponse],
        "has_more": false,
        "limit": 20,
        "total": 1,
        "page": 1
    ]
    
    nonisolated(unsafe)
    public static let documentResponse: [String: Any] = [
        "id": testDocumentId,
        "position": 1,
        "data_source": [
            "type": "upload_file",
            "info": [
                "upload_file_id": "file-123"
            ]
        ],
        "dataset_process_rule_id": "rule-456",
        "name": "test-document.pdf",
        "created_from": "api",
        "created_by": testUser,
        "created_at": 1726139644,
        "tokens": 500,
        "indexing_status": "completed",
        "error": NSNull(),
        "enabled": true,
        "disabled_at": NSNull(),
        "disabled_by": NSNull(),
        "archived": false,
        "display_status": "available",
        "word_count": 250,
        "hit_count": 0,
        "doc_form": "text_model"
    ]
    
    nonisolated(unsafe)
    public static let documentsResponse: [String: Any] = [
        "data": [documentResponse],
        "has_more": false,
        "limit": 20,
        "total": 1,
        "page": 1
    ]
    
    nonisolated(unsafe)
    public static let createDocumentResponse: [String: Any] = [
        "document": documentResponse,
        "batch": "batch-789"
    ]
    
    // MARK: - Annotation Responses
    
    nonisolated(unsafe)
    public static let annotationListResponse: [String: Any] = [
        "data": [
            [
                "id": "annotation-123",
                "question": "What is artificial intelligence?",
                "answer": "Artificial intelligence is a branch of computer science...",
                "hit_count": 5,
                "created_at": 1726139644
            ]
        ],
        "has_more": false,
        "limit": 20,
        "total": 1,
        "page": 1
    ]
    
    nonisolated(unsafe)
    public static let annotationResponse: [String: Any] = [
        "id": "annotation-123",
        "question": "What is artificial intelligence?",
        "answer": "Artificial intelligence is a branch of computer science...",
        "hit_count": 5,
        "created_at": 1726139644
    ]
    
    nonisolated(unsafe)
    public static let annotationReplySettingsResponse: [String: Any] = [
        "job_id": "job-123",
        "job_status": "pending"
    ]
    
    nonisolated(unsafe)
    public static let annotationJobStatusResponse: [String: Any] = [
        "job_id": "job-123",
        "job_status": "completed"
    ]
    
    // MARK: - Error Responses
    
    nonisolated(unsafe)
    public static let unauthorizedError: [String: Any] = [
        "code": "unauthorized",
        "message": "Invalid API key provided",
        "status": 401
    ]
    
    nonisolated(unsafe)
    public static let rateLimitError: [String: Any] = [
        "code": "rate_limit_exceeded",
        "message": "Rate limit exceeded. Please try again later.",
        "status": 429
    ]
    
    nonisolated(unsafe)
    public static let serverError: [String: Any] = [
        "code": "internal_server_error",
        "message": "An internal server error occurred",
        "status": 500
    ]
    
    nonisolated(unsafe)
    public static let validationError: [String: Any] = [
        "code": "invalid_param",
        "message": "The 'user' parameter is required",
        "status": 400
    ]
    
    // MARK: - Audio Processing Responses
    
    nonisolated(unsafe)
    public static let textToAudioResponse: Data = {
        // Create a simple WAV file header for testing
        var wavData = Data()
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(contentsOf: [0x24, 0x00, 0x00, 0x00]) // ChunkSize
        wavData.append("WAVE".data(using: .ascii)!)
        // fmt subchunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(contentsOf: [0x10, 0x00, 0x00, 0x00]) // Subchunk1Size
        wavData.append(contentsOf: [0x01, 0x00]) // AudioFormat
        wavData.append(contentsOf: [0x01, 0x00]) // NumChannels
        wavData.append(contentsOf: [0x44, 0xAC, 0x00, 0x00]) // SampleRate
        wavData.append(contentsOf: [0x88, 0x58, 0x01, 0x00]) // ByteRate
        wavData.append(contentsOf: [0x02, 0x00]) // BlockAlign
        wavData.append(contentsOf: [0x10, 0x00]) // BitsPerSample
        // data subchunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Subchunk2Size
        return wavData
    }()
    
    // MARK: - Base Responses
    
    nonisolated(unsafe)
    public static let baseSuccessResponse: [String: Any] = [
        "result": "success"
    ]
    
    nonisolated(unsafe)
    public static let baseDeleteResponse: [String: Any] = [:]
    
    // MARK: - Complex Streaming Responses
    
    /// Generate a sequence of streaming events for chat
    nonisolated
    public static func generateChatStreamingEvents() -> [[String: Any]] {
        return [
            [
                "event": "message",
                "message_id": testMessageId,
                "conversation_id": testConversationId,
                "answer": "Hello",
                "created_at": 1726139644
            ],
            [
                "event": "message",
                "message_id": testMessageId,
                "conversation_id": testConversationId,
                "answer": " there!",
                "created_at": 1726139644
            ],
            [
                "event": "message_end",
                "message_id": testMessageId,
                "conversation_id": testConversationId,
                "metadata": [
                    "usage": [
                        "prompt_tokens": 20,
                        "completion_tokens": 12,
                        "total_tokens": 32
                    ]
                ],
                "created_at": 1726139644
            ]
        ]
    }
    
    /// Generate a sequence of streaming events for workflow
    nonisolated
    public static func generateWorkflowStreamingEvents() -> [[String: Any]] {
        return [
            [
                "event": "workflow_started",
                "task_id": "task-123",
                "workflow_run_id": testWorkflowRunId,
                "created_at": 1726139644
            ],
            [
                "event": "node_started",
                "task_id": "task-123",
                "workflow_run_id": testWorkflowRunId,
                "data": [
                    "id": "node-1",
                    "node_id": "start",
                    "node_type": "start",
                    "title": "Start",
                    "index": 1
                ],
                "created_at": 1726139644
            ],
            [
                "event": "node_finished",
                "task_id": "task-123",
                "workflow_run_id": testWorkflowRunId,
                "data": [
                    "id": "node-1",
                    "node_id": "start",
                    "node_type": "start",
                    "title": "Start",
                    "index": 1,
                    "status": "succeeded"
                ],
                "created_at": 1726139644
            ],
            [
                "event": "workflow_finished",
                "task_id": "task-123",
                "workflow_run_id": testWorkflowRunId,
                "data": [
                    "id": testWorkflowRunId,
                    "workflow_id": "workflow-456",
                    "status": "succeeded",
                    "outputs": [
                        "result": "Workflow completed successfully"
                    ],
                    "elapsed_time": 1.5,
                    "total_tokens": 100,
                    "total_steps": 3,
                    "created_at": 1726139644,
                    "finished_at": 1726139645
                ],
                "created_at": 1726139645
            ]
        ]
    }
    
    // MARK: - Convenience Methods
    
    /// Get mock response for a specific endpoint
    nonisolated
    public static func getMockResponse(for endpoint: String) -> [String: Any]? {
        switch endpoint {
        case "chat-messages":
            return chatMessageResponse
        case let endpoint where endpoint.contains("chat-messages") && endpoint.contains("/stop"):
            return baseResponse
        case "messages":
            return conversationMessagesResponse
        case let endpoint where endpoint.contains("messages") && endpoint.contains("/suggested"):
            return suggestedQuestionsResponse
        case let endpoint where endpoint.contains("messages") && endpoint.contains("/feedbacks"):
            return baseResponse
        case "app/feedbacks":
            return chatApplicationFeedbacksResponse
        case let endpoint where endpoint.contains("conversations") && endpoint.contains("/variables"):
            return conversationVariablesResponse
        case let endpoint where endpoint.contains("conversations") && endpoint.contains("/name"):
            return conversationsResponse["data"]?[0] as? [String: Any] ?? [:]
        case "conversations":
            return conversationsResponse
        case "audio-to-text":
            return audioToTextResponse
        case "text-to-audio":
            return Data() // Return empty data for audio
        case "completion-messages":
            return completionMessageResponse
        case "workflows/run":
            return workflowResponse
        case "workflows/logs":
            return workflowLogsResponse
        case let endpoint where endpoint.hasPrefix("workflows/run/") && !endpoint.contains("/stop"):
            return workflowRunDetailResponse
        case let endpoint where endpoint.contains("workflows/tasks") && endpoint.contains("/stop"):
            return baseResponse
        case "files/upload":
            return fileUploadResponse
        case "info":
            return applicationInfoResponse
        case "parameters":
            return applicationParametersResponse
        case "meta":
            return applicationMetaResponse
        case "site":
            return applicationSiteResponse
        case "apps/annotations":
            return annotationsListResponse
        case let endpoint where endpoint.contains("apps/annotations") && !endpoint.contains("apps/annotations/"):
            return annotationsListResponse
        case let endpoint where endpoint.contains("apps/annotations/") && !endpoint.contains("/reply"):
            return annotationResponse
        case let endpoint where endpoint.contains("annotation-reply") && !endpoint.contains("/status"):
            return annotationReplyJobResponse
        case let endpoint where endpoint.contains("annotation-reply") && endpoint.contains("/status"):
            return annotationReplyJobStatusResponse
        case let endpoint where endpoint.contains("feedbacks"):
            return messageFeedbackResponse
        case "datasets":
            return datasetsResponse
        case let endpoint where endpoint.contains("documents") && !endpoint.contains("segments"):
            return documentsResponse
        default:
            return nil
        }
    }
}

// MARK: - Mock Configuration Helper

/// Helper for common mock configurations used across tests
public final class MockConfiguration {
    
    /// Setup standard mocks for all endpoints
    public static func setupStandardMocks() {
        // Chat endpoints
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        
        // Completion endpoints
        MockURLProtocol.registerMock(
            endpoint: "completion-messages",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.completionMessageResponse)
        )
        
        // Workflow endpoints
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.workflowResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "workflows/logs",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.workflowLogsResponse)
        )
        
        // Additional workflow endpoints
        MockURLProtocol.registerMock(
            endpoint: "workflows/run/test-workflow-run-abc",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.workflowRunDetailResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "workflows/tasks/test-task-123/stop",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseResponse)
        )
        
        // File upload endpoints
        MockURLProtocol.registerMock(
            endpoint: "files/upload",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        // Application info endpoints
        MockURLProtocol.registerMock(
            endpoint: "info",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationInfoResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "parameters",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationParametersResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "meta",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationMetaResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "site",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationSiteResponse)
        )
        
        // Feedback endpoints
        MockURLProtocol.registerMock(
            endpoint: "messages/\(MockDataProvider.testMessageId)/feedbacks",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.messageFeedbackResponse)
        )
        
        // Knowledge base endpoints
        MockURLProtocol.registerMock(
            endpoint: "datasets",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.datasetsResponse)
        )
        
        // Annotation endpoints
        MockURLProtocol.registerMock(
            endpoint: "apps/annotations",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationListResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotations/annotation-123",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotation-reply/enable",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationReplySettingsResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotation-reply/disable",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationReplySettingsResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotation-reply/enable/status/job-123",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationJobStatusResponse)
        )
        
        // Text to audio endpoint
        MockURLProtocol.registerMock(
            endpoint: "text-to-audio",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.textToAudioResponse)
        )
        
        // Audio to text endpoint
        MockURLProtocol.registerMock(
            endpoint: "audio-to-text",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        
        // Conversation management endpoints
        MockURLProtocol.registerMock(
            endpoint: "conversations",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.conversationsResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "conversations/\(MockDataProvider.testConversationId)",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseDeleteResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "conversations/\(MockDataProvider.testConversationId)/name",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "conversations/\(MockDataProvider.testConversationId)/variables",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        
        // Application feedbacks endpoint
        MockURLProtocol.registerMock(
            endpoint: "app/feedbacks",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationFeedbacksResponse)
        )
        
        // Knowledge base document endpoints
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.documentsResponse)
        )
        
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.documentResponse)
        )
        
        // Individual dataset endpoint
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.datasetResponse)
        )
    }
    
    /// Setup error scenarios for testing
    public static func setupErrorMocks() {
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 401, message: "Unauthorized")
        )
    }
    
    /// Clear all mocks and reset to clean state
    public static func cleanup() {
        MockURLProtocol.clearAllMocks()
        MockRequestCapture.clearCapturedRequests()
    }
}