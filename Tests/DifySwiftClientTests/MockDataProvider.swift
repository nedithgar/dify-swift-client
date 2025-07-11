import Foundation
@testable import DifySwiftClient

/// Provides mock data for all API endpoints in the Dify SDK
struct MockDataProvider {
    
    // MARK: - Application Info Mock Data
    
    static let mockApplicationInfo = ApplicationInfoResponse(
        name: "Test App",
        description: "A test application",
        tags: ["test", "demo"],
        mode: "chat",
        authorName: "Test Author"
    )
    
    static let mockApplicationParameters = ApplicationParametersResponse(
        openingStatement: "Hello! How can I help you today?",
        suggestedQuestions: ["What is AI?", "How does this work?"],
        suggestedQuestionsAfterAnswer: SuggestedQuestionsConfig(enabled: true),
        speechToText: SpeechToTextConfig(enabled: true),
        retrieverResource: RetrieverResourceConfig(enabled: true),
        annotationReply: AnnotationReplyConfig(enabled: false),
        userInputForm: [
            UserInputFormItem(
                paragraph: FormInput(label: "Query", variable: "query", required: true, defaultValue: ""),
                textInput: nil,
                select: nil
            )
        ],
        fileUpload: FileUploadConfig(
            image: ImageUploadConfig(
                enabled: true,
                numberLimits: 3,
                transferMethods: ["local_file", "remote_url"]
            )
        ),
        systemParameters: SystemParameters(
            fileSizeLimit: 15,
            imageFileSizeLimit: 10,
            audioFileSizeLimit: 50,
            videoFileSizeLimit: 100
        )
    )
    
    static let mockApplicationSite = ApplicationSiteResponse(
        title: "Test App",
        chatColorTheme: "blue",
        chatColorThemeInverted: false,
        iconType: "emoji",
        icon: "🤖",
        iconBackground: "#1C64F2",
        iconUrl: nil,
        description: "A test application",
        copyright: "© 2024 Test Corp",
        privacyPolicy: "https://test.com/privacy",
        customDisclaimer: "This is a test app",
        defaultLanguage: "en",
        showWorkflowSteps: true,
        useIconAsAnswerIcon: false
    )
    
    static let mockApplicationMeta = ApplicationMetaResponse(
        toolIcons: [
            "search": .url("https://example.com/search.png"),
            "calculator": .emoji(ToolIconEmoji(background: "#FF6B6B", content: "🧮"))
        ]
    )
    
    // MARK: - Chat Mock Data
    
    static let mockChatMessage = ChatMessageResponse(
        event: "message",
        taskId: "task-123",
        id: "msg-123",
        messageId: "msg-123",
        conversationId: "conv-123",
        mode: "chat",
        answer: "Hello! How can I help you today?",
        metadata: mockMetadata,
        createdAt: 1640995200
    )
    
    static let mockConversations = ConversationsResponse(
        data: [
            Conversation(
                id: "conv-123",
                name: "Test Conversation",
                inputs: ["query": "Hello"],
                status: "normal",
                introduction: "This is a test conversation",
                createdAt: 1640995200
            )
        ],
        hasMore: false,
        limit: 20
    )
    
    static let mockMessageHistory = MessageHistoryResponse(
        data: [
            ChatMessage(
                id: "msg-123",
                conversationId: "conv-123",
                inputs: ["query": AnyCodable("Hello")],
                query: "Hello",
                messageFiles: [],
                agentThoughts: [],
                answer: "Hi there!",
                createdAt: 1640995200,
                feedback: MessageFeedback(rating: "like"),
                retrieverResources: []
            )
        ],
        hasMore: false,
        limit: 20
    )
    
    static let mockSuggestedQuestions = SuggestedQuestionsResponse(
        result: "success",
        data: ["What is AI?", "How does this work?", "Can you help me?"]
    )
    
    static let mockConversationVariables = ConversationVariablesResponse(
        limit: 20,
        hasMore: false,
        data: [
            ConversationVariable(
                id: "var-123",
                name: "user_name",
                valueType: "string",
                value: "John Doe",
                description: "The user's name",
                createdAt: 1640995200,
                updatedAt: 1640995200
            )
        ]
    )
    
    static let mockAudioToText = AudioToTextResponse(text: "Hello, this is a test transcription")
    
    // MARK: - Completion Mock Data
    
    static let mockCompletionMessage = CompletionMessageResponse(
        event: "message",
        messageId: "msg-123",
        mode: "completion",
        answer: "This is a completion response",
        metadata: mockMetadata,
        createdAt: 1640995200
    )
    
