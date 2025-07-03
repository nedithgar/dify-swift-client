import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for chat-based interactions with Dify
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class ChatClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Chat Methods
    
    /// Create a chat message
    /// - Parameters:
    ///   - inputs: Input parameters for the chat
    ///   - query: User query/message
    ///   - user: User identifier
    ///   - responseMode: Response mode (blocking or streaming)
    ///   - conversationId: Optional conversation ID to continue existing conversation
    ///   - files: Optional files to include with the request
    ///   - autoGenerateName: Auto-generate title, default is true
    /// - Returns: Chat message response
    public func createChatMessage(
        inputs: [String: String],
        query: String,
        user: String,
        responseMode: ResponseMode = .blocking,
        conversationId: String? = nil,
        files: [APIFile]? = nil,
        autoGenerateName: Bool = true
    ) async throws -> ChatMessageResponse {
        struct ChatRequest: Codable {
            let inputs: [String: String]
            let query: String
            let user: String
            let responseMode: ResponseMode
            let conversationId: String?
            let files: [APIFile]?
            let autoGenerateName: Bool
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case query
                case user
                case responseMode = "response_mode"
                case conversationId = "conversation_id"
                case files
                case autoGenerateName = "auto_generate_name"
            }
        }
        
        let request = ChatRequest(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: responseMode,
            conversationId: conversationId,
            files: files,
            autoGenerateName: autoGenerateName
        )
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/chat-messages",
            body: request,
            stream: responseMode == .streaming
        )
        
        return try decode(data, to: ChatMessageResponse.self)
    }
    
    /// Create a streaming chat message
    /// - Parameters:
    ///   - inputs: Input parameters for the chat
    ///   - query: User query/message
    ///   - user: User identifier
    ///   - conversationId: Optional conversation ID to continue existing conversation
    ///   - files: Optional files to include with the request
    ///   - autoGenerateName: Auto-generate title, default is true
    /// - Returns: Async sequence of data chunks
    public func createStreamingChatMessage(
        inputs: [String: String],
        query: String,
        user: String,
        conversationId: String? = nil,
        files: [APIFile]? = nil,
        autoGenerateName: Bool = true
    ) async throws -> StreamingResponse {
        struct ChatRequest: Codable {
            let inputs: [String: String]
            let query: String
            let user: String
            let responseMode: ResponseMode
            let conversationId: String?
            let files: [APIFile]?
            let autoGenerateName: Bool
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case query
                case user
                case responseMode = "response_mode"
                case conversationId = "conversation_id"
                case files
                case autoGenerateName = "auto_generate_name"
            }
        }
        
        let request = ChatRequest(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: .streaming,
            conversationId: conversationId,
            files: files,
            autoGenerateName: autoGenerateName
        )
        
        let url = baseURL.appendingPathComponent("/chat-messages")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.POST.rawValue
        try urlRequest.setJSONBody(request)
        
        return createStreamingResponse(for: urlRequest)
    }
    
    /// Get suggested messages for a given message
    /// - Parameters:
    ///   - messageId: ID of the message to get suggestions for
    ///   - user: User identifier
    /// - Returns: Suggested messages response
    public func getSuggestedMessages(messageId: String, user: String) async throws -> SuggestedMessagesResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/messages/\(messageId)/suggested",
            queryItems: queryItems
        )
        
        return try decode(data, to: SuggestedMessagesResponse.self)
    }
    
    /// Stop a message generation
    /// - Parameters:
    ///   - taskId: Task ID of the message to stop
    ///   - user: User identifier
    /// - Returns: Base response
    public func stopMessage(taskId: String, user: String) async throws -> BaseResponse {
        struct StopRequest: Codable {
            let user: String
        }
        
        let request = StopRequest(user: user)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/chat-messages/\(taskId)/stop",
            body: request
        )
        
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Get list of conversations
    /// - Parameters:
    ///   - user: User identifier
    ///   - lastId: Last conversation ID for pagination
    ///   - limit: Number of conversations to return
    ///   - pinned: Filter by pinned status
    /// - Returns: Conversations response
    public func getConversations(
        user: String,
        lastId: String? = nil,
        limit: Int? = nil,
        pinned: Bool? = nil
    ) async throws -> ConversationsResponse {
        var queryItems = [URLQueryItem(name: "user", value: user)]
        
        if let lastId = lastId {
            queryItems.append(URLQueryItem(name: "last_id", value: lastId))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let pinned = pinned {
            queryItems.append(URLQueryItem(name: "pinned", value: String(pinned)))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/conversations",
            queryItems: queryItems
        )
        
        return try decode(data, to: ConversationsResponse.self)
    }
    
    /// Get messages from a conversation
    /// - Parameters:
    ///   - user: User identifier
    ///   - conversationId: Conversation ID
    ///   - firstId: First message ID for pagination
    ///   - limit: Number of messages to return
    /// - Returns: Conversation messages response
    public func getConversationMessages(
        user: String,
        conversationId: String? = nil,
        firstId: String? = nil,
        limit: Int? = nil
    ) async throws -> ConversationMessagesResponse {
        var queryItems = [URLQueryItem(name: "user", value: user)]
        
        if let conversationId = conversationId {
            queryItems.append(URLQueryItem(name: "conversation_id", value: conversationId))
        }
        if let firstId = firstId {
            queryItems.append(URLQueryItem(name: "first_id", value: firstId))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/messages",
            queryItems: queryItems
        )
        
        return try decode(data, to: ConversationMessagesResponse.self)
    }
    
    /// Rename a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID to rename
    ///   - name: New name for the conversation
    ///   - autoGenerate: Whether to auto-generate the name
    ///   - user: User identifier
    /// - Returns: Base response
    public func renameConversation(
        conversationId: String,
        name: String,
        autoGenerate: Bool,
        user: String
    ) async throws -> BaseResponse {
        struct RenameRequest: Codable {
            let name: String
            let autoGenerate: Bool
            let user: String
            
            private enum CodingKeys: String, CodingKey {
                case name
                case autoGenerate = "auto_generate"
                case user
            }
        }
        
        let request = RenameRequest(name: name, autoGenerate: autoGenerate, user: user)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/conversations/\(conversationId)/name",
            body: request
        )
        
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Delete a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID to delete
    ///   - user: User identifier
    /// - Returns: Base response
    public func deleteConversation(conversationId: String, user: String) async throws -> BaseResponse {
        struct DeleteRequest: Codable {
            let user: String
        }
        
        let request = DeleteRequest(user: user)
        let data = try await sendRequest(
            method: .DELETE,
            endpoint: "/conversations/\(conversationId)",
            body: request
        )
        
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Convert audio to text
    /// - Parameters:
    ///   - audioData: Audio file data
    ///   - filename: Name of the audio file
    ///   - user: User identifier
    /// - Returns: Audio to text response (same as chat response)
    public func audioToText(audioData: Data, filename: String, user: String) async throws -> ChatMessageResponse {
        let data = try await sendRequestWithFiles(
            method: .POST,
            endpoint: "/audio-to-text",
            parameters: ["user": user],
            files: [(key: "audio_file", filename: filename, data: audioData, mimeType: "audio/mpeg")]
        )
        
        return try decode(data, to: ChatMessageResponse.self)
    }
    
    /// Get conversation variables
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - user: User identifier
    ///   - lastId: Optional last ID for pagination
    ///   - limit: Number of records to return
    /// - Returns: Conversation variables response
    public func getConversationVariables(
        conversationId: String,
        user: String,
        lastId: String? = nil,
        limit: Int = 20
    ) async throws -> ConversationVariablesResponse {
        var queryItems = [URLQueryItem(name: "user", value: user)]
        if let lastId = lastId {
            queryItems.append(URLQueryItem(name: "last_id", value: lastId))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/conversations/\(conversationId)/variables",
            queryItems: queryItems
        )
        
        return try decode(data, to: ConversationVariablesResponse.self)
    }
}