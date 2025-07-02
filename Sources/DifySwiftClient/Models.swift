import Foundation

// MARK: - Response Models

/// Response mode for API requests
public enum ResponseMode: String, Codable {
    case blocking
    case streaming
}

/// File transfer method
public enum FileTransferMethod: String, Codable {
    case remoteUrl = "remote_url"
    case localFile = "local_file"
}

/// File type
public enum FileType: String, Codable {
    case document
    case image
    case audio
    case video
    case custom
}

/// API file representation
public struct APIFile: Codable {
    public let type: FileType
    public let transferMethod: FileTransferMethod
    public let url: String?
    public let uploadFileId: String?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case transferMethod = "transfer_method"
        case url
        case uploadFileId = "upload_file_id"
    }
    
    public init(type: FileType, transferMethod: FileTransferMethod, url: String? = nil, uploadFileId: String? = nil) {
        self.type = type
        self.transferMethod = transferMethod
        self.url = url
        self.uploadFileId = uploadFileId
    }
}

/// Base response structure
public struct BaseResponse: Codable {
    public let result: String?
}

/// Message feedback response
public struct MessageFeedbackResponse: Codable {
    public let result: String
}

/// Application parameters response
public struct ApplicationParametersResponse: Codable {
    public let userInputForm: [UserInputFormItem]
    
    private enum CodingKeys: String, CodingKey {
        case userInputForm = "user_input_form"
    }
}

public struct UserInputFormItem: Codable {
    public let paragraph: Paragraph?
    public let select: Select?
    public let textInput: TextInput?
    
    private enum CodingKeys: String, CodingKey {
        case paragraph
        case select
        case textInput = "text-input"
    }
}

public struct Paragraph: Codable {
    public let label: String
    public let variable: String
    public let required: Bool
    public let defaultValue: String
    
    private enum CodingKeys: String, CodingKey {
        case label
        case variable
        case required
        case defaultValue = "default"
    }
}

public struct Select: Codable {
    public let label: String
    public let variable: String
    public let required: Bool
    public let defaultValue: String
    public let options: [String]
    
    private enum CodingKeys: String, CodingKey {
        case label
        case variable
        case required
        case defaultValue = "default"
        case options
    }
}

public struct TextInput: Codable {
    public let label: String
    public let variable: String
    public let required: Bool
    public let maxLength: Int
    
    private enum CodingKeys: String, CodingKey {
        case label
        case variable
        case required
        case maxLength = "max_length"
    }
}

/// File upload response
public struct FileUploadResponse: Codable {
    public let id: String
    public let name: String
    public let size: Int
    public let fileExtension: String
    public let mimeType: String
    public let createdBy: String
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case size
        case fileExtension = "extension"
        case mimeType = "mime_type"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

/// Text to audio response
public struct TextToAudioResponse: Codable {
    public let taskId: String?
    public let audio: String?
    
    private enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case audio
    }
}

/// Meta response
public struct MetaResponse: Codable {
    public let tool: MetaTool
}

public struct MetaTool: Codable {
    public let labels: [String: String]
}

/// Completion message response
public struct CompletionMessageResponse: Codable {
    public let answer: String
    public let messageId: String
    public let conversationId: String
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case answer
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case createdAt = "created_at"
    }
}

/// Chat message response
public struct ChatMessageResponse: Codable {
    public let answer: String
    public let messageId: String
    public let conversationId: String
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case answer
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case createdAt = "created_at"
    }
}

/// Suggested messages response
public struct SuggestedMessagesResponse: Codable {
    public let data: [String]
}

/// Conversations response
public struct ConversationsResponse: Codable {
    public let data: [Conversation]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
    }
}

public struct Conversation: Codable {
    public let id: String
    public let name: String
    public let inputs: [String: String]
    public let status: String
    public let introduction: String
    public let createdAt: Int
    public let updatedAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case inputs
        case status
        case introduction
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Conversation messages response
public struct ConversationMessagesResponse: Codable {
    public let data: [ConversationMessage]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
    }
}