    static let mockFileUpload = FileUploadResponse(
        id: "file-123",
        name: "test.png",
        size: 1024,
        fileExtension: "png",
        mimeType: "image/png",
        createdBy: "user-123",
        createdAt: 1640995200
    )
    
    static let mockMessageFeedback = MessageFeedbackResponse(result: "success")
    
    static let mockApplicationFeedbacks = ApplicationFeedbacksResponse(
        data: [
            ApplicationFeedbacksResponse.FeedbackItem(
                id: "feedback-123",
                appId: "app-123",
                conversationId: "conv-123",
                messageId: "msg-123",
                rating: "like",
                content: "Great response!",
                fromSource: "api",
                fromEndUserId: "user-123",
                fromAccountId: "account-123",
                createdAt: "2024-01-01T00:00:00Z",
                updatedAt: "2024-01-01T00:00:00Z"
            )
        ]
    )
    
    // MARK: - Workflow Mock Data
    
    static let mockWorkflowResponse = WorkflowResponse(
        workflowRunId: "workflow-run-123",
        taskId: "task-123",
        data: mockWorkflowData
    )
    
    static let mockWorkflowData = WorkflowData(
        id: "workflow-123",
        workflowId: "workflow-def-123",
        status: "succeeded",
        outputs: ["result": AnyCodable("Success")],
        error: nil,
        elapsedTime: 1.5,
        totalTokens: 100,
        totalSteps: 3,
        createdAt: 1640995200,
        finishedAt: 1640995201
    )
    
    static let mockWorkflowRunDetail = WorkflowRunDetailResponse(
        id: "workflow-run-123",
        workflowId: "workflow-def-123",
        status: "succeeded",
        inputs: ["query": AnyCodable("Test input")],
        outputs: ["result": AnyCodable("Test output")],
        error: nil,
        totalSteps: 3,
        totalTokens: 100,
        createdAt: 1640995200,
        finishedAt: 1640995201,
        elapsedTime: 1.5
    )
    
    static let mockWorkflowLogs = WorkflowLogsResponse(
        page: 1,
        limit: 20,
        total: 1,
        hasMore: false,
        data: [
            WorkflowLogEntry(
                id: "log-123",
                workflowRun: WorkflowRunInfo(
                    id: "workflow-run-123",
                    version: "1.0",
                    status: "succeeded",
                    error: nil,
                    elapsedTime: 1.5,
                    totalTokens: 100,
                    totalSteps: 3,
                    createdAt: 1640995200,
                    finishedAt: 1640995201
                ),
                createdFrom: "api",
                createdByRole: "end_user",
                createdByAccount: nil,
                createdByEndUser: EndUserInfo(
                    id: "user-123",
                    type: "browser",
                    isAnonymous: false,
                    sessionId: "session-123"
                ),
                createdAt: 1640995200
            )
        ]
    )
    
    static let mockApplicationWebAppSettings = ApplicationWebAppSettingsResponse(
        title: "Test Workflow App",
        iconType: "emoji",
        icon: "🔧",
        iconBackground: "#1C64F2",
        iconUrl: nil,
        description: "A test workflow application",
        copyright: "© 2024 Test Corp",
        privacyPolicy: "https://test.com/privacy",
        customDisclaimer: "This is a test workflow app",
        defaultLanguage: "en",
        showWorkflowSteps: true
    )
    
    // MARK: - Knowledge Base Mock Data
    
    static let mockDatasets = DatasetsResponse(
        data: [
            DatasetResponse(
                id: "dataset-123",
                name: "Test Dataset",
                description: "A test dataset",
                permission: "only_me",
                dataSourceType: "upload_file",
                indexingTechnique: "high_quality",
                appCount: 1,
                documentCount: 5,
                wordCount: 1000,
                createdBy: "user-123",
                createdAt: 1640995200
            )
        ],
        hasMore: false,
        limit: 20,
        total: 1,
        page: 1
    )
    
    static let mockDataset = DatasetResponse(
        id: "dataset-123",
        name: "Test Dataset",
        description: "A test dataset",
        permission: "only_me",
        dataSourceType: "upload_file",
        indexingTechnique: "high_quality",
        appCount: 1,
        documentCount: 5,
        wordCount: 1000,
        createdBy: "user-123",
        createdAt: 1640995200
    )
    
    static let mockDocuments = DocumentsResponse(
        data: [
            DocumentResponse(
                id: "doc-123",
                position: 1,
                name: "test.pdf",
                tokens: 500,
                indexingStatus: "completed",
                createdBy: "user-123",
                createdAt: 1640995200
            )
        ],
        hasMore: false,
        limit: 20,
        total: 1,
        page: 1
    )
    
