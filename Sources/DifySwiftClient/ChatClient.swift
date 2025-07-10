
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for handling chat-based interactions with the Dify API.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class ChatClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Chat Messages
    
    /// Creates a new chat message.
    /// - Parameters:
    ///   - inputs: A dictionary of input variables for the chat.
    ///   - query: The user's query or message.
    ///   - user: A unique identifier for the end-user.
    ///   - conversationId: An optional ID to continue an existing conversation.
    ///   - files: An optional list of files to include with the message.
    ///   - autoGenerateName: Auto-generate title, default is true.
    /// - Returns: A `ChatMessageResponse` object with the chat completion details.
    public func createChatMessage(
        inputs: [String: String],
        query: String,
        user: String,
        conversationId: String? = nil,
        files: [APIFile]? = nil,
        autoGenerateName: Bool? = nil
    ) async throws -> ChatMessageResponse {
        let requestBody = ChatRequestBody(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: .blocking,
            conversationId: conversationId,
            files: files,
            autoGenerateName: autoGenerateName
        )
        let data = try await sendRequest(method: .POST, endpoint: "/chat-messages", body: requestBody)
        return try decode(data, to: ChatMessageResponse.self)
    }
    
    /// Creates a new chat message and streams the response.
    /// - Parameters:
    ///   - inputs: A dictionary of input variables for the chat.
    ///   - query: The user's query or message.
    ///   - user: A unique identifier for the end-user.
    ///   - conversationId: An optional ID to continue an existing conversation.
    ///   - files: An optional list of files to include with the message.
    ///   - autoGenerateName: Auto-generate title, default is true.
    /// - Returns: An `AsyncThrowingStream` of `StreamingChatMessageResponse` events.
    public func createStreamingChatMessage(
        inputs: [String: String],
        query: String,
        user: String,
        conversationId: String? = nil,
        files: [APIFile]? = nil,
        autoGenerateName: Bool? = nil
    ) async throws -> AsyncThrowingStream<StreamingChatMessageResponse, Error> {
        let requestBody = ChatRequestBody(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: .streaming,
            conversationId: conversationId,
            files: files,
            autoGenerateName: autoGenerateName
        )
        let request = try createURLRequest(method: .POST, endpoint: "/chat-messages", body: requestBody)
        return try await createStreamingResponse(for: request)
    }
    
    /// Stop a chat generation in progress.
    /// - Parameters:
    ///   - taskId: The task ID obtained from streaming response.
    ///   - user: A unique identifier for the end-user.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func stopChatGeneration(taskId: String, user: String) async throws -> BaseResponse {
        let requestBody = ["user": user]
        let data = try await sendRequest(method: .POST, endpoint: "/chat-messages/\(taskId)/stop", body: requestBody)
        return try decode(data, to: BaseResponse.self)
    }
    
    // MARK: - Message History
    
    /// Get conversation history messages.
    /// - Parameters:
    ///   - conversationId: The conversation ID.
    ///   - user: A unique identifier for the end-user.
    ///   - firstId: The ID of the first chat record on the current page.
    ///   - limit: How many chat history messages to return in one request.
    /// - Returns: A `MessageHistoryResponse` containing the messages.
    public func getConversationMessages(
        conversationId: String,
        user: String,
        firstId: String? = nil,
        limit: Int? = nil
    ) async throws -> MessageHistoryResponse {
        var params: [String: String] = [
            "conversation_id": conversationId,
            "user": user
        ]
        if let firstId { params["first_id"] = firstId }
        if let limit { params["limit"] = String(limit) }
        
        let data = try await sendRequest(method: .GET, endpoint: "/messages", params: params)
        return try decode(data, to: MessageHistoryResponse.self)
    }
    
    /// Get suggested questions for a message.
    /// - Parameters:
    ///   - messageId: The message ID.
    ///   - user: A unique identifier for the end-user.
    /// - Returns: A `SuggestedQuestionsResponse` containing suggested questions.
    public func getSuggestedQuestions(messageId: String, user: String) async throws -> SuggestedQuestionsResponse {
        let params = ["user": user]
        let data = try await sendRequest(method: .GET, endpoint: "/messages/\(messageId)/suggested", params: params)
        return try decode(data, to: SuggestedQuestionsResponse.self)
    }
    
    // MARK: - Message Feedback
    
    /// Send feedback for a message.
    /// - Parameters:
    ///   - messageId: The message ID.
    ///   - rating: Upvote as "like", downvote as "dislike", revoke upvote as null.
    ///   - user: A unique identifier for the end-user.
    ///   - content: The specific content of message feedback.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func sendMessageFeedback(
        messageId: String,
        rating: String?,
        user: String,
        content: String? = nil
    ) async throws -> BaseResponse {
        let requestBody = MessageFeedbackRequestBody(rating: rating, user: user, content: content)
        let data = try await sendRequest(method: .POST, endpoint: "/messages/\(messageId)/feedbacks", body: requestBody)
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Get application feedbacks.
    /// - Parameters:
    ///   - page: Page number (optional, default: 1).
    ///   - limit: Records per page (optional, default: 20).
    /// - Returns: A `ChatApplicationFeedbacksResponse` containing feedbacks.
    public func getApplicationFeedbacks(page: Int? = nil, limit: Int? = nil) async throws -> ChatApplicationFeedbacksResponse {
        var params: [String: String] = [:]
        if let page { params["page"] = String(page) }
        if let limit { params["limit"] = String(limit) }
        
        let data = try await sendRequest(method: .GET, endpoint: "/app/feedbacks", params: params)
        return try decode(data, to: ChatApplicationFeedbacksResponse.self)
    }

    // MARK: - Conversation Variables
    
    /// Get variables from a specific conversation.
    /// - Parameters:
    ///   - conversationId: The conversation ID.
    ///   - user: A unique identifier for the end-user.
    ///   - lastId: The ID of the last record on the current page.
    ///   - limit: How many records to return in one request.
    /// - Returns: A `ConversationVariablesResponse` containing variables.
    public func getConversationVariables(
        conversationId: String,
        user: String,
        lastId: String? = nil,
        limit: Int? = nil
    ) async throws -> ConversationVariablesResponse {
        var params: [String: String] = ["user": user]
        if let lastId { params["last_id"] = lastId }
        if let limit { params["limit"] = String(limit) }
        
        let data = try await sendRequest(method: .GET, endpoint: "/conversations/\(conversationId)/variables", params: params)
        return try decode(data, to: ConversationVariablesResponse.self)
    }
    
    // MARK: - Audio Processing
    
    /// Convert audio to text using speech-to-text.
    /// - Parameters:
    ///   - audioFile: The audio file data.
    ///   - user: A unique identifier for the end-user.
    /// - Returns: An `AudioToTextResponse` containing the transcribed text.
    public func audioToText(audioFile: Data, user: String) async throws -> AudioToTextResponse {
        let multipart = MultipartFormData()
        multipart.addTextField(named: "user", value: user)
        multipart.addFileField(named: "file", fileName: "audio.mp3", data: audioFile, mimeType: "audio/mp3")
        
        let data = try await sendMultipartRequest(method: .POST, endpoint: "/audio-to-text", multipart: multipart)
        return try decode(data, to: AudioToTextResponse.self)
    }
    
    /// Convert text to audio using text-to-speech.
    /// - Parameters:
    ///   - messageId: For text messages generated by Dify, pass the message-id directly.
    ///   - text: Speech generated content (used if messageId is not provided).
    ///   - user: A unique identifier for the end-user.
    /// - Returns: Raw audio data.
    public func textToAudio(messageId: String? = nil, text: String? = nil, user: String) async throws -> Data {
        let requestBody = TextToAudioRequestBody(messageId: messageId, text: text, user: user)
        return try await sendRequest(method: .POST, endpoint: "/text-to-audio", body: requestBody)
    }
    
    // MARK: - Application Information
    
    /// Get basic application information.
    /// - Returns: An `ApplicationInfoResponse` with app details.
    public func getApplicationInfo() async throws -> ApplicationInfoResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/info")
        return try decode(data, to: ApplicationInfoResponse.self)
    }
    
    /// Get application parameters information.
    /// - Parameters:
    ///   - user: A unique identifier for the end-user.
    /// - Returns: An `ApplicationParametersResponse` with configuration details.
    public func getApplicationParameters(user: String) async throws -> ApplicationParametersResponse {
        let params = ["user": user]
        let data = try await sendRequest(method: .GET, endpoint: "/parameters", params: params)
        return try decode(data, to: ApplicationParametersResponse.self)
    }
    
    /// Get application meta information (tool icons).
    /// - Returns: An `ApplicationMetaResponse` with tool icon details.
    public func getApplicationMeta() async throws -> ApplicationMetaResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/meta")
        return try decode(data, to: ApplicationMetaResponse.self)
    }
    
    /// Get application WebApp settings.
    /// - Returns: An `ApplicationSiteResponse` with WebApp configuration.
    public func getApplicationWebAppSettings() async throws -> ApplicationSiteResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/site")
        return try decode(data, to: ApplicationSiteResponse.self)
    }
    
    // MARK: - Annotations
    
    /// Get annotation list.
    /// - Parameters:
    ///   - page: Page number.
    ///   - limit: Number of items returned (default 20, range 1-100).
    /// - Returns: An `AnnotationsListResponse` containing annotations.
    public func getAnnotations(page: Int? = nil, limit: Int? = nil) async throws -> AnnotationsListResponse {
        var params: [String: String] = [:]
        if let page { params["page"] = String(page) }
        if let limit { params["limit"] = String(limit) }
        
        let data = try await sendRequest(method: .GET, endpoint: "/apps/annotations", params: params)
        return try decode(data, to: AnnotationsListResponse.self)
    }
    
    /// Create a new annotation.
    /// - Parameters:
    ///   - question: The question.
    ///   - answer: The answer.
    /// - Returns: An `AnnotationResponse` with the created annotation.
    public func createAnnotation(question: String, answer: String) async throws -> AnnotationResponse {
        let requestBody = ["question": question, "answer": answer]
        let data = try await sendRequest(method: .POST, endpoint: "/apps/annotations", body: requestBody)
        return try decode(data, to: AnnotationResponse.self)
    }
    
    /// Update an existing annotation.
    /// - Parameters:
    ///   - annotationId: The annotation ID.
    ///   - question: The updated question.
    ///   - answer: The updated answer.
    /// - Returns: An `AnnotationResponse` with the updated annotation.
    public func updateAnnotation(annotationId: String, question: String, answer: String) async throws -> AnnotationResponse {
        let requestBody = ["question": question, "answer": answer]
        let data = try await sendRequest(method: .PUT, endpoint: "/apps/annotations/\(annotationId)", body: requestBody)
        return try decode(data, to: AnnotationResponse.self)
    }
    
    /// Delete an annotation.
    /// - Parameters:
    ///   - annotationId: The annotation ID.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func deleteAnnotation(annotationId: String) async throws -> BaseResponse {
        let data = try await sendRequest(method: .DELETE, endpoint: "/apps/annotations/\(annotationId)")
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Configure annotation reply settings.
    /// - Parameters:
    ///   - action: Action, can only be "enable" or "disable".
    ///   - embeddingModelProvider: Specified embedding model provider.
    ///   - embeddingModel: Specified embedding model.
    ///   - scoreThreshold: The similarity threshold for matching annotated replies.
    /// - Returns: An `AnnotationReplyJobResponse` with job information.
    public func configureAnnotationReply(
        action: String,
        embeddingModelProvider: String? = nil,
        embeddingModel: String? = nil,
        scoreThreshold: Double? = nil
    ) async throws -> AnnotationReplyJobResponse {
        let requestBody = AnnotationReplyConfigRequestBody(
            embeddingModelProvider: embeddingModelProvider,
            embeddingModel: embeddingModel,
            scoreThreshold: scoreThreshold
        )
        let data = try await sendRequest(method: .POST, endpoint: "/apps/annotation-reply/\(action)", body: requestBody)
        return try decode(data, to: AnnotationReplyJobResponse.self)
    }
    
    /// Query annotation reply settings task status.
    /// - Parameters:
    ///   - action: Action, can only be "enable" or "disable".
    ///   - jobId: Job ID from the configure annotation reply response.
    /// - Returns: An `AnnotationReplyJobStatusResponse` with status information.
    public func getAnnotationReplyJobStatus(action: String, jobId: String) async throws -> AnnotationReplyJobStatusResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/apps/annotation-reply/\(action)/status/\(jobId)")
        return try decode(data, to: AnnotationReplyJobStatusResponse.self)
    }
    
    // MARK: - Conversations
    
    /// Retrieves a list of conversations for a user.
    /// - Parameters:
    ///   - user: The user's unique identifier.
    ///   - lastId: An optional ID of the last conversation for pagination.
    ///   - limit: The maximum number of conversations to return.
    ///   - sortBy: Sorting field (default: -updated_at).
    /// - Returns: A `ConversationsResponse` object containing the list of conversations.
    public func getConversations(user: String, lastId: String? = nil, limit: Int? = nil, sortBy: String? = nil) async throws -> ConversationsResponse {
        var params: [String: String] = ["user": user]
        if let lastId { params["last_id"] = lastId }
        if let limit { params["limit"] = String(limit) }
        if let sortBy { params["sort_by"] = sortBy }
        
        let data = try await sendRequest(method: .GET, endpoint: "/conversations", params: params)
        return try decode(data, to: ConversationsResponse.self)
    }
    
    /// Renames a conversation.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to rename.
    ///   - name: The new name for the conversation (optional if autoGenerate is true).
    ///   - autoGenerate: Automatically generate the title (default: false).
    ///   - user: The user's unique identifier.
    /// - Returns: A `Conversation` object with updated details.
    public func renameConversation(conversationId: String, name: String? = nil, autoGenerate: Bool? = nil, user: String) async throws -> Conversation {
        let requestBody = ConversationRenameRequestBody(name: name, autoGenerate: autoGenerate, user: user)
        let data = try await sendRequest(method: .POST, endpoint: "/conversations/\(conversationId)/name", body: requestBody)
        return try decode(data, to: Conversation.self)
    }
    
    /// Deletes a conversation.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to delete.
    ///   - user: The user's unique identifier.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func deleteConversation(conversationId: String, user: String) async throws -> BaseResponse {
        let requestBody = ["user": user]
        let data = try await sendRequest(method: .DELETE, endpoint: "/conversations/\(conversationId)", body: requestBody)
        return try decode(data, to: BaseResponse.self)
    }
    
    // MARK: - Private Helpers
    
    private struct ChatRequestBody: Codable {
        let inputs: [String: String]
        let query: String
        let user: String
        let responseMode: ResponseMode
        let conversationId: String?
        let files: [APIFile]?
        let autoGenerateName: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case inputs, query, user, files
            case responseMode = "response_mode"
            case conversationId = "conversation_id"
            case autoGenerateName = "auto_generate_name"
        }
    }
    
    private struct MessageFeedbackRequestBody: Codable {
        let rating: String?
        let user: String
        let content: String?
    }
    
    private struct TextToAudioRequestBody: Codable {
        let messageId: String?
        let text: String?
        let user: String
        
        private enum CodingKeys: String, CodingKey {
            case messageId = "message_id"
            case text
            case user
        }
    }
    
    private struct AnnotationReplyConfigRequestBody: Codable {
        let embeddingModelProvider: String?
        let embeddingModel: String?
        let scoreThreshold: Double?
        
        private enum CodingKeys: String, CodingKey {
            case embeddingModelProvider = "embedding_model_provider"
            case embeddingModel = "embedding_model"
            case scoreThreshold = "score_threshold"
        }
    }
    
    private struct ConversationRenameRequestBody: Codable {
        let name: String?
        let autoGenerate: Bool?
        let user: String
        
        private enum CodingKeys: String, CodingKey {
            case name
            case autoGenerate = "auto_generate"
            case user
        }
    }
}
