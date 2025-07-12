import Foundation

/// Provides mock data for all Dify API endpoints
enum MockDataProvider {
    
    // MARK: - Chat API Mocks
    
    static let chatMessageResponse: [String: Any] = [
        "event": "message",
        "task_id": "900bbd43-dc0b-4383-a372-aa6e6c414227",
        "id": "663c5084-a254-4040-8ad3-51f2a3c1a77c",
        "message_id": "663c5084-a254-4040-8ad3-51f2a3c1a77c",
        "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2",
        "mode": "chat",
        "answer": "Hello! I'm here to help you with any questions you have.",
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
            ],
            "retriever_resources": []
        ],
        "created_at": 1705407629
    ]
    
    static let streamingChatEvents: [String] = [
        #"data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": "Hello", "created_at": 1679586595}"#,
        #"data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": "!", "created_at": 1679586595}"#,
        #"data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " How", "created_at": 1679586595}"#,
        #"data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " can", "created_at": 1679586595}"#,
        #"data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " I", "created_at": 1679586595}"#,
        #"data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " help?", "created_at": 1679586595}"#,
        #"data: {"event": "message_end", "id": "5e52ce04-874b-4d27-9045-b3bc80def685", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "metadata": {"usage": {"prompt_tokens": 1033, "completion_tokens": 135, "total_tokens": 1168}}}"#
    ]
    
    static let conversationList: [String: Any] = [
        "data": [
            [
                "id": "10799fb8-64f7-4296-bbf7-b42bfbe0ae54",
                "name": "New conversation",
                "inputs": [:],
                "status": "normal",
                "created_at": 1679667915,
                "updated_at": 1679667915
            ],
            [
                "id": "hSIhXBhNe8X1d8Et",
                "name": "Another conversation",
                "inputs": ["name": "John"],
                "status": "normal",
                "created_at": 1679667915,
                "updated_at": 1679667915
            ]
        ],
        "has_more": false,
        "limit": 20
    ]
    
    static let messageHistory: [String: Any] = [
        "data": [
            [
                "id": "a076a87f-31e5-48dc-b452-0061adbbc922",
                "conversation_id": "cd78daf6-f9e4-4463-9ff2-54257230a0ce",
                "inputs": [:],
                "query": "Hello",
                "answer": "Hi there! How can I help you today?",
                "message_files": [],
                "feedback": nil,
                "retriever_resources": [],
                "created_at": 1705569239
            ]
        ],
        "has_more": false,
        "limit": 20
    ]
    
    static let suggestedQuestions: [String: Any] = [
        "result": "success",
        "data": [
            "What is machine learning?",
            "How does AI work?",
            "Can you explain neural networks?"
        ]
    ]
    
    // MARK: - Completion API Mocks
    
    static let completionResponse: [String: Any] = [
        "event": "message",
        "task_id": "c3800678-a077-43df-a102-53f23ed20b88",
        "id": "9da23599-e713-473b-982c-4328d4f5c78a",
        "message_id": "9da23599-e713-473b-982c-4328d4f5c78a",
        "mode": "completion",
        "answer": "The capital of France is Paris.",
        "metadata": [
            "usage": [
                "prompt_tokens": 20,
                "completion_tokens": 8,
                "total_tokens": 28
            ]
        ],
        "created_at": 1705407629
    ]
    
    // MARK: - Workflow API Mocks
    
    static let workflowResponse: [String: Any] = [
        "workflow_run_id": "djflajgkldjgd",
        "task_id": "9da23599-e713-473b-982c-4328d4f5c78a",
        "data": [
            "id": "fdlsjfjejkghjda",
            "workflow_id": "fldjaslkfjlsda",
            "status": "succeeded",
            "outputs": [
                "result": "Workflow completed successfully"
            ],
            "error": nil,
            "elapsed_time": 0.875,
            "total_tokens": 3562,
            "total_steps": 8,
            "created_at": 1705407629,
            "finished_at": 1727807631
        ]
    ]
    
    static let streamingWorkflowEvents: [String] = [
        #"data: {"event": "workflow_started", "task_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "workflow_run_id": "5ad498-f0c7-4085-b384-88cbe6290", "data": {"id": "5ad498-f0c7-4085-b384-88cbe6290", "workflow_id": "dfjasklfjdslag", "created_at": 1679586595}}"#,
        #"data: {"event": "node_started", "task_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "workflow_run_id": "5ad498-f0c7-4085-b384-88cbe6290", "data": {"id": "5ad498-f0c7-4085-b384-88cbe6290", "node_id": "start-node", "node_type": "start", "title": "Start", "index": 0, "inputs": {}, "created_at": 1679586595}}"#,
        #"data: {"event": "node_finished", "task_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "workflow_run_id": "5ad498-f0c7-4085-b384-88cbe6290", "data": {"id": "5ad498-f0c7-4085-b384-88cbe6290", "node_id": "start-node", "node_type": "start", "title": "Start", "index": 0, "outputs": {}, "status": "succeeded", "elapsed_time": 0.324, "created_at": 1679586595}}"#,
        #"data: {"event": "workflow_finished", "task_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "workflow_run_id": "5ad498-f0c7-4085-b384-88cbe6290", "data": {"id": "5ad498-f0c7-4085-b384-88cbe6290", "workflow_id": "dfjasklfjdslag", "outputs": {"result": "Success"}, "status": "succeeded", "elapsed_time": 0.324, "total_tokens": 100, "total_steps": 1, "created_at": 1679586595, "finished_at": 1679976595}}"#
    ]
    
    static let workflowLogs: [String: Any] = [
        "page": 1,
        "limit": 20,
        "total": 1,
        "has_more": false,
        "data": [
            [
                "id": "e41b93f1-7ca2-40fd-b3a8-999aeb499cc0",
                "workflow_run": [
                    "id": "c0640fc8-03ef-4481-a96c-8a13b732a36e",
                    "version": "2024-08-01 12:17:09.771832",
                    "status": "succeeded",
                    "error": nil,
                    "elapsed_time": 1.358,
                    "total_tokens": 0,
                    "total_steps": 3,
                    "created_at": 1726139643,
                    "finished_at": 1726139644
                ],
                "created_from": "service-api",
                "created_by_role": "end_user",
                "created_by_account": nil,
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
    
    // MARK: - Knowledge Base API Mocks
    
    static let datasetList: [String: Any] = [
        "data": [
            [
                "id": "b5829712-b2fb-4e47-bc0b-5f6f29c08162",
                "name": "Product Documentation",
                "description": "Company product documentation and guides",
                "document_count": 42,
                "word_count": 125000,
                "created_at": 1695065710,
                "updated_at": 1695065710
            ]
        ],
        "has_more": false,
        "total": 1,
        "page": 1,
        "limit": 20
    ]
    
    static let documentList: [String: Any] = [
        "data": [
            [
                "id": "c8b7e36e-0dca-443e-b5f5-2e865e6cbeb5",
                "position": 1,
                "data_source_type": "upload_file",
                "data_source_info": [:],
                "dataset_process_rule_id": "rule-123",
                "name": "user_guide.pdf",
                "created_from": "api",
                "created_by": "user-123",
                "created_at": 1695312007,
                "tokens": 1234,
                "indexing_status": "completed",
                "error": nil,
                "enabled": true,
                "disabled_at": nil,
                "disabled_by": nil,
                "archived": false
            ]
        ],
        "has_more": false,
        "total": 1,
        "page": 1,
        "limit": 20
    ]
    
    // MARK: - File Upload Mock
    
    static let fileUploadResponse: [String: Any] = [
        "id": "72fa9618-8f89-4a37-9b33-7e1178a24a67",
        "name": "example.png",
        "size": 1024,
        "extension": "png",
        "mime_type": "image/png",
        "created_by": "6ad1ab0a-73ff-4ac1-b9e4-cdb312f71f13",
        "created_at": 1577836800
    ]
    
    // MARK: - Application Info Mocks
    
    static let applicationInfo: [String: Any] = [
        "name": "My Dify App",
        "description": "This is a test application",
        "tags": ["ai", "chatbot"],
        "mode": "chat",
        "author_name": "Dify"
    ]
    
    static let applicationParameters: [String: Any] = [
        "opening_statement": "Hello! How can I help you today?",
        "suggested_questions": [
            "What can you do?",
            "Tell me about yourself"
        ],
        "suggested_questions_after_answer": [
            "enabled": true
        ],
        "speech_to_text": [
            "enabled": true
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
    
    // MARK: - Error Responses
    
    static let notFoundError: [String: Any] = [
        "error": [
            "code": "not_found",
            "message": "The requested resource was not found"
        ]
    ]
    
    static let invalidParamError: [String: Any] = [
        "error": [
            "code": "invalid_param",
            "message": "Invalid parameter provided"
        ]
    ]
    
    static let unauthorizedError: [String: Any] = [
        "error": [
            "code": "unauthorized",
            "message": "Invalid API key"
        ]
    ]
    
    static let rateLimitError: [String: Any] = [
        "error": [
            "code": "rate_limit_exceeded",
            "message": "Rate limit exceeded"
        ]
    ]
    
    // MARK: - Helper Methods
    
    /// Convert a dictionary to JSON data
    static func jsonData(from dict: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: dict, options: [])
    }
    
    /// Create a successful response
    static func successResponse() -> [String: Any] {
        ["result": "success"]
    }
    
    /// Create a stop response
    static func stopResponse() -> [String: Any] {
        ["result": "success"]
    }
}