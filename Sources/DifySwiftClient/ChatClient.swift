
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
    /// - Returns: A `ChatMessageResponse` object with the chat completion details.
    public func createChatMessage(
        inputs: [String: String],
        query: String,
        user: String,
        conversationId: String? = nil,
        files: [APIFile]? = nil
    ) async throws -> ChatMessageResponse {
        let requestBody = ChatRequestBody(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: .blocking,
            conversationId: conversationId,
            files: files
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
    /// - Returns: An `AsyncThrowingStream` of `StreamingChatMessageResponse` events.
    public func createStreamingChatMessage(
        inputs: [String: String],
        query: String,
        user: String,
        conversationId: String? = nil,
        files: [APIFile]? = nil
    ) async throws -> AsyncThrowingStream<StreamingChatMessageResponse, Error> {
        let requestBody = ChatRequestBody(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: .streaming,
            conversationId: conversationId,
            files: files
        )
        let request = try createURLRequest(method: .POST, endpoint: "/chat-messages", body: requestBody)
        return try await createStreamingResponse(for: request)
    }

    // MARK: - Conversations
    
    /// Retrieves a list of conversations for a user.
    /// - Parameters:
    ///   - user: The user's unique identifier.
    ///   - lastId: An optional ID of the last conversation for pagination.
    ///   - limit: The maximum number of conversations to return.
    ///   - pinned: An optional filter to return only pinned or unpinned conversations.
    /// - Returns: A `ConversationsResponse` object containing the list of conversations.
    public func getConversations(user: String, lastId: String? = nil, limit: Int? = nil, pinned: Bool? = nil) async throws -> ConversationsResponse {
        var params: [String: String] = ["user": user]
        if let lastId { params["last_id"] = lastId }
        if let limit { params["limit"] = String(limit) }
        if let pinned { params["pinned"] = String(pinned) }
        
        let data = try await sendRequest(method: .GET, endpoint: "/conversations", params: params)
        return try decode(data, to: ConversationsResponse.self)
    }
    
    /// Renames a conversation.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to rename.
    ///   - name: The new name for the conversation.
    ///   - user: The user's unique identifier.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func renameConversation(conversationId: String, name: String, user: String) async throws -> BaseResponse {
        let requestBody = ["name": name, "user": user]
        let data = try await sendRequest(method: .POST, endpoint: "/conversations/\(conversationId)/name", body: requestBody)
        return try decode(data, to: BaseResponse.self)
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
        
        private enum CodingKeys: String, CodingKey {
            case inputs, query, user, files
            case responseMode = "response_mode"
            case conversationId = "conversation_id"
        }
    }
}