public struct ConversationMessage: Codable {
    public let id: String
    public let conversationId: String
    public let inputs: [String: String]
    public let query: String
    public let answer: String
    public let messageFiles: [MessageFile]
    public let feedback: MessageFeedback?
    public let retrieverResources: [RetrieverResource]
    public let createdAt: Int
    public let agentThoughts: [AgentThought]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case inputs
        case query
        case answer
        case messageFiles = "message_files"
        case feedback
        case retrieverResources = "retriever_resources"
        case createdAt = "created_at"
        case agentThoughts = "agent_thoughts"
    }
}

public struct MessageFile: Codable {
    public let id: String
    public let type: String
    public let url: String
    public let belongsTo: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case url
        case belongsTo = "belongs_to"
    }
}

public struct MessageFeedback: Codable {
    public let rating: String
}

public struct RetrieverResource: Codable {
    public let position: Int
    public let datasetId: String
    public let datasetName: String
    public let documentId: String
    public let documentName: String
    public let segmentId: String
    public let score: Double
    public let content: String
    
    private enum CodingKeys: String, CodingKey {
        case position
        case datasetId = "dataset_id"
        case datasetName = "dataset_name"
        case documentId = "document_id"
        case documentName = "document_name"
        case segmentId = "segment_id"
        case score
        case content
    }
}

public struct AgentThought: Codable {
    public let id: String
    public let messageId: String
    public let position: Int
    public let thought: String
    public let tool: String
    public let toolInput: String
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case position
        case thought
        case tool
        case toolInput = "tool_input"
        case createdAt = "created_at"
    }
}

/// Workflow response
public struct WorkflowResponse: Codable {
    public let workflowRunId: String
    public let taskId: String
    public let data: WorkflowData
    
    private enum CodingKeys: String, CodingKey {
        case workflowRunId = "workflow_run_id"
        case taskId = "task_id"
        case data
    }
}

public struct WorkflowData: Codable {
    public let id: String
    public let workflowId: String
    public let status: String
    public let outputs: [String: String]
    public let error: String?
    public let elapsedTime: Double
    public let totalTokens: Int
    public let totalSteps: Int
    public let createdAt: Int
    public let finishedAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case workflowId = "workflow_id"
        case status
        case outputs
        case error
        case elapsedTime = "elapsed_time"
        case totalTokens = "total_tokens"
        case totalSteps = "total_steps"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
    }
}

/// Dataset response
public struct DatasetResponse: Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let permission: String
    public let dataSourceType: String
    public let indexingTechnique: String
    public let createdBy: String
    public let createdAt: Int
    public let updatedBy: String
    public let updatedAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case permission
        case dataSourceType = "data_source_type"
        case indexingTechnique = "indexing_technique"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
}

/// Datasets list response
public struct DatasetsResponse: Codable {
    public let data: [DatasetResponse]
    public let hasMore: Bool
    public let limit: Int
    public let total: Int
    public let page: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
        case total
        case page
    }
}

/// Document response
public struct DocumentResponse: Codable {
    public let id: String
    public let position: Int
    public let dataSource: DataSource
    public let datasetProcessRuleId: String
    public let name: String
    public let createdFrom: String
    public let createdBy: String
    public let createdAt: Int
    public let tokens: Int
    public let indexingStatus: String
    public let error: String?
    public let enabled: Bool
    public let disabledAt: Int?
    public let disabledBy: String?
    public let archived: Bool
    public let displayStatus: String
    public let wordCount: Int
    public let hitCount: Int
    public let docForm: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case position
        case dataSource = "data_source"
        case datasetProcessRuleId = "dataset_process_rule_id"
        case name
        case createdFrom = "created_from"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case tokens
        case indexingStatus = "indexing_status"
        case error
        case enabled
        case disabledAt = "disabled_at"
        case disabledBy = "disabled_by"
        case archived
        case displayStatus = "display_status"
        case wordCount = "word_count"
        case hitCount = "hit_count"
        case docForm = "doc_form"
    }
}

public struct DataSource: Codable {
    public let type: String
    public let info: [String: String]
}

/// Create document response
public struct CreateDocumentResponse: Codable {
    public let document: DocumentResponse
    public let batch: String
}

/// Documents list response
public struct DocumentsResponse: Codable {
    public let data: [DocumentResponse]
    public let hasMore: Bool
    public let limit: Int
    public let total: Int
    public let page: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
        case total
        case page
    }
}

