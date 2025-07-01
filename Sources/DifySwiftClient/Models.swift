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
    case image
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