import Foundation

// MARK: - Response Models

/// Response mode for API requests
public enum ResponseMode: String, Codable, Sendable {
    case blocking
    case streaming
}

/// File transfer method
public enum FileTransferMethod: String, Codable, Sendable {
    case remoteUrl = "remote_url"
    case localFile = "local_file"
}

/// File type
public enum FileType: String, Codable, Sendable {
    case document
    case image
    case audio
    case video
    case custom
}

/// API file representation
public struct APIFile: Codable, Sendable {
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
public struct BaseResponse: Codable, Sendable {
    public let result: String?
}

/// Message feedback response
public struct MessageFeedbackResponse: Codable, Sendable {
    public let result: String
}

/// Stop completion response
public struct StopCompletionResponse: Codable, Sendable {
    public let result: String
}

// MARK: - Application Info Models

/// Application basic information response
public struct ApplicationInfoResponse: Codable, Sendable {
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

/// Application parameters response
public struct ApplicationParametersResponse: Codable, Sendable {
    public let openingStatement: String?
    public let suggestedQuestions: [String]?
    public let suggestedQuestionsAfterAnswer: SuggestedQuestionsConfig?
    public let speechToText: SpeechToTextConfig?
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
        case retrieverResource = "retriever_resource"
        case annotationReply = "annotation_reply"
        case userInputForm = "user_input_form"
        case fileUpload = "file_upload"
        case systemParameters = "system_parameters"
    }
}

public struct SuggestedQuestionsConfig: Codable, Sendable {
    public let enabled: Bool
}

public struct SpeechToTextConfig: Codable, Sendable {
    public let enabled: Bool
}

public struct RetrieverResourceConfig: Codable, Sendable {
    public let enabled: Bool
}

public struct AnnotationReplyConfig: Codable, Sendable {
    public let enabled: Bool
}

public struct UserInputFormItem: Codable, Sendable {
    public let paragraph: FormInput?
    public let textInput: FormInput?
    public let select: Select?

    private enum CodingKeys: String, CodingKey {
        case paragraph
        case textInput = "text-input"
        case select
    }
}

public struct FormInput: Codable, Sendable {
    public let label: String
    public let variable: String
    public let required: Bool
    public let defaultValue: String

    private enum CodingKeys: String, CodingKey {
        case label, variable, required
        case defaultValue = "default"
    }
}

public struct Select: Codable, Sendable {
    public let label: String
    public let variable: String
    public let required: Bool
    public let defaultValue: String
    public let options: [String]

    private enum CodingKeys: String, CodingKey {
        case label, variable, required, options
        case defaultValue = "default"
    }
}

public struct FileUploadConfig: Codable, Sendable {
    /// Configuration for document uploads
    public let document: UploadCategoryConfig?
    /// Configuration for image uploads (backwards compatible alias retained below)
    public let image: UploadCategoryConfig?
    /// Configuration for audio uploads
    public let audio: UploadCategoryConfig?
    /// Configuration for video uploads
    public let video: UploadCategoryConfig?
    /// Configuration for custom uploads
    public let custom: UploadCategoryConfig?
}

/// Generic upload category configuration used for all file categories.
public struct UploadCategoryConfig: Codable, Sendable {
    public let enabled: Bool
    public let numberLimits: Int
    public let transferMethods: [String]

    private enum CodingKeys: String, CodingKey {
        case enabled
        case numberLimits = "number_limits"
        case transferMethods = "transfer_methods"
    }
}

/// Backwards compatibility: previous public type name
public typealias ImageUploadConfig = UploadCategoryConfig

public struct SystemParameters: Codable, Sendable {
    public let fileSizeLimit: Int?
    public let imageFileSizeLimit: Int?
    public let audioFileSizeLimit: Int?
    public let videoFileSizeLimit: Int?