/// Segment response
public struct SegmentResponse: Codable {
    public let id: String
    public let position: Int
    public let documentId: String
    public let content: String
    public let answer: String?
    public let wordCount: Int
    public let tokens: Int
    public let keywords: [String]
    public let indexNodeId: String
    public let indexNodeHash: String
    public let hitCount: Int
    public let enabled: Bool
    public let disabledAt: Int?
    public let disabledBy: String?
    public let status: String
    public let createdBy: String
    public let createdAt: Int
    public let indexingAt: Int?
    public let completedAt: Int?
    public let error: String?
    public let stoppedAt: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case position
        case documentId = "document_id"
        case content
        case answer
        case wordCount = "word_count"
        case tokens
        case keywords
        case indexNodeId = "index_node_id"
        case indexNodeHash = "index_node_hash"
        case hitCount = "hit_count"
        case enabled
        case disabledAt = "disabled_at"
        case disabledBy = "disabled_by"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case indexingAt = "indexing_at"
        case completedAt = "completed_at"
        case error
        case stoppedAt = "stopped_at"
    }
}

/// Segments response
public struct SegmentsResponse: Codable {
    public let data: [SegmentResponse]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
    }
}

/// Add segments response
public struct AddSegmentsResponse: Codable {
    public let data: [SegmentResponse]
}

/// Update segment response
public struct UpdateSegmentResponse: Codable {
    public let data: SegmentResponse
}

/// Batch indexing status response
public struct BatchIndexingStatusResponse: Codable {
    public let id: String
    public let indexingStatus: String
    public let processingStartedAt: Int
    public let parsingCompletedAt: Int
    public let cleaningCompletedAt: Int
    public let splittingCompletedAt: Int
    public let completedAt: Int
    public let pausedBy: String?
    public let pausedAt: Int?
    public let canceledBy: String?
    public let canceledAt: Int?
    public let error: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case indexingStatus = "indexing_status"
        case processingStartedAt = "processing_started_at"
        case parsingCompletedAt = "parsing_completed_at"
        case cleaningCompletedAt = "cleaning_completed_at"
        case splittingCompletedAt = "splitting_completed_at"
        case completedAt = "completed_at"
        case pausedBy = "paused_by"
        case pausedAt = "paused_at"
        case canceledBy = "canceled_by"
        case canceledAt = "canceled_at"
        case error
    }
}

// MARK: - Request Models

/// Process rule for documents
public struct ProcessRule: Codable {
    public let mode: String
    public let rules: ProcessRuleRules?
    
    public init(mode: String = "automatic", rules: ProcessRuleRules? = nil) {
        self.mode = mode
        self.rules = rules
    }
}

public struct ProcessRuleRules: Codable {
    public let preProcessingRules: [PreProcessingRule]
    public let segmentation: Segmentation
    
    private enum CodingKeys: String, CodingKey {
        case preProcessingRules = "pre_processing_rules"
        case segmentation
    }
    
    public init(preProcessingRules: [PreProcessingRule], segmentation: Segmentation) {
        self.preProcessingRules = preProcessingRules
        self.segmentation = segmentation
    }
}

public struct PreProcessingRule: Codable {
    public let id: String
    public let enabled: Bool
    
    public init(id: String, enabled: Bool) {
        self.id = id
        self.enabled = enabled
    }
}

public struct Segmentation: Codable {
    public let separator: String
    public let maxTokens: Int
    
    private enum CodingKeys: String, CodingKey {
        case separator
        case maxTokens = "max_tokens"
    }
    
    public init(separator: String, maxTokens: Int) {
        self.separator = separator
        self.maxTokens = maxTokens
    }
}

/// Segment data for adding/updating
public struct SegmentData: Codable {
    public let content: String
    public let answer: String?
    public let keywords: [String]?
    public let enabled: Bool?
    
    public init(content: String, answer: String? = nil, keywords: [String]? = nil, enabled: Bool? = nil) {
        self.content = content
        self.answer = answer
        self.keywords = keywords
        self.enabled = enabled
    }
}

// MARK: - Application Info Models

/// Application basic information response
public struct ApplicationInfoResponse: Codable {
    public let name: String
    public let description: String
    public let tags: [String]
    public let mode: String
    public let authorName: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case tags
        case mode
        case authorName = "author_name"
    }
}

/// Enhanced application parameters response with all API features
public struct EnhancedApplicationParametersResponse: Codable {
    public let openingStatement: String?
    public let suggestedQuestions: [String]?
    public let suggestedQuestionsAfterAnswer: SuggestedQuestionsConfig?
    public let speechToText: SpeechToTextConfig?
    public let textToSpeech: TextToSpeechConfig?
    public let retrieverResource: RetrieverResourceConfig?
    public let annotationReply: AnnotationReplyConfig?
    public let userInputForm: [UserInputFormItem]?
    public let fileUpload: FileUploadConfig?
    public let systemParameters: SystemParameters?
    
    private enum CodingKeys: String, CodingKey {
        case openingStatement = "opening_statement"
        case suggestedQuestions = "suggested_questions"
        case suggestedQuestionsAfterAnswer = "suggested_questions_after_answer"
        case speechToText = "speech_to_text"
        case textToSpeech = "text_to_speech"
        case retrieverResource = "retriever_resource"
        case annotationReply = "annotation_reply"
        case userInputForm = "user_input_form"
        case fileUpload = "file_upload"
        case systemParameters = "system_parameters"
    }
}

public struct SuggestedQuestionsConfig: Codable {
    public let enabled: Bool
}

public struct SpeechToTextConfig: Codable {
    public let enabled: Bool
}

public struct TextToSpeechConfig: Codable {
    public let enabled: Bool
    public let voice: String?
    public let language: String?
    public let autoPlay: String?
    
    private enum CodingKeys: String, CodingKey {
        case enabled
        case voice
        case language
        case autoPlay = "autoPlay"
    }
}

public struct RetrieverResourceConfig: Codable {
    public let enabled: Bool
}

public struct AnnotationReplyConfig: Codable {
    public let enabled: Bool
}

public struct FileUploadConfig: Codable {
    public let image: ImageUploadConfig?
}

public struct ImageUploadConfig: Codable {
    public let enabled: Bool
    public let numberLimits: Int
    public let detail: String?
    public let transferMethods: [String]
    
    private enum CodingKeys: String, CodingKey {
        case enabled
        case numberLimits = "number_limits"
        case detail
        case transferMethods = "transfer_methods"
    }
}

public struct SystemParameters: Codable {
    public let fileSizeLimit: Int
    public let imageFileSizeLimit: Int
    public let audioFileSizeLimit: Int
    public let videoFileSizeLimit: Int
    
    private enum CodingKeys: String, CodingKey {
        case fileSizeLimit = "file_size_limit"
        case imageFileSizeLimit = "image_file_size_limit"
        case audioFileSizeLimit = "audio_file_size_limit"
        case videoFileSizeLimit = "video_file_size_limit"
    }
}

/// Application meta information response
public struct ApplicationMetaResponse: Codable {
    public let toolIcons: [String: ToolIcon]
    
    private enum CodingKeys: String, CodingKey {
        case toolIcons = "tool_icons"
    }
}

public enum ToolIcon: Codable {
    case url(String)
    case icon(ToolIconObject)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let urlString = try? container.decode(String.self) {
            self = .url(urlString)
        } else if let iconObject = try? container.decode(ToolIconObject.self) {
            self = .icon(iconObject)
        } else {
            throw DecodingError.typeMismatch(ToolIcon.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid tool icon format"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .url(let string):
            try container.encode(string)
        case .icon(let toolIconObject):
            try container.encode(toolIconObject)
        }
    }
}

public struct ToolIconObject: Codable {
    public let background: String
    public let content: String
}

/// Application site/webapp settings response
public struct ApplicationSiteResponse: Codable {
    public let title: String?
    public let chatColorTheme: String?
    public let chatColorThemeInverted: Bool?
    public let iconType: String?
    public let icon: String?
    public let iconBackground: String?
    public let iconUrl: String?
    public let description: String?
    public let copyright: String?
    public let privacyPolicy: String?
    public let customDisclaimer: String?
    public let defaultLanguage: String?
    public let showWorkflowSteps: Bool?
    public let useIconAsAnswerIcon: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case chatColorTheme = "chat_color_theme"
        case chatColorThemeInverted = "chat_color_theme_inverted"
        case iconType = "icon_type"
        case icon
        case iconBackground = "icon_background"
        case iconUrl = "icon_url"
        case description
        case copyright
        case privacyPolicy = "privacy_policy"
        case customDisclaimer = "custom_disclaimer"
        case defaultLanguage = "default_language"
        case showWorkflowSteps = "show_workflow_steps"
        case useIconAsAnswerIcon = "use_icon_as_answer_icon"
    }
}

// MARK: - Enhanced Feedback Models

/// Enhanced message feedback request with content support
public struct EnhancedMessageFeedbackRequest: Codable {
    public let rating: String?
    public let user: String
    public let content: String?
    
    public init(rating: String?, user: String, content: String? = nil) {
        self.rating = rating
        self.user = user
        self.content = content
    }
}

/// Application feedbacks list response
public struct ApplicationFeedbacksResponse: Codable {
    public let data: [FeedbackItem]
    
    public struct FeedbackItem: Codable {
        public let id: String
        public let appId: String
        public let conversationId: String?
        public let messageId: String
        public let rating: String
        public let content: String?
        public let fromSource: String
        public let fromEndUserId: String?
        public let fromAccountId: String?
        public let createdAt: String
        public let updatedAt: String
        
        private enum CodingKeys: String, CodingKey {
            case id
            case appId = "app_id"
            case conversationId = "conversation_id"
            case messageId = "message_id"
            case rating
            case content
            case fromSource = "from_source"
            case fromEndUserId = "from_end_user_id"
            case fromAccountId = "from_account_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
}

// MARK: - Conversation Variables Models

/// Conversation variables response
public struct ConversationVariablesResponse: Codable {
    public let limit: Int
    public let hasMore: Bool
    public let data: [ConversationVariable]
    
    private enum CodingKeys: String, CodingKey {
        case limit
        case hasMore = "has_more"
        case data
    }
    
    public struct ConversationVariable: Codable {
        public let id: String
        public let name: String
        public let valueType: String
        public let value: String
        public let description: String?
        public let createdAt: Int
        public let updatedAt: Int
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case valueType = "value_type"
            case value
            case description
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
}

// MARK: - Annotation Models

/// Annotation list response
public struct AnnotationListResponse: Codable {
    public let data: [Annotation]
    public let hasMore: Bool
    public let limit: Int
    public let total: Int
    public let page: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
        case total
        case page
    }
    
    public struct Annotation: Codable {
        public let id: String
        public let question: String
        public let answer: String
        public let hitCount: Int
        public let createdAt: Int
        
        private enum CodingKeys: String, CodingKey {
            case id
            case question
            case answer
            case hitCount = "hit_count"
            case createdAt = "created_at"
        }
    }
}

/// Create/Update annotation request
public struct AnnotationRequest: Codable {
    public let question: String
    public let answer: String
    
    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

/// Annotation reply settings request
public struct AnnotationReplySettingsRequest: Codable {
    public let scoreThreshold: Double?
    public let embeddingProviderName: String?
    public let embeddingModelName: String?
    
    private enum CodingKeys: String, CodingKey {
        case scoreThreshold = "score_threshold"
        case embeddingProviderName = "embedding_provider_name"
        case embeddingModelName = "embedding_model_name"
    }
    
    public init(scoreThreshold: Double? = nil, embeddingProviderName: String? = nil, embeddingModelName: String? = nil) {
        self.scoreThreshold = scoreThreshold
        self.embeddingProviderName = embeddingProviderName
        self.embeddingModelName = embeddingModelName
    }
}

/// Annotation reply settings response
public struct AnnotationReplySettingsResponse: Codable {
    public let jobId: String
    public let jobStatus: String
    
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case jobStatus = "job_status"
    }
}

/// Annotation job status response
public struct AnnotationJobStatusResponse: Codable {
    public let jobId: String
    public let jobStatus: String
    public let errorMsg: String?
    
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case jobStatus = "job_status"
        case errorMsg = "error_msg"
    }
}

// MARK: - Workflow Logs Models

/// Workflow logs response
public struct WorkflowLogsResponse: Codable {
    public let page: Int
    public let limit: Int
    public let total: Int
    public let hasMore: Bool
    public let data: [WorkflowLog]
    
    private enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case hasMore = "has_more"
        case data
    }
    
    public struct WorkflowLog: Codable {
        public let id: String
        public let workflowRun: WorkflowRun
        public let createdFrom: String
        public let createdByRole: String
        public let createdByAccount: String?
        public let createdByEndUser: EndUser
        public let createdAt: Int
        
        private enum CodingKeys: String, CodingKey {
            case id
            case workflowRun = "workflow_run"
            case createdFrom = "created_from"
            case createdByRole = "created_by_role"
            case createdByAccount = "created_by_account"
            case createdByEndUser = "created_by_end_user"
            case createdAt = "created_at"
        }
        
        public struct WorkflowRun: Codable {
            public let id: String
            public let version: String
            public let status: String
            public let error: String?
            public let elapsedTime: Double
            public let totalTokens: Int
            public let totalSteps: Int
            public let createdAt: Int
            public let finishedAt: Int?
            
            private enum CodingKeys: String, CodingKey {
                case id
                case version
                case status
                case error
                case elapsedTime = "elapsed_time"
                case totalTokens = "total_tokens"
                case totalSteps = "total_steps"
                case createdAt = "created_at"
                case finishedAt = "finished_at"
            }
        }
        
        public struct EndUser: Codable {
            public let id: String
            public let type: String
            public let isAnonymous: Bool
            public let sessionId: String
            
            private enum CodingKeys: String, CodingKey {
                case id
                case type
                case isAnonymous = "is_anonymous"
                case sessionId = "session_id"
            }
        }
    }
}

// MARK: - Streaming Event Models

/// Streaming event types for advanced features
public enum StreamingEventType: String, Codable {
    case message
    case messageEnd = "message_end"
    case messageReplace = "message_replace"
    case messageFile = "message_file"
    case agentMessage = "agent_message"
    case agentThought = "agent_thought"
    case ttsMessage = "tts_message"
    case ttsMessageEnd = "tts_message_end"
    case workflowStarted = "workflow_started"
    case nodeStarted = "node_started"
    case nodeFinished = "node_finished"
    case workflowFinished = "workflow_finished"
    case textChunk = "text_chunk"
    case error
    case ping
}

/// Base streaming event protocol
public protocol StreamingEvent: Codable {
    var event: StreamingEventType { get }
    var taskId: String? { get }
    var messageId: String? { get }
    var conversationId: String? { get }
    var createdAt: Int? { get }
}

/// Generic streaming event container
public struct GenericStreamingEvent: Codable {
    public let event: StreamingEventType
    public let taskId: String?
    public let messageId: String?
    public let conversationId: String?
    public let workflowRunId: String?
    public let createdAt: Int?
    public let data: [String: Any]?
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case workflowRunId = "workflow_run_id"
        case createdAt = "created_at"
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(StreamingEventType.self, forKey: .event)
        taskId = try container.decodeIfPresent(String.self, forKey: .taskId)
        messageId = try container.decodeIfPresent(String.self, forKey: .messageId)
        conversationId = try container.decodeIfPresent(String.self, forKey: .conversationId)
        workflowRunId = try container.decodeIfPresent(String.self, forKey: .workflowRunId)
        createdAt = try container.decodeIfPresent(Int.self, forKey: .createdAt)
        
        // Try to decode additional data as a generic dictionary
        if let dataContainer = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .data) {
            var dataDict: [String: Any] = [:]
            for key in dataContainer.allKeys {
                if let value = try? dataContainer.decode(AnyCodable.self, forKey: key) {
                    dataDict[key.stringValue] = value.value
                }
            }
            data = dataDict.isEmpty ? nil : dataDict
        } else {
            data = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(taskId, forKey: .taskId)
        try container.encodeIfPresent(messageId, forKey: .messageId)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
        try container.encodeIfPresent(workflowRunId, forKey: .workflowRunId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        
        if let data = data {
            var dataContainer = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .data)
            for (key, value) in data {
                let codingKey = AnyCodingKey(stringValue: key)!
                try dataContainer.encode(AnyCodable(value), forKey: codingKey)
            }
        }
    }
}

// MARK: - Utility Types for Generic Decoding

/// Helper for encoding/decoding Any values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

/// Dynamic coding key for generic dictionaries
public struct AnyCodingKey: CodingKey {
    public let stringValue: String
    public let intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}