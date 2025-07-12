
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for completion-based interactions with the Dify API.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class CompletionClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Completion Messages
    
    /// Sends a request to the text generation application.
    /// - Parameters:
    ///   - inputs: A dictionary of variable values defined by the App. Requires at least one key/value pair, e.g., `["query": "Your query"]`.
    ///   - user: A unique identifier for the end-user.
    ///   - files: An optional list of files to include, for models that support Vision capabilities.
    /// - Returns: A `CompletionMessageResponse` object containing the complete result.
    public func createCompletionMessage(
        inputs: [String: String],
        user: String,
        files: [APIFile]? = nil
    ) async throws -> CompletionMessageResponse {
        struct RequestBody: Codable {
            let inputs: [String: String]
            let responseMode: ResponseMode = .blocking
            let user: String
            let files: [APIFile]?

            private enum CodingKeys: String, CodingKey {
                case inputs, user, files
                case responseMode = "response_mode"
            }
        }
        
        let request = RequestBody(inputs: inputs, user: user, files: files)
        let data = try await sendRequest(method: .POST, endpoint: "/completion-messages", body: request)
        return try decode(data, to: CompletionMessageResponse.self)
    }
    
    /// Sends a request to the text generation application and receives the response as a stream.
    /// - Parameters:
    ///   - inputs: A dictionary of variable values defined by the App. Requires at least one key/value pair, e.g., `["query": "Your query"]`.
    ///   - user: A unique identifier for the end-user.
    ///   - files: An optional list of files to include, for models that support Vision capabilities.
    /// - Returns: An `AsyncThrowingStream` of `StreamingCompletionResponse` events.
    public func createStreamingCompletionMessage(
        inputs: [String: String],
        user: String,
        files: [APIFile]? = nil
    ) async throws -> AsyncThrowingStream<StreamingCompletionResponse, Error> {
        struct RequestBody: Codable {
            let inputs: [String: String]
            let responseMode: ResponseMode = .streaming
            let user: String
            let files: [APIFile]?

            private enum CodingKeys: String, CodingKey {
                case inputs, user, files
                case responseMode = "response_mode"
            }
        }
        
        let request = RequestBody(inputs: inputs, user: user, files: files)
        let urlRequest = try createURLRequest(method: .POST, endpoint: "/completion-messages", body: request)
        
        return try await createStreamingResponse(for: urlRequest)
    }

    /// Stops a streaming generation task.
    /// - Parameters:
    ///   - taskId: The ID of the task to stop, obtained from a streaming chunk.
    ///   - user: The user identifier, which must match the one used in the original request.
    /// - Returns: A `StopCompletionResponse` indicating success.
    public func stopCompletionMessage(taskId: String, user: String) async throws -> StopCompletionResponse {
        struct RequestBody: Codable {
            let user: String
        }
        let request = RequestBody(user: user)
        let data = try await sendRequest(method: .POST, endpoint: "/completion-messages/\(taskId)/stop", body: request)
        return try decode(data, to: StopCompletionResponse.self)
    }

    // MARK: - File Upload

    /// Uploads a file (currently only images are supported) for use in messages.
    /// Supports png, jpg, jpeg, webp, gif formats.
    /// - Parameters:
    ///   - fileData: The raw data of the file to upload.
    ///   - fileName: The name of the file.
    ///   - user: The user identifier.
    ///   - mimeType: Optional MIME type. If not provided, it will be inferred from the file extension.
    /// - Returns: A `FileUploadResponse` with the file's ID and metadata.
    public func uploadFile(fileData: Data, fileName: String, user: String, mimeType: String? = nil) async throws -> FileUploadResponse {
        let multipart = MultipartFormData()
        multipart.addTextField(named: "user", value: user)
        
        // Determine MIME type from file extension if not provided
        let detectedMimeType = mimeType ?? {
            let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
            switch ext {
            case "png": return "image/png"
            case "jpg", "jpeg": return "image/jpeg"
            case "webp": return "image/webp"
            case "gif": return "image/gif"
            default: return "image/png"
            }
        }()
        
        multipart.addFileField(named: "file", fileName: fileName, data: fileData, mimeType: detectedMimeType)

        let data = try await sendMultipartRequest(method: .POST, endpoint: "/files/upload", multipart: multipart)
        return try decode(data, to: FileUploadResponse.self)
    }

    // MARK: - Feedback

    /// Provides feedback on a message.
    /// - Parameters:
    ///   - messageId: The ID of the message to provide feedback on.
    ///   - rating: The rating: "like", "dislike", or `nil` to revoke.
    ///   - user: The user identifier.
    ///   - content: Optional additional feedback content.
    /// - Returns: A `MessageFeedbackResponse` indicating success.
    public func giveMessageFeedback(messageId: String, rating: String?, user: String, content: String? = nil) async throws -> MessageFeedbackResponse {
        let request = MessageFeedbackRequest(rating: rating, user: user, content: content)
        let data = try await sendRequest(method: .POST, endpoint: "/messages/\(messageId)/feedbacks", body: request)
        return try decode(data, to: MessageFeedbackResponse.self)
    }

    /// Retrieves feedbacks for the application.
    /// - Parameters:
    ///   - page: The page number for pagination (default: 1).
    ///   - limit: The number of records per page (default: 20).
    /// - Returns: An `ApplicationFeedbacksResponse` containing a list of feedbacks.
    public func getApplicationFeedbacks(page: Int = 1, limit: Int = 20) async throws -> ApplicationFeedbacksResponse {
        let params = ["page": String(page), "limit": String(limit)]
        let data = try await sendRequest(method: .GET, endpoint: "/app/feedbacks", params: params)
        return try decode(data, to: ApplicationFeedbacksResponse.self)
    }

    // MARK: - Text-to-Audio

    /// Converts text to speech.
    /// - Parameters:
    ///   - messageId: The ID of a generated message. If provided, `text` is ignored.
    ///   - text: The text content to synthesize.
    ///   - user: The user identifier.
    /// - Returns: Raw `Data` of the audio file (e.g., WAV or MP3).
    public func getTextToAudio(messageId: String? = nil, text: String? = nil, user: String) async throws -> Data {
        let request = TextToAudioRequest(messageId: messageId, text: text, user: user)
        return try await sendRequest(method: .POST, endpoint: "/text-to-audio", body: request)
    }

    // MARK: - Application Information

    /// Retrieves basic information about the application.
    /// - Returns: An `ApplicationInfoResponse` object.
    public func getApplicationInfo() async throws -> ApplicationInfoResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/info")
        return try decode(data, to: ApplicationInfoResponse.self)
    }

    /// Retrieves the application's configurable parameters.
    /// - Returns: An `ApplicationParametersResponse` object.
    public func getApplicationParameters() async throws -> ApplicationParametersResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/parameters")
        return try decode(data, to: ApplicationParametersResponse.self)
    }

    /// Retrieves the application's WebApp settings.
    /// - Returns: An `ApplicationSiteResponse` object.
    public func getApplicationSiteSettings() async throws -> ApplicationSiteResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/site")
        return try decode(data, to: ApplicationSiteResponse.self)
    }
}