    private enum CodingKeys: String, CodingKey {
        case fileSizeLimit = "file_size_limit"
        case imageFileSizeLimit = "image_file_size_limit"
        case audioFileSizeLimit = "audio_file_size_limit"
        case videoFileSizeLimit = "video_file_size_limit"
    }
}

/// Application site/webapp settings response
public struct ApplicationSiteResponse: Codable, Sendable {
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

/// File upload response
public struct FileUploadResponse: Codable, Sendable {
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

// MARK: - Completion Models

/// Completion message response (for blocking mode)
public struct CompletionMessageResponse: Codable, Sendable {
    public let event: String
    public let messageId: String
    public let mode: String
    public let answer: String
    public let metadata: Metadata?
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case event
        case messageId = "message_id"
        case mode
        case answer
        case metadata
        case createdAt = "created_at"
    }
}

public struct Metadata: Codable, Sendable {
    public let usage: Usage?
    public let retrieverResources: [RetrieverResource]?

    private enum CodingKeys: String, CodingKey {
        case usage
        case retrieverResources = "retriever_resources"
    }
}

public struct Usage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    public let promptUnitPrice: String?
    public let promptPriceUnit: String?
    public let promptPrice: String?
    public let completionUnitPrice: String?
    public let completionPriceUnit: String?
    public let completionPrice: String?
    public let totalPrice: String?
    public let currency: String?
    public let latency: Double?

    private enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case promptUnitPrice = "prompt_unit_price"
        case promptPriceUnit = "prompt_price_unit"
        case promptPrice = "prompt_price"
        case completionUnitPrice = "completion_unit_price"
        case completionPriceUnit = "completion_price_unit"
        case completionPrice = "completion_price"
        case totalPrice = "total_price"
        case currency
        case latency
    }
}

public struct RetrieverResource: Codable, Sendable {
    public let position: Int?
    public let datasetId: String?
    public let datasetName: String?
    public let documentId: String?
    public let documentName: String?
    public let segmentId: String?
    public let score: Double?
    public let content: String?
    
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

// MARK: - Streaming Completion Response Models

public enum StreamingCompletionResponse: Decodable, Sendable {
    case message(MessageStreamEvent)
    case messageEnd(MessageEndStreamEvent)
    case ttsMessage(TTSMessageStreamEvent)
    case ttsMessageEnd(TTSMessageEndStreamEvent)
    case messageReplace(MessageReplaceStreamEvent)
    case error(ErrorStreamEvent)
    case ping

    private enum CodingKeys: String, CodingKey {
        case event
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .event)
        
        switch eventType {
        case "message":
            self = .message(try MessageStreamEvent(from: decoder))
        case "message_end":
            self = .messageEnd(try MessageEndStreamEvent(from: decoder))
        case "tts_message":
            self = .ttsMessage(try TTSMessageStreamEvent(from: decoder))
        case "tts_message_end":
            self = .ttsMessageEnd(try TTSMessageEndStreamEvent(from: decoder))
        case "message_replace":
            self = .messageReplace(try MessageReplaceStreamEvent(from: decoder))
        case "error":
            self = .error(try ErrorStreamEvent(from: decoder))
        case "ping":
            self = .ping
        default:
            throw DecodingError.dataCorruptedError(forKey: .event, in: container, debugDescription: "Unknown event type: \(eventType)")
        }
    }
}

public struct MessageStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let answer: String
    public let createdAt: Int

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case answer
        case createdAt = "created_at"
    }
}

public struct MessageEndStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let metadata: Metadata

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case metadata
    }
}

public struct TTSMessageStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let audio: String // Base64 encoded
    public let createdAt: Int

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case audio
        case createdAt = "created_at"
    }
}

public struct TTSMessageEndStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let audio: String // Empty string
    public let createdAt: Int

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case audio
        case createdAt = "created_at"
    }
}

public struct MessageReplaceStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let conversationId: String
    public let answer: String
    public let createdAt: Int

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case answer
        case createdAt = "created_at"
    }
}

public struct MessageFileStreamEvent: Codable, Sendable {
    public let event: String
    public let id: String
    public let type: String
    public let belongsTo: String
    public let url: String
    public let conversationId: String

    private enum CodingKeys: String, CodingKey {
        case event
        case id
        case type
        case belongsTo = "belongs_to"
        case url
        case conversationId = "conversation_id"
    }
}