    static let mockDocument = DocumentResponse(
        id: "doc-123",
        position: 1,
        name: "test.pdf",
        tokens: 500,
        indexingStatus: "completed",
        createdBy: "user-123",
        createdAt: 1640995200
    )
    
    // MARK: - Annotation Mock Data
    
    static let mockAnnotation = AnnotationResponse(
        id: "annotation-123",
        question: "What is AI?",
        answer: "AI stands for Artificial Intelligence",
        hitCount: 5,
        createdAt: 1640995200
    )
    
    static let mockAnnotationsList = AnnotationsListResponse(
        data: [mockAnnotation],
        hasMore: false,
        limit: 20,
        total: 1,
        page: 1
    )
    
    static let mockAnnotationReplyJob = AnnotationReplyJobResponse(
        jobId: "job-123",
        jobStatus: "pending"
    )
    
    static let mockAnnotationReplyJobStatus = AnnotationReplyJobStatusResponse(
        jobId: "job-123",
        jobStatus: "completed",
        errorMsg: ""
    )
    
    // MARK: - Shared Mock Data
    
    static let mockBaseResponse = BaseResponse(result: "success")
    
    static let mockMetadata = Metadata(
        usage: Usage(
            promptTokens: 10,
            completionTokens: 20,
            totalTokens: 30,
            promptUnitPrice: "0.001",
            promptPriceUnit: "USD",
            promptPrice: "0.01",
            completionUnitPrice: "0.002",
            completionPriceUnit: "USD",
            completionPrice: "0.04",
            totalPrice: "0.05",
            currency: "USD",
            latency: 1.5
        ),
        retrieverResources: [
            RetrieverResource(
                position: 1,
                datasetId: "dataset-123",
                datasetName: "Test Dataset",
                documentId: "doc-123",
                documentName: "test.pdf",
                segmentId: "segment-123",
                score: 0.95,
                content: "This is relevant content"
            )
        ]
    )
    
    // MARK: - Streaming Mock Data
    
    static let mockStreamingChatData = [
        "data: {\"event\":\"message\",\"task_id\":\"task-123\",\"message_id\":\"msg-123\",\"answer\":\"Hello\",\"created_at\":1640995200}\n",
        "data: {\"event\":\"message_end\",\"task_id\":\"task-123\",\"message_id\":\"msg-123\",\"metadata\":{\"usage\":{\"prompt_tokens\":10,\"completion_tokens\":20,\"total_tokens\":30}}}\n"
    ]
    
    static let mockStreamingCompletionData = [
        "data: {\"event\":\"message\",\"task_id\":\"task-123\",\"message_id\":\"msg-123\",\"answer\":\"Response\",\"created_at\":1640995200}\n",
        "data: {\"event\":\"message_end\",\"task_id\":\"task-123\",\"message_id\":\"msg-123\",\"metadata\":{\"usage\":{\"prompt_tokens\":10,\"completion_tokens\":20,\"total_tokens\":30}}}\n"
    ]
    
    static let mockStreamingWorkflowData = [
        "data: {\"event\":\"workflow_started\",\"task_id\":\"task-123\",\"workflow_run_id\":\"workflow-run-123\",\"data\":{\"id\":\"workflow-123\",\"workflow_id\":\"workflow-def-123\",\"status\":\"running\",\"elapsed_time\":0.0,\"total_tokens\":0,\"total_steps\":3,\"created_at\":1640995200}}\n",
        "data: {\"event\":\"workflow_finished\",\"task_id\":\"task-123\",\"workflow_run_id\":\"workflow-run-123\",\"data\":{\"id\":\"workflow-123\",\"workflow_id\":\"workflow-def-123\",\"status\":\"succeeded\",\"elapsed_time\":1.5,\"total_tokens\":100,\"total_steps\":3,\"created_at\":1640995200,\"finished_at\":1640995201}}\n"
    ]
    
    // MARK: - Helper Methods
    
    /// Get mock data as JSON Data
    static func jsonData<T: Codable>(_ object: T) -> Data {
        return try! JSONEncoder.difyEncoder.encode(object)
    }
    
    /// Get mock data as JSON string
    static func jsonString<T: Codable>(_ object: T) -> String {
        let data = jsonData(object)
        return String(data: data, encoding: .utf8)!
    }
    
    /// Create mock error response
    static func errorResponse(message: String, code: String? = nil, status: Int? = nil) -> Data {
        let error = DifyError(message: message, code: code, status: status)
        return jsonData(error)
    }
}