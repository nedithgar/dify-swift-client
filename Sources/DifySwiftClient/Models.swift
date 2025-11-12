import Foundation

// This file declares the public data models exposed by the Dify Swift Client.
// The goal of the inline documentation is to make the semantics of every model
// and important property clear to SDK consumers while keeping the code surface
// lightweight. All models are intentionally simple value types (struct / enum)
// to facilitate decoding from the Dify HTTP/Streaming APIs.

// MARK: - Response Models

/// Response mode for API requests returned by the server or specified in a request.
///
/// - blocking: The server will perform the entire operation and return a single JSON payload.
/// - streaming: The server will stream a sequence of SSE (Server Sent Event) JSON objects.
public enum ResponseMode: String, Codable, Sendable {
    case blocking
    case streaming
}

/// File transfer method indicating how an accompanying file is provided.
///
/// - remoteUrl: Provide a publicly accessible URL that the server can fetch.
/// - localFile: Provide a previously uploaded file reference (e.g. via file upload endpoint).
public enum FileTransferMethod: String, Codable, Sendable {
    case remoteUrl = "remote_url"
    case localFile = "local_file"
}

/// File type accepted by the API. Used for validation / routing of processing logic.
public enum FileType: String, Codable, Sendable {
    case document
    case image
    case audio
    case video
    case custom
}

/// API file representation used when attaching supplemental user-provided files.
public struct APIFile: Codable, Sendable {
    /// The general file category (e.g. `image`).
    public let type: FileType
    /// How the file is transferred (remote URL vs uploaded file id).
    public let transferMethod: FileTransferMethod
    /// Publicly reachable URL when `transferMethod == .remoteUrl`.
    public let url: String?
    /// Identifier returned from an earlier upload when `transferMethod == .localFile`.
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

/// Base response structure returned by certain simple endpoints carrying only a result status.
public struct BaseResponse: Codable, Sendable {
    public let result: String?
}

/// Message feedback response (e.g. acknowledging a like/dislike submission).
public struct MessageFeedbackResponse: Codable, Sendable {
    public let result: String
}

/// Stop completion response acknowledging a streaming termination request.
public struct StopCompletionResponse: Codable, Sendable {
    public let result: String
}

// MARK: - Application Info Models

/// Application basic information response describing metadata defined in Dify Studio.
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

/// Application parameters response describing runtime / UX behaviour configuration.
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
    /// True if suggested follow-up questions are enabled.
    public let enabled: Bool
}

public struct SpeechToTextConfig: Codable, Sendable {
    /// True if user audio input (STT) is enabled.
    public let enabled: Bool
}

public struct RetrieverResourceConfig: Codable, Sendable {
    /// True if retrieval augmented generation (RAG) resources are enabled.
    public let enabled: Bool
}

public struct AnnotationReplyConfig: Codable, Sendable {
    /// True if automatic annotation reply drafting is enabled.
    public let enabled: Bool
}

public struct UserInputFormItem: Codable, Sendable {
    /// Paragraph long-form input configuration (if present).
    public let paragraph: FormInput?
    /// Single line text input configuration (if present).
    public let textInput: FormInput?
    /// Select (drop‑down) configuration (if present).
    public let select: Select?

    private enum CodingKeys: String, CodingKey {
        case paragraph
        case textInput = "text-input"
        case select
    }
}

public struct FormInput: Codable, Sendable {
    /// Display label presented to the end-user.
    public let label: String
    /// Template variable name accessible in prompts.
    public let variable: String
    /// Whether this field must be supplied.
    public let required: Bool
    /// Default value used when user omits input.
    public let defaultValue: String

    private enum CodingKeys: String, CodingKey {
        case label, variable, required
        case defaultValue = "default"
    }
}

public struct Select: Codable, Sendable {
    /// Display label presented to the end-user.
    public let label: String
    /// Template variable name accessible in prompts.
    public let variable: String
    /// Whether this field must be supplied.
    public let required: Bool
    /// Default selected option.
    public let defaultValue: String
    /// Available options for selection.
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
    /// Whether this file category is allowed.
    public let enabled: Bool
    /// Maximum number of files allowed per request.
    public let numberLimits: Int
    /// Allowed transfer methods (e.g. ["remote_url", "local_file"]).
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
    /// Global file size limit (bytes) for uploads.
    public let fileSizeLimit: Int?
    /// Size limit for image uploads (bytes).
    public let imageFileSizeLimit: Int?
    /// Size limit for audio uploads (bytes).
    public let audioFileSizeLimit: Int?
    /// Size limit for video uploads (bytes).
    public let videoFileSizeLimit: Int?

    private enum CodingKeys: String, CodingKey {
        case fileSizeLimit = "file_size_limit"
        case imageFileSizeLimit = "image_file_size_limit"
        case audioFileSizeLimit = "audio_file_size_limit"
        case videoFileSizeLimit = "video_file_size_limit"
    }
}

/// Application site/webapp settings response controlling UI branding & behaviour.
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

/// File upload response returned after successfully uploading a file.
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

/// Completion message response (for blocking mode) returning the final answer in one payload.
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
    /// Token/price usage information.
    public let usage: Usage?
    /// Retrieval hits used to ground the answer (if RAG enabled).
    public let retrieverResources: [RetrieverResource]?

    private enum CodingKeys: String, CodingKey {
        case usage
        case retrieverResources = "retriever_resources"
    }
}

public struct Usage: Codable, Sendable {
    /// Number of tokens in the prompt.
    public let promptTokens: Int
    /// Number of tokens generated in the completion.
    public let completionTokens: Int
    /// Total tokens (prompt + completion).
    public let totalTokens: Int
    /// Raw unit price for prompt tokens (string to preserve formatting/currency style).
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
    /// Position (rank) of the retrieved segment.
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

/// Streaming completion SSE events emitted in `ResponseMode.streaming`.
public enum StreamingCompletionResponse: Decodable, Sendable {
    /// Partial text delta for the assistant answer.
    case message(MessageStreamEvent)
    /// Finalization event containing usage metadata.
    case messageEnd(MessageEndStreamEvent)
    /// Text-to-Speech audio chunk (Base64) for the answer.
    case ttsMessage(TTSMessageStreamEvent)
    /// Indicates TTS stream ended (empty audio string).
    case ttsMessageEnd(TTSMessageEndStreamEvent)
    /// Replacement of previously emitted content (e.g. when agent rewrites answer).
    case messageReplace(MessageReplaceStreamEvent)
    /// Error describing an abnormal termination.
    case error(ErrorStreamEvent)
    /// Keep-alive heartbeat.
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
    /// Text chunk appended to the cumulative answer.
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
    /// Final usage / retrieval metadata for the completed answer.
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
    /// Base64 encoded audio frame.
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
    /// Always empty; indicates TTS stream completion.
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
    /// Replacement answer text.
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
    /// Human-readable error message.
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

/// Streaming chat SSE events capturing agent reasoning, files, workflow progress and answer content.
public enum StreamingChatMessageResponse: Decodable, Sendable {
    /// Partial answer text.
    case message(MessageStreamEvent)
    /// Final answer & usage metadata.
    case messageEnd(MessageEndStreamEvent)
    /// Agent produced an intermediate user-visible message.
    case agentMessage(AgentMessageStreamEvent)
    /// Agent internal reasoning / tool invocation state.
    case agentThought(AgentThoughtStreamEvent)
    /// Text-to-Speech audio chunk for chat answer.
    case ttsMessage(TTSMessageStreamEvent)
    /// TTS finished marker.
    case ttsMessageEnd(TTSMessageEndStreamEvent)
    /// A file associated with this message became available.
    case messageFile(MessageFileStreamEvent)
    /// Answer replacement (e.g. editing / re-generation).
    case messageReplace(MessageReplaceStreamEvent)
    /// Workflow started (when chat triggers a workflow).
    case workflowStarted(WorkflowStartedEvent)
    /// A workflow node started executing.
    case nodeStarted(NodeStartedEvent)
    /// A workflow node finished executing.
    case nodeFinished(NodeFinishedEvent)
    /// Workflow run finished.
    case workflowFinished(WorkflowFinishedEvent)
    /// Error event.
    case error(ErrorStreamEvent)
    /// Keep-alive heartbeat.
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
    public let event: String
    public let id: String?
    public let taskId: String?
    public let messageId: String?
    public let position: Int?
    /// Agent internal reasoning text (not always exposed to end-user UI by default).
    public let thought: String?
    public let observation: String?
    public let tool: String?
    public let toolInput: String?
    public let createdAt: Int?
    public let messageFiles: [String]? // array of file_id
    public let conversationId: String?

    private enum CodingKeys: String, CodingKey {
        case event
        case id
        case taskId = "task_id"
        case messageId = "message_id"
        case position
        case thought
        case observation
        case tool
        case toolInput = "tool_input"
        case createdAt = "created_at"
        case messageFiles = "message_files"
        case conversationId = "conversation_id"
    }
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
    /// Short introduction / system prompt context.
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

/// Streaming workflow SSE events representing progression of a workflow run.
public enum StreamingWorkflowResponse: Decodable, Sendable {
    /// Workflow execution has begun.
    case workflowStarted(WorkflowStartedEvent)
    /// A node (step) started executing.
    case nodeStarted(NodeStartedEvent)
    /// A node finished executing.
    case nodeFinished(NodeFinishedEvent)
    /// Workflow has finished (success or error contained in data).
    case workflowFinished(WorkflowFinishedEvent)
    /// Incremental text output generated by a running node.
    case textChunk(TextChunkEvent)
    /// TTS audio chunk produced during workflow.
    case ttsMessage(TTSMessageStreamEvent)
    /// TTS finished marker.
    case ttsMessageEnd(TTSMessageEndStreamEvent)
    /// Error event.
    case error(ErrorStreamEvent)
    /// Keep-alive heartbeat.
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
    public let workflowRunId: String?
    public let data: NodeExecutionData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case workflowRunId = "workflow_run_id"
        case data
    }
}

public struct NodeFinishedEvent: Codable, Sendable {
    public let event: String
    public let taskId: String
    public let workflowRunId: String?
    public let data: NodeExecutionData
    
    private enum CodingKeys: String, CodingKey {
        case event
        case taskId = "task_id"
        case workflowRunId = "workflow_run_id"
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

// MARK: Knowledge Base Models (OpenAPI-aligned, non-breaking new types)

/// Advanced Create Dataset request (OpenAPI CreateDatasetRequest)
public struct KBCreateDatasetRequest: Codable, Sendable {
    public let name: String
    public let description: String?
    public let indexingTechnique: String?
    public let permission: String?
    public let provider: String?
    public let externalKnowledgeApiId: String?
    public let externalKnowledgeId: String?
    public let embeddingModel: String?
    public let embeddingModelProvider: String?
    public let retrievalModel: KBRetrievalModel?

    private enum CodingKeys: String, CodingKey {
        case name, description
        case indexingTechnique = "indexing_technique"
        case permission, provider
        case externalKnowledgeApiId = "external_knowledge_api_id"
        case externalKnowledgeId = "external_knowledge_id"
        case embeddingModel = "embedding_model"
        case embeddingModelProvider = "embedding_model_provider"
        case retrievalModel = "retrieval_model"
    }

    public init(name: String,
                description: String? = nil,
                indexingTechnique: String? = nil,
                permission: String? = nil,
                provider: String? = nil,
                externalKnowledgeApiId: String? = nil,
                externalKnowledgeId: String? = nil,
                embeddingModel: String? = nil,
                embeddingModelProvider: String? = nil,
                retrievalModel: KBRetrievalModel? = nil) {
        self.name = name
        self.description = description
        self.indexingTechnique = indexingTechnique
        self.permission = permission
        self.provider = provider
        self.externalKnowledgeApiId = externalKnowledgeApiId
        self.externalKnowledgeId = externalKnowledgeId
        self.embeddingModel = embeddingModel
        self.embeddingModelProvider = embeddingModelProvider
        self.retrievalModel = retrievalModel
    }
}

/// Dataset object (OpenAPI Dataset)
public struct KBDataset: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let provider: String?
    public let permission: String
    public let dataSourceType: String?
    public let indexingTechnique: String?
    public let appCount: Int
    public let documentCount: Int
    public let wordCount: Int
    public let createdBy: String
    public let createdAt: Int
    public let updatedBy: String?
    public let updatedAt: Int?
    public let embeddingModel: String?
    public let embeddingModelProvider: String?
    public let embeddingAvailable: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, provider, permission
        case dataSourceType = "data_source_type"
        case indexingTechnique = "indexing_technique"
        case appCount = "app_count"
        case documentCount = "document_count"
        case wordCount = "word_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
        case embeddingModel = "embedding_model"
        case embeddingModelProvider = "embedding_model_provider"
        case embeddingAvailable = "embedding_available"
    }
}

/// Retrieval Model configuration (OpenAPI RetrievalModel)
public struct KBRetrievalModel: Codable, Sendable {
    public struct RerankingMode: Codable, Sendable {
        public let rerankingProviderName: String?
        public let rerankingModelName: String?

        public init(rerankingProviderName: String? = nil,
                    rerankingModelName: String? = nil) {
            self.rerankingProviderName = rerankingProviderName
            self.rerankingModelName = rerankingModelName
        }

        private enum CodingKeys: String, CodingKey {
            case rerankingProviderName = "reranking_provider_name"
            case rerankingModelName = "reranking_model_name"
        }
    }

    public struct MetadataFilteringConditions: Codable, Sendable {
        public struct Condition: Codable, Sendable {
            public let name: String?
            public let comparisonOperator: String?
            public let value: AnyCodable?

            public init(name: String? = nil,
                        comparisonOperator: String? = nil,
                        value: AnyCodable? = nil) {
                self.name = name
                self.comparisonOperator = comparisonOperator
                self.value = value
            }

            private enum CodingKeys: String, CodingKey {
                case name
                case comparisonOperator = "comparison_operator"
                case value
            }
        }

        public let logicalOperator: String?
        public let conditions: [Condition]?

        public init(logicalOperator: String? = nil,
                    conditions: [Condition]? = nil) {
            self.logicalOperator = logicalOperator
            self.conditions = conditions
        }

        private enum CodingKeys: String, CodingKey {
            case logicalOperator = "logical_operator"
            case conditions
        }
    }

    public let searchMethod: String?
    public let rerankingEnable: Bool?
    public let rerankingMode: RerankingMode?
    public let topK: Int?
    public let scoreThresholdEnabled: Bool?
    public let scoreThreshold: Double?
    public let weights: Double?
    public let metadataFilteringConditions: MetadataFilteringConditions?

    public init(searchMethod: String? = nil,
                rerankingEnable: Bool? = nil,
                rerankingMode: RerankingMode? = nil,
                topK: Int? = nil,
                scoreThresholdEnabled: Bool? = nil,
                scoreThreshold: Double? = nil,
                weights: Double? = nil,
                metadataFilteringConditions: MetadataFilteringConditions? = nil) {
        self.searchMethod = searchMethod
        self.rerankingEnable = rerankingEnable
        self.rerankingMode = rerankingMode
        self.topK = topK
        self.scoreThresholdEnabled = scoreThresholdEnabled
        self.scoreThreshold = scoreThreshold
        self.weights = weights
        self.metadataFilteringConditions = metadataFilteringConditions
    }

    private enum CodingKeys: String, CodingKey {
        case searchMethod = "search_method"
        case rerankingEnable = "reranking_enable"
        case rerankingMode = "reranking_mode"
        case topK = "top_k"
        case scoreThresholdEnabled = "score_threshold_enabled"
        case scoreThreshold = "score_threshold"
        case weights
        case metadataFilteringConditions = "metadata_filtering_conditions"
    }
}

/// Dataset detail (OpenAPI DatasetDetail)
public struct KBDatasetDetail: Codable, Sendable {
    // Base dataset fields
    public let id: String
    public let name: String
    public let description: String?
    public let provider: String?
    public let permission: String
    public let dataSourceType: String?
    public let indexingTechnique: String?
    public let appCount: Int
    public let documentCount: Int
    public let wordCount: Int
    public let createdBy: String
    public let createdAt: Int
    public let updatedBy: String?
    public let updatedAt: Int?
    public let embeddingModel: String?
    public let embeddingModelProvider: String?
    public let embeddingAvailable: Bool?

    // Additional detail fields
    public let retrievalModelDict: KBRetrievalModel?
    public let tags: [AnyCodable]?
    public let docForm: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, provider, permission
        case dataSourceType = "data_source_type"
        case indexingTechnique = "indexing_technique"
        case appCount = "app_count"
        case documentCount = "document_count"
        case wordCount = "word_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
        case embeddingModel = "embedding_model"
        case embeddingModelProvider = "embedding_model_provider"
        case embeddingAvailable = "embedding_available"
        case retrievalModelDict = "retrieval_model_dict"
        case tags
        case docForm = "doc_form"
    }
}

/// Update dataset request (OpenAPI UpdateDatasetRequest)
public struct KBUpdateDatasetRequest: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let indexingTechnique: String?
    public let permission: String?
    public let embeddingModelProvider: String?
    public let embeddingModel: String?
    public let retrievalModel: KBRetrievalModel?
    public let partialMemberList: [String]?

    private enum CodingKeys: String, CodingKey {
        case name, description
        case indexingTechnique = "indexing_technique"
        case permission
        case embeddingModelProvider = "embedding_model_provider"
        case embeddingModel = "embedding_model"
        case retrievalModel = "retrieval_model"
        case partialMemberList = "partial_member_list"
    }

    public init(name: String? = nil,
                description: String? = nil,
                indexingTechnique: String? = nil,
                permission: String? = nil,
                embeddingModelProvider: String? = nil,
                embeddingModel: String? = nil,
                retrievalModel: KBRetrievalModel? = nil,
                partialMemberList: [String]? = nil) {
        self.name = name
        self.description = description
        self.indexingTechnique = indexingTechnique
        self.permission = permission
        self.embeddingModelProvider = embeddingModelProvider
        self.embeddingModel = embeddingModel
        self.retrievalModel = retrievalModel
        self.partialMemberList = partialMemberList
    }
}

/// Flexible process rule for Knowledge endpoints supporting nested structures.
public struct KBProcessRule: Codable, Sendable {
    public let mode: String?
    public let rules: [String: AnyCodable]?

    public init(mode: String? = nil,
                rules: [String: AnyCodable]? = nil) {
        self.mode = mode
        self.rules = rules
    }
}

// MARK: Documents (OpenAPI)

public struct KBCreateDocumentByFileData: Codable, Sendable {
    public let originalDocumentId: String?
    public let indexingTechnique: String?
    public let docForm: String?
    public let docLanguage: String?
    public let processRule: KBProcessRule?
    public let retrievalModel: KBRetrievalModel?
    public let embeddingModel: String?
    public let embeddingModelProvider: String?

    public init(originalDocumentId: String? = nil,
                indexingTechnique: String? = nil,
                docForm: String? = nil,
                docLanguage: String? = nil,
                processRule: KBProcessRule? = nil,
                retrievalModel: KBRetrievalModel? = nil,
                embeddingModel: String? = nil,
                embeddingModelProvider: String? = nil) {
        self.originalDocumentId = originalDocumentId
        self.indexingTechnique = indexingTechnique
        self.docForm = docForm
        self.docLanguage = docLanguage
        self.processRule = processRule
        self.retrievalModel = retrievalModel
        self.embeddingModel = embeddingModel
        self.embeddingModelProvider = embeddingModelProvider
    }

    private enum CodingKeys: String, CodingKey {
        case originalDocumentId = "original_document_id"
        case indexingTechnique = "indexing_technique"
        case docForm = "doc_form"
        case docLanguage = "doc_language"
        case processRule = "process_rule"
        case retrievalModel = "retrieval_model"
        case embeddingModel = "embedding_model"
        case embeddingModelProvider = "embedding_model_provider"
    }
}

public struct KBCreateDocumentByTextRequest: Codable, Sendable {
    public let name: String
    public let text: String
    public let indexingTechnique: String?
    public let docForm: String?
    public let docLanguage: String?
    public let processRule: KBProcessRule?
    public let retrievalModel: KBRetrievalModel?
    public let embeddingModel: String?
    public let embeddingModelProvider: String?

    public init(name: String,
                text: String,
                indexingTechnique: String? = nil,
                docForm: String? = nil,
                docLanguage: String? = nil,
                processRule: KBProcessRule? = nil,
                retrievalModel: KBRetrievalModel? = nil,
                embeddingModel: String? = nil,
                embeddingModelProvider: String? = nil) {
        self.name = name
        self.text = text
        self.indexingTechnique = indexingTechnique
        self.docForm = docForm
        self.docLanguage = docLanguage
        self.processRule = processRule
        self.retrievalModel = retrievalModel
        self.embeddingModel = embeddingModel
        self.embeddingModelProvider = embeddingModelProvider
    }

    private enum CodingKeys: String, CodingKey {
        case name, text
        case indexingTechnique = "indexing_technique"
        case docForm = "doc_form"
        case docLanguage = "doc_language"
        case processRule = "process_rule"
        case retrievalModel = "retrieval_model"
        case embeddingModel = "embedding_model"
        case embeddingModelProvider = "embedding_model_provider"
    }
}

public struct KBUpdateDocumentByTextRequest: Codable, Sendable {
    public let name: String?
    public let text: String?
    public let processRule: KBProcessRule?

    public init(name: String? = nil,
                text: String? = nil,
                processRule: KBProcessRule? = nil) {
        self.name = name
        self.text = text
        self.processRule = processRule
    }

    private enum CodingKeys: String, CodingKey {
        case name, text
        case processRule = "process_rule"
    }
}

public struct KBUpdateDocumentByFileData: Codable, Sendable {
    public let name: String?
    public let processRule: KBProcessRule?

    public init(name: String? = nil,
                processRule: KBProcessRule? = nil) {
        self.name = name
        self.processRule = processRule
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case processRule = "process_rule"
    }
}

/// Document detail (OpenAPI DocumentDetail)
public struct KBDocumentDetail: Codable, Sendable {
    public let id: String
    public let position: Int?
    public let dataSourceType: String?
    public let dataSourceInfo: [String: AnyCodable]?
    public let datasetProcessRule: KBProcessRule?
    public let documentProcessRule: KBDocumentProcessRule?
    public let indexingLatency: Double?
    public let segmentCount: Int?
    public let averageSegmentLength: Int?
    public let docLanguage: String?
    public let name: String?
    public let createdFrom: String?
    public let createdBy: String?
    public let createdAt: Int?
    public let tokens: Int?
    public let indexingStatus: String?
    public let error: String?
    public let enabled: Bool?
    public let disabledAt: Int?
    public let disabledBy: String?
    public let archived: Bool?
    public let displayStatus: String?
    public let wordCount: Int?
    public let hitCount: Int?
    public let docForm: String?

    private enum CodingKeys: String, CodingKey {
        case id, position
        case dataSourceType = "data_source_type"
        case dataSourceInfo = "data_source_info"
        case datasetProcessRule = "dataset_process_rule"
        case documentProcessRule = "document_process_rule"
        case indexingLatency = "indexing_latency"
        case segmentCount = "segment_count"
        case averageSegmentLength = "average_segment_length"
        case docLanguage = "doc_language"
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

/// Wrapper for creation/update responses that include batch id
public struct KBDocumentCreationResponse: Codable, Sendable {
    public let document: DocumentResponse
    public let batch: String
}

public struct KBDocumentProcessRule: Codable, Sendable {
    public let id: String?
    public let datasetId: String?
    public let mode: String?
    public let rules: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case id
        case datasetId = "dataset_id"
        case mode
        case rules
    }
}

public struct KBDocumentIndexingStatus: Codable, Sendable {
    public let id: String
    public let indexingStatus: String
    public let processingStartedAt: Double?
    public let parsingCompletedAt: Double?
    public let cleaningCompletedAt: Double?
    public let splittingCompletedAt: Double?
    public let completedAt: Double?
    public let pausedAt: Double?
    public let error: String?
    public let stoppedAt: Double?
    public let completedSegments: Int?
    public let totalSegments: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case indexingStatus = "indexing_status"
        case processingStartedAt = "processing_started_at"
        case parsingCompletedAt = "parsing_completed_at"
        case cleaningCompletedAt = "cleaning_completed_at"
        case splittingCompletedAt = "splitting_completed_at"
        case completedAt = "completed_at"
        case pausedAt = "paused_at"
        case error
        case stoppedAt = "stopped_at"
        case completedSegments = "completed_segments"
        case totalSegments = "total_segments"
    }
}

public struct KBIndexingStatusResponse: Codable, Sendable {
    public let data: [KBDocumentIndexingStatus]
}

public enum KBDocumentStatusAction: String, Sendable {
    case enable
    case disable
    case archive
    case un_archive
}

// MARK: Segments & Child Chunks

public struct KBSegment: Codable, Sendable {
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
    public let indexingAt: Int
    public let completedAt: Int
    public let error: String?
    public let stoppedAt: Int?

    private enum CodingKeys: String, CodingKey {
        case id, position
        case documentId = "document_id"
        case content, answer
        case wordCount = "word_count"
        case tokens, keywords
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

public struct KBSegmentListResponse: Codable, Sendable {
    public let data: [KBSegment]
    public let docForm: String?

    private enum CodingKeys: String, CodingKey {
        case data
        case docForm = "doc_form"
    }
}

public struct KBSegmentPaginatedResponse: Codable, Sendable {
    public let data: [KBSegment]
    public let docForm: String?
    public let hasMore: Bool?
    public let limit: Int?
    public let total: Int?
    public let page: Int?

    private enum CodingKeys: String, CodingKey {
        case data
        case docForm = "doc_form"
        case hasMore = "has_more"
        case limit, total, page
    }
}

public struct KBSegmentDetailResponse: Codable, Sendable {
    public let data: KBSegment
    public let docForm: String?

    private enum CodingKeys: String, CodingKey {
        case data
        case docForm = "doc_form"
    }
}

public struct KBCreateSegmentsRequest: Codable, Sendable {
    public struct SegmentItem: Codable, Sendable {
        public let content: String
        public let answer: String?
        public let keywords: [String]?

        public init(content: String,
                    answer: String? = nil,
                    keywords: [String]? = nil) {
            self.content = content
            self.answer = answer
            self.keywords = keywords
        }
    }
    public let segments: [SegmentItem]

    public init(segments: [SegmentItem]) {
        self.segments = segments
    }
}

public struct KBUpdateSegmentRequest: Codable, Sendable {
    public struct SegmentFields: Codable, Sendable {
        public let content: String
        public let answer: String?
        public let keywords: [String]?
        public let enabled: Bool?
        public let regenerateChildChunks: Bool?

        public init(content: String,
                    answer: String? = nil,
                    keywords: [String]? = nil,
                    enabled: Bool? = nil,
                    regenerateChildChunks: Bool? = nil) {
            self.content = content
            self.answer = answer
            self.keywords = keywords
            self.enabled = enabled
            self.regenerateChildChunks = regenerateChildChunks
        }

        private enum CodingKeys: String, CodingKey {
            case content, answer, keywords, enabled
            case regenerateChildChunks = "regenerate_child_chunks"
        }
    }
    public let segment: SegmentFields

    public init(segment: SegmentFields) {
        self.segment = segment
    }
}

public struct KBChildChunk: Codable, Sendable {
    public let id: String
    public let segmentId: String
    public let content: String
    public let wordCount: Int
    public let tokens: Int
    public let indexNodeId: String
    public let indexNodeHash: String
    public let status: String
    public let createdBy: String
    public let createdAt: Int
    public let indexingAt: Int
    public let completedAt: Int
    public let error: String?
    public let stoppedAt: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case segmentId = "segment_id"
        case content
        case wordCount = "word_count"
        case tokens
        case indexNodeId = "index_node_id"
        case indexNodeHash = "index_node_hash"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case indexingAt = "indexing_at"
        case completedAt = "completed_at"
        case error
        case stoppedAt = "stopped_at"
    }
}

public struct KBChildChunkResponse: Codable, Sendable {
    public let data: KBChildChunk
}

public struct KBChildChunkListResponse: Codable, Sendable {
    public let data: [KBChildChunk]
    public let total: Int
    public let totalPages: Int
    public let page: Int
    public let limit: Int

    private enum CodingKeys: String, CodingKey {
        case data, total
        case totalPages = "total_pages"
        case page, limit
    }
}

public struct KBCreateChildChunkRequest: Codable, Sendable {
    public let content: String

    public init(content: String) {
        self.content = content
    }
}

public struct KBUpdateChildChunkRequest: Codable, Sendable {
    public let content: String

    public init(content: String) {
        self.content = content
    }
}

// MARK: Retrieve

public struct KBRetrieveRequest: Codable, Sendable {
    public let query: String
    public let retrievalModel: KBRetrievalModel?

    public init(query: String,
                retrievalModel: KBRetrievalModel? = nil) {
        self.query = query
        self.retrievalModel = retrievalModel
    }

    private enum CodingKeys: String, CodingKey {
        case query
        case retrievalModel = "retrieval_model"
    }
}

public struct KBRetrieveResponse: Codable, Sendable {
    public struct Query: Codable, Sendable { public let content: String }
    public let query: Query
    public let records: [KBRetrievedSegment]
}

public struct KBRetrievedSegment: Codable, Sendable {
    public struct SegmentData: Codable, Sendable {
        public struct DocumentRef: Codable, Sendable {
            public let id: String
            public let dataSourceType: String?
            public let name: String

            private enum CodingKeys: String, CodingKey {
                case id
                case dataSourceType = "data_source_type"
                case name
            }
        }

        // mirror KBSegment minimal set used in retrieve
        public let id: String
        public let position: Int?
        public let documentId: String?
        public let content: String
        public let answer: String?
        public let tokens: Int?
        public let keywords: [String]?
        public let document: DocumentRef

        private enum CodingKeys: String, CodingKey {
            case id, position
            case documentId = "document_id"
            case content, answer, tokens, keywords
            case document
        }
    }
    public let segment: SegmentData
    public let score: Double
}

// MARK: Models (Embedding)

public struct KBModel: Codable, Sendable {
    public let model: String
    public let label: [String: String]?
    public let modelType: String?
    public let features: [AnyCodable]?
    public let fetchFrom: String?
    public let modelProperties: KBModelProperties?
    public let deprecated: Bool?
    public let status: String?
    public let loadBalancingEnabled: Bool?

    private enum CodingKeys: String, CodingKey {
        case model
        case label
        case modelType = "model_type"
        case features
        case fetchFrom = "fetch_from"
        case modelProperties = "model_properties"
        case deprecated, status
        case loadBalancingEnabled = "load_balancing_enabled"
    }
}

public struct KBModelProperties: Codable, Sendable { public let contextSize: Int?; private enum CodingKeys: String, CodingKey { case contextSize = "context_size" } }

public struct KBModelProvider: Codable, Sendable {
    public let provider: String
    public let label: [String: String]?
    public let iconSmall: [String: String]?
    public let iconLarge: [String: String]?
    public let status: String?
    public let models: [KBModel]

    private enum CodingKeys: String, CodingKey {
        case provider, label
        case iconSmall = "icon_small"
        case iconLarge = "icon_large"
        case status, models
    }
}

public struct KBModelProvidersResponse: Codable, Sendable { public let data: [KBModelProvider] }

// MARK: Tags

public struct KBTag: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: String?
    public let bindingCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, type
        case bindingCount = "binding_count"
    }
}

public struct KBQueryDatasetTagsResponse: Codable, Sendable {
    public struct TagRef: Codable, Sendable { public let id: String; public let name: String }
    public let data: [TagRef]
    public let total: Int
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

/// Type-erased Codable wrapper allowing heterogeneous JSON structures without
/// needing to predeclare a strongly typed model. Use ONLY when structure is
/// unknowable ahead of time (e.g. workflow node inputs/outputs) as it foregoes
/// most compile-time safety.
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
/// Detailed workflow run response with full inputs / outputs.
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
/// Paginated workflow logs response.
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
/// Individual workflow log entry summarizing a run.
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
/// Lightweight workflow run info used in log listings.
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
/// Identifies the end-user that triggered a workflow/chat (for audit / analytics).
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
/// WebApp specific branding & legal settings (legacy variant of `ApplicationSiteResponse`).
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
/// Paginated message history for a conversation.
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
/// Full chat message including agent reasoning & file attachments.
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
/// Metadata describing a file attached to / produced by a message.
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
/// Agent internal reasoning element linking tool execution results.
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
/// User feedback (like / dislike) applied to a message.
public struct MessageFeedback: Codable, Sendable {
    public let rating: String
}

/// Suggested questions response
/// Suggested follow-up questions returned after an answer.
public struct SuggestedQuestionsResponse: Codable, Sendable {
    public let result: String
    public let data: [String]
}

/// Conversation variables response
/// Paginated response for conversation variables.
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
/// Dynamic variable stored on a conversation scope.
public struct ConversationVariable: Codable, Sendable {
    public let id: String
    public let name: String
    public let valueType: String
    public let value: AnyCodable
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
/// Response for audio transcription containing extracted text.
public struct AudioToTextResponse: Codable, Sendable {
    public let text: String
}

/// Chat Application feedbacks response
/// Paginated list of feedback items across chat application messages.
public struct ChatApplicationFeedbacksResponse: Codable, Sendable {
    public let data: [ApplicationFeedback]
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
}

/// Application feedback details
/// Individual feedback record applied to a chat message.
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
/// Annotation QA pair with knowledge base hit statistics.
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
/// Paginated list of annotation responses.
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
/// Response when initiating an annotation reply generation job.
public struct AnnotationReplyJobResponse: Codable, Sendable {
    public let jobId: String
    public let jobStatus: String
    
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case jobStatus = "job_status"
    }
}

/// Annotation reply job status response
/// Status response for an annotation reply background job.
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
/// Application meta information including tool icon registry.
public struct ApplicationMetaResponse: Codable, Sendable {
    public let toolIcons: [String: ToolIcon]
    
    private enum CodingKeys: String, CodingKey {
        case toolIcons = "tool_icons"
    }
}

/// Tool icon representation
/// Tool icon which might be a direct URL string or an emoji descriptor.
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
/// Emoji-based tool icon specifying background and glyph.
public struct ToolIconEmoji: Codable, Sendable {
    public let background: String
    public let content: String
}