public struct ErrorStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let status: Int
    public let code: String
    public let message: String

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case status
        case code
        case message
    }
}

// MARK: - Chat Models

public struct ChatMessageResponse: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let id: String
    public let messageId: String
    public let conversationId: String
    public let mode: String
    public let answer: String
    public let metadata: Metadata?
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case id
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case mode
        case answer
        case metadata
        case createdAt = "created_at"
    }
}

public enum StreamingChatMessageResponse: Decodable, Sendable {
    case message(MessageStreamEvent)
    case messageEnd(MessageEndStreamEvent)
    case agentMessage(AgentMessageStreamEvent)
    case agentThought(AgentThoughtStreamEvent)
    case ttsMessage(TTSMessageStreamEvent)
    case ttsMessageEnd(TTSMessageEndStreamEvent)
    case messageFile(MessageFileStreamEvent)
    case messageReplace(MessageReplaceStreamEvent)
    case workflowStarted(WorkflowStartedEvent)
    case nodeStarted(NodeStartedEvent)
    case nodeFinished(NodeFinishedEvent)
    case workflowFinished(WorkflowFinishedEvent)
    case error(ErrorStreamEvent)
    case ping

    private enum CodingKeys: String, CodingKey {
        case event
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .event)
        
        switch eventType {
        case "message":
            self = .message(try MessageStreamEvent(from: decoder))
        case "message_end":
            self = .messageEnd(try MessageEndStreamEvent(from: decoder))
        case "agent_message":
            self = .agentMessage(try AgentMessageStreamEvent(from: decoder))
        case "agent_thought":
            self = .agentThought(try AgentThoughtStreamEvent(from: decoder))
        case "tts_message":
            self = .ttsMessage(try TTSMessageStreamEvent(from: decoder))
        case "tts_message_end":
            self = .ttsMessageEnd(try TTSMessageEndStreamEvent(from: decoder))
        case "message_file":
            self = .messageFile(try MessageFileStreamEvent(from: decoder))
        case "message_replace":
            self = .messageReplace(try MessageReplaceStreamEvent(from: decoder))
        case "workflow_started":
            self = .workflowStarted(try WorkflowStartedEvent(from: decoder))
        case "node_started":
            self = .nodeStarted(try NodeStartedEvent(from: decoder))
        case "node_finished":
            self = .nodeFinished(try NodeFinishedEvent(from: decoder))
        case "workflow_finished":
            self = .workflowFinished(try WorkflowFinishedEvent(from: decoder))
        case "error":
            self = .error(try ErrorStreamEvent(from: decoder))
        case "ping":
            self = .ping
        default:
            throw DecodingError.dataCorruptedError(forKey: .event, in: container, debugDescription: "Unknown event type: \(eventType)")
        }
    }
}

public struct AgentMessageStreamEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let messageId: String
    public let conversationId: String
    public let answer: String
    public let createdAt: Int

    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case answer
        case createdAt = "created_at"
    }
}

public struct AgentThoughtStreamEvent: Codable, Sendable {
    // Define properties based on API documentation for agent_thought event
    public let event: String
}

public struct ConversationsResponse: Codable, Sendable {
    public let data: [Conversation]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
    }
}

public struct Conversation: Codable, Sendable {
    public let id: String
    public let name: String
    public let inputs: [String: String]?
    public let status: String
    public let introduction: String?
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, name, inputs, status, introduction
        case createdAt = "created_at"
    }
}

// MARK: - Workflow Models

public struct WorkflowResponse: Codable, Sendable {
    public let workflowRunId: String
    public let taskId: String
    public let data: WorkflowData
    
    private enum CodingKeys: String, CodingKey {
        case workflowRunId = "workflow_run_id"
        case taskId = "task_id"
        case data
    }
}

public struct WorkflowData: Codable, Sendable {
    public let id: String
    public let workflowId: String
    public let status: String
    public let outputs: [String: AnyCodable]?
    public let error: String?
    public let elapsedTime: Double
    public let totalTokens: Int
    public let totalSteps: Int
    public let createdAt: Int
    public let finishedAt: Int?
    
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

public enum StreamingWorkflowResponse: Decodable, Sendable {
    case workflowStarted(WorkflowStartedEvent)
    case nodeStarted(NodeStartedEvent)
    case nodeFinished(NodeFinishedEvent)
    case workflowFinished(WorkflowFinishedEvent)
    case textChunk(TextChunkEvent)
    case ttsMessage(TTSMessageStreamEvent)
    case ttsMessageEnd(TTSMessageEndStreamEvent)
    case error(ErrorStreamEvent)
    case ping

    private enum CodingKeys: String, CodingKey {
        case event
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .event)
        
        switch eventType {
        case "workflow_started":
            self = .workflowStarted(try WorkflowStartedEvent(from: decoder))
        case "node_started":
            self = .nodeStarted(try NodeStartedEvent(from: decoder))
        case "node_finished":
            self = .nodeFinished(try NodeFinishedEvent(from: decoder))
        case "workflow_finished":
            self = .workflowFinished(try WorkflowFinishedEvent(from: decoder))
        case "text_chunk":
            self = .textChunk(try TextChunkEvent(from: decoder))
        case "tts_message":
            self = .ttsMessage(try TTSMessageStreamEvent(from: decoder))
        case "tts_message_end":
            self = .ttsMessageEnd(try TTSMessageEndStreamEvent(from: decoder))
        case "error":
            self = .error(try ErrorStreamEvent(from: decoder))
        case "ping":
            self = .ping
        default:
            throw DecodingError.dataCorruptedError(forKey: .event, in: container, debugDescription: "Unknown event type: \(eventType)")
        }
    }
}

public struct WorkflowStartedEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let workflowRunId: String
    public let data: WorkflowData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case workflowRunId = "workflow_run_id"
        case data
    }
}

public struct NodeStartedEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let data: NodeExecutionData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case data
    }
}

public struct NodeFinishedEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let data: NodeExecutionData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case data
    }
}

public struct WorkflowFinishedEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let workflowRunId: String
    public let data: WorkflowData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case workflowRunId = "workflow_run_id"
        case data
    }
}

public struct TextChunkEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let workflowRunId: String
    public let data: TextChunkData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case workflowRunId = "workflow_run_id"
        case data
    }
}

public struct TextChunkData: Codable, Sendable {
    public let text: String
    public let fromVariableSelector: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case text
        case fromVariableSelector = "from_variable_selector"
    }
}

public struct NodeExecutionData: Codable, Sendable {
    public let id: String
    public let nodeId: String
    public let nodeType: String
    public let index: Int
    public let title: String
    public let predecessorNodeId: String?
    public let inputs: [String: AnyCodable]?
    public let processData: [String: AnyCodable]?
    public let outputs: [String: AnyCodable]?
    public let status: String
    public let error: String?
    public let elapsedTime: Double?
    public let executionMetadata: ExecutionMetadata?
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case nodeId = "node_id"
        case nodeType = "node_type"
        case index, title
        case predecessorNodeId = "predecessor_node_id"
        case inputs
        case processData = "process_data"
        case outputs, status, error
        case elapsedTime = "elapsed_time"
        case executionMetadata = "execution_metadata"
        case createdAt = "created_at"
    }
}

public struct ExecutionMetadata: Codable, Sendable {
    public let totalTokens: Int?
    public let totalPrice: Double?
    public let currency: String?
    
    private enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case totalPrice = "total_price"
        case currency
    }
}

// MARK: - Knowledge Base Models

public struct DatasetResponse: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let permission: String
    public let dataSourceType: String
    public let indexingTechnique: String
    public let appCount: Int
    public let documentCount: Int
    public let wordCount: Int
    public let createdBy: String
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, permission
        case dataSourceType = "data_source_type"
        case indexingTechnique = "indexing_technique"
        case appCount = "app_count"
        case documentCount = "document_count"
        case wordCount = "word_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

public struct DatasetsResponse: Codable, Sendable {
    public let data: [DatasetResponse]
    public let hasMore: Bool
    public let limit: Int
    public let total: Int
    public let page: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit, total, page
    }
}

public struct DocumentResponse: Codable, Sendable {
    public let id: String
    public let position: Int
    public let name: String
    public let tokens: Int
    public let indexingStatus: String
    public let createdBy: String
    public let createdAt: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, position, name, tokens
        case indexingStatus = "indexing_status"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

public struct DocumentsResponse: Codable, Sendable {
    public let data: [DocumentResponse]
    public let hasMore: Bool
    public let limit: Int
    public let total: Int
    public let page: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit, total, page
    }
}

public struct ProcessRule: Codable, Sendable {
    public let mode: String
    public let rules: [String: String]?
    
    public init(mode: String, rules: [String : String]? = nil) {
        self.mode = mode
        self.rules = rules
    }
}


// MARK: - Feedback Models

public struct MessageFeedbackRequest: Codable, Sendable {
    public let rating: String? // "like", "dislike", or null
    public let user: String
    public let content: String?

    public init(rating: String?, user: String, content: String? = nil) {
        self.rating = rating
        self.user = user
        self.content = content
    }
}

public struct ApplicationFeedbacksResponse: Codable, Sendable {
    public let data: [FeedbackItem]
    
    public struct FeedbackItem: Codable, Sendable {
        public let id: String
        public let appId: String?
        public let conversationId: String?
        public let messageId: String?
        public let rating: String?
        public let content: String?
        public let fromSource: String?
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

// MARK: - Text to Audio Models

public struct TextToAudioRequest: Codable, Sendable {
    public let messageId: String?
    public let text: String?
    public let user: String

    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case text
        case user
    }

    public init(messageId: String? = nil, text: String? = nil, user: String) {
        self.messageId = messageId
        self.text = text
        self.user = user
    }
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let arrayValue = value as? [Any] {
            try container.encode(arrayValue.map { AnyCodable($0) })
        } else if let dictValue = value as? [String: Any] {
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

// MARK: - Additional Workflow Models (from template_workflow.en.mdx)

/// Workflow run detail response
public struct WorkflowRunDetailResponse: Codable, Sendable {
    public let id: String
    public let workflowId: String
    public let status: String
    public let inputs: [String: AnyCodable]?
    public let outputs: [String: AnyCodable]?
    public let error: String?
    public let totalSteps: Int
    public let totalTokens: Int
    public let createdAt: Int
    public let finishedAt: Int?
    public let elapsedTime: Double
    
    private enum CodingKeys: String, CodingKey {
        case id
        case workflowId = "workflow_id"
        case status
        case inputs
        case outputs
        case error
        case totalSteps = "total_steps"
        case totalTokens = "total_tokens"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
        case elapsedTime = "elapsed_time"
    }
}

/// Workflow logs response
public struct WorkflowLogsResponse: Codable, Sendable {
    public let page: Int
    public let limit: Int
    public let total: Int
    public let hasMore: Bool
    public let data: [WorkflowLogEntry]
    
    private enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case hasMore = "has_more"
        case data
    }
}

/// Workflow log entry
public struct WorkflowLogEntry: Codable, Sendable {
    public let id: String
    public let workflowRun: WorkflowRunInfo
    public let createdFrom: String
    public let createdByRole: String
    public let createdByAccount: String?
    public let createdByEndUser: EndUserInfo
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
}

/// Workflow run info
public struct WorkflowRunInfo: Codable, Sendable {
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

/// End user info
public struct EndUserInfo: Codable, Sendable {
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

/// Application WebApp settings response
public struct ApplicationWebAppSettingsResponse: Codable, Sendable {
    public let title: String
    public let iconType: String
    public let icon: String
    public let iconBackground: String
    public let iconUrl: String?
    public let description: String
    public let copyright: String
    public let privacyPolicy: String
    public let customDisclaimer: String
    public let defaultLanguage: String
    public let showWorkflowSteps: Bool
    
    private enum CodingKeys: String, CodingKey {
        case title
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
    }
}

// MARK: - Chat API Models (from template_chat.en.mdx)

/// Message history response
public struct MessageHistoryResponse: Codable, Sendable {
    public let data: [ChatMessage]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case limit
    }
}

/// Chat message model with full details
public struct ChatMessage: Codable, Sendable {
    public let id: String
    public let conversationId: String
    public let inputs: [String: AnyCodable]
    public let query: String
    public let messageFiles: [MessageFile]
    public let agentThoughts: [AgentThought]
    public let answer: String
    public let createdAt: Int
    public let feedback: MessageFeedback?
    public let retrieverResources: [RetrieverResource]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case inputs
        case query
        case messageFiles = "message_files"
        case agentThoughts = "agent_thoughts"
        case answer
        case createdAt = "created_at"
        case feedback
        case retrieverResources = "retriever_resources"
    }
}

/// Message file details
public struct MessageFile: Codable, Sendable {
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

/// Agent thought details
public struct AgentThought: Codable, Sendable {
    public let id: String
    public let messageId: String
    public let position: Int
    public let thought: String
    public let observation: String
    public let tool: String
    public let toolInput: String
    public let createdAt: Int
    public let messageFiles: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case position
        case thought
        case observation
        case tool
        case toolInput = "tool_input"
        case createdAt = "created_at"
        case messageFiles = "message_files"
    }
}

/// Message feedback details
public struct MessageFeedback: Codable, Sendable {
    public let rating: String
}

/// Suggested questions response
public struct SuggestedQuestionsResponse: Codable, Sendable {
    public let result: String
    public let data: [String]
}

/// Conversation variables response
public struct ConversationVariablesResponse: Codable, Sendable {
    public let limit: Int
    public let hasMore: Bool
    public let data: [ConversationVariable]
    
    private enum CodingKeys: String, CodingKey {
        case limit
        case hasMore = "has_more"
        case data
    }
}

/// Conversation variable details
public struct ConversationVariable: Codable, Sendable {
    public let id: String
    public let name: String
    public let valueType: String
    public let value: String
    public let description: String
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

/// Audio to text response
public struct AudioToTextResponse: Codable, Sendable {
    public let text: String
}

/// Chat Application feedbacks response
public struct ChatApplicationFeedbacksResponse: Codable, Sendable {
    public let data: [ApplicationFeedback]
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
}

/// Application feedback details
public struct ApplicationFeedback: Codable, Sendable {
    public let id: String
    public let appId: String
    public let conversationId: String
    public let messageId: String
    public let rating: String
    public let content: String
    public let fromSource: String
    public let fromEndUserId: String
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

/// Annotation response
public struct AnnotationResponse: Codable, Sendable {
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

/// Annotations list response
public struct AnnotationsListResponse: Codable, Sendable {
    public let data: [AnnotationResponse]
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

/// Annotation reply settings job response
public struct AnnotationReplyJobResponse: Codable, Sendable {
    public let jobId: String
    public let jobStatus: String
    
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case jobStatus = "job_status"
    }
}

/// Annotation reply job status response
public struct AnnotationReplyJobStatusResponse: Codable, Sendable {
    public let jobId: String
    public let jobStatus: String
    public let errorMsg: String
    
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case jobStatus = "job_status"
        case errorMsg = "error_msg"
    }
}

/// Application meta information response
public struct ApplicationMetaResponse: Codable, Sendable {
    public let toolIcons: [String: ToolIcon]
    
    private enum CodingKeys: String, CodingKey {
        case toolIcons = "tool_icons"
    }
}

/// Tool icon representation
public enum ToolIcon: Codable, Sendable {
    case url(String)
    case emoji(ToolIconEmoji)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let url = try? container.decode(String.self) {
            self = .url(url)
        } else {
            self = .emoji(try container.decode(ToolIconEmoji.self))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .url(let url):
            try container.encode(url)
        case .emoji(let emoji):
            try container.encode(emoji)
        }
    }
}

/// Tool icon emoji details
public struct ToolIconEmoji: Codable, Sendable {
    public let background: String
    public let content: String
}