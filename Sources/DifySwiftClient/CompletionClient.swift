
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for completion-based interactions with the Dify API.
///
/// This client surfaces high-level convenience methods for the Dify "completion" style
/// application endpoints (non-chat, single turn style generations) plus a few shared
/// application utilities (files, feedback, info, parameters, site settings, text-to-audio).
///
/// Creation:
///   Typically you do not instantiate this type directly; instead use whatever factory or
///   initializer your codebase employs for `DifyClient` subclasses (e.g. passing an API key,
///   base URL and optional custom `URLSession`). If you do create it manually, ensure the
///   underlying `DifyClient` initializer is provided correct authentication before issuing
///   requests.
///
/// Concurrency / Thread Safety:
///   The client is `Sendable` (unchecked) and its public API is `async`. Calls can safely be
///   awaited concurrently from multiple tasks. Any per-request state is confined to the call.
///
/// Error Handling:
///   All methods are `async throws`. They may throw:
///   - networking / transport errors from the underlying `URLSession`
///   - decoding errors if the server response does not match expected models
///   - domain errors surfaced as HTTP error responses translated by `sendRequest` (e.g. 4xx/5xx)
///
/// Streaming:
///   For streaming generation (`createStreamingCompletionMessage`) you receive an
///   `AsyncThrowingStream<StreamingCompletionResponse, Error>`. Iterate with `for try await`.
///   You can prematurely cancel by breaking out of the loop or by calling `stopCompletionMessage`
///   with the `task_id` obtained from individual streaming events.
///
/// Tip:
///   Most completion endpoints require at least one variable (commonly `"query"`). Ensure your
///   `inputs` dictionary aligns with the variable definitions configured in your Dify App.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class CompletionClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Completion Messages
    
    /// Sends a synchronous (blocking) completion request to the text generation application.
    ///
    /// Use this when you want the full response in a single payload (as opposed to incremental
    /// streaming events). The call only returns once the model has finished generating.
    ///
    /// - Parameters:
    ///   - inputs: Key/value variable assignments required by the App definition. Must include at
    ///             least one entry (for example: `["query": "Your question"]`). Extra keys not
    ///             defined in the App may be ignored or cause server validation errors.
    ///   - user: A stable unique identifier for the end-user. Used for rate limiting, analytics and
    ///           personalization. Must be identical across related calls for the same user.
    ///   - files: Optional list of previously uploaded files (Vision / multi-modal support) to
    ///            reference in generation. Provide the `id` and the `type` (see `APIFile`).
    /// - Returns: A fully populated `CompletionMessageResponse` containing the entire model output.
    /// - Throws: Network errors, decoding errors, or server-side errors (HTTP 4xx/5xx) propagated
    ///           by `sendRequest`.
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
    
    /// Sends a completion request and receives model output incrementally as a stream.
    ///
    /// Iterate the returned `AsyncThrowingStream` with `for try await event in stream { ... }`.
    /// Each `StreamingCompletionResponse` can represent different event types (e.g. output tokens,
    /// task metadata, finalization). Capture the `task_id` (if present) if you may need to stop
    /// generation early via `stopCompletionMessage`.
    ///
    /// - Parameters:
    ///   - inputs: Variable dictionary required by the App configuration (see
    ///             `createCompletionMessage` for guidance).
    ///   - user: Stable unique identifier for the end-user; must match when stopping a task.
    ///   - files: Optional multi-modal file references for supported models.
    /// - Returns: An `AsyncThrowingStream<StreamingCompletionResponse, Error>` yielding events until
    ///            completion or cancellation.
    /// - Throws: Immediately if request construction or network setup fails. Iteration may later
    ///           throw if the underlying stream encounters an error or malformed event.
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
    ///
    /// Call this to politely request termination of an in-progress streaming generation. The `taskId`
    /// must come from a previously received streaming event and the `user` must match exactly.
    ///
    /// - Parameters:
    ///   - taskId: The identifier of the streaming generation task (from a streaming chunk).
    ///   - user: The same user identifier originally supplied when starting the stream.
    /// - Returns: A `StopCompletionResponse` indicating acknowledgement of the stop request.
    /// - Throws: Network / decoding errors or server-side errors (e.g., if task not found / mismatch).
    public func stopCompletionMessage(taskId: String, user: String) async throws -> StopCompletionResponse {
        struct RequestBody: Codable {
            let user: String
        }
        let request = RequestBody(user: user)
        let data = try await sendRequest(method: .POST, endpoint: "/completion-messages/\(taskId)/stop", body: request)
        return try decode(data, to: StopCompletionResponse.self)
    }

    // MARK: - File Upload

    /// Uploads a file for use in later completion / workflow requests.
    ///
    /// Currently geared toward image (vision) support; additional formats may be accepted by the
    /// server. If `mimeType` is omitted, a best-effort inference is performed using the file
    /// extension; unknown extensions default to `application/octet-stream`.
    ///
    /// - Parameters:
    ///   - fileData: Raw bytes of the file.
    ///   - fileName: The original (or desired) filename including extension.
    ///   - user: User identifier associated with the file (authorization / segregation).
    ///   - mimeType: Optional explicit MIME type override.
    /// - Returns: `FileUploadResponse` containing the uploaded file's identifier and metadata.
    /// - Throws: Network / decoding / server errors.
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
            default: return "application/octet-stream"
            }
        }()
        
        multipart.addFileField(named: "file", fileName: fileName, data: fileData, mimeType: detectedMimeType)

        let data = try await sendMultipartRequest(method: .POST, endpoint: "/files/upload", multipart: multipart)
        return try decode(data, to: FileUploadResponse.self)
    }

    // MARK: - Feedback

    /// Provides feedback on a previously generated message.
    ///
    /// Passing `nil` for `rating` revokes / clears an existing rating. Additional free-form
    /// `content` can be supplied for qualitative feedback if supported by the server.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message being evaluated.
    ///   - rating: One of `"like"`, `"dislike"`, or `nil` to revoke.
    ///   - user: User identifier (must match original generation request for attribution).
    ///   - content: Optional elaborative text.
    /// - Returns: A `MessageFeedbackResponse` confirming the stored feedback state.
    /// - Throws: Network / decoding / server errors (e.g., invalid message ID).
    public func giveMessageFeedback(messageId: String, rating: String?, user: String, content: String? = nil) async throws -> MessageFeedbackResponse {
        let request = MessageFeedbackRequest(rating: rating, user: user, content: content)
        let data = try await sendRequest(method: .POST, endpoint: "/messages/\(messageId)/feedbacks", body: request)
        return try decode(data, to: MessageFeedbackResponse.self)
    }

    // MARK: - Files

    /// Retrieves the bytes of a previously uploaded file.
    ///
    /// Set `asAttachment` to `true` to request `Content-Disposition: attachment` semantics (when
    /// supported by the server) which may influence downstream handling (e.g., file downloads).
    ///
    /// - Parameters:
    ///   - fileId: Identifier of the file to retrieve.
    ///   - asAttachment: If `true`, asks the server for a downloadable attachment variant.
    /// - Returns: Raw binary `Data` of the file.
    /// - Throws: Network / server errors (404 if not found, etc.).
    public func previewFile(fileId: String, asAttachment: Bool = false) async throws -> Data {
        var params: [String: String]? = nil
        if asAttachment {
            params = ["as_attachment": "true"]
        }
        return try await sendRequest(method: .GET, endpoint: "/files/\(fileId)/preview", params: params)
    }

    /// Retrieves paginated end-user feedback across the application scope.
    ///
    /// - Parameters:
    ///   - page: 1-based page index (default 1).
    ///   - limit: Page size (default 20). Respect server-imposed maximums to avoid errors.
    /// - Returns: `ApplicationFeedbacksResponse` with aggregated feedback records.
    /// - Throws: Network / decoding / server errors.
    public func getApplicationFeedbacks(page: Int = 1, limit: Int = 20) async throws -> ApplicationFeedbacksResponse {
        let params = ["page": String(page), "limit": String(limit)]
        let data = try await sendRequest(method: .GET, endpoint: "/app/feedbacks", params: params)
        return try decode(data, to: ApplicationFeedbacksResponse.self)
    }

    // MARK: - Text-to-Audio

    /// Converts either raw text or an existing message's content into synthesized speech.
    ///
    /// Supply `messageId` to synthesize the model-generated output of a prior completion. If
    /// `messageId` is provided any explicit `text` parameter is ignored server-side.
    ///
    /// - Parameters:
    ///   - messageId: Optional message identifier whose content will be rendered as audio.
    ///   - text: Direct text to synthesize (ignored if `messageId` is non-nil).
    ///   - user: User identifier (authorization / personalization context).
    /// - Returns: Audio bytes (`Data`) in a format determined by server defaults / configuration.
    /// - Throws: Network / decoding / server errors.
    public func getTextToAudio(messageId: String? = nil, text: String? = nil, user: String) async throws -> Data {
        let request = TextToAudioRequest(messageId: messageId, text: text, user: user)
        return try await sendRequest(method: .POST, endpoint: "/text-to-audio", body: request)
    }

    // MARK: - Application Information

    /// Retrieves high-level metadata describing the application (name, modes, etc.).
    ///
    /// - Returns: `ApplicationInfoResponse` with summary fields.
    /// - Throws: Network / decoding / server errors.
    public func getApplicationInfo() async throws -> ApplicationInfoResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/info")
        return try decode(data, to: ApplicationInfoResponse.self)
    }

    /// Retrieves the application's configurable parameter schema / current values.
    ///
    /// - Returns: `ApplicationParametersResponse` describing tunable inputs.
    /// - Throws: Network / decoding / server errors.
    public func getApplicationParameters() async throws -> ApplicationParametersResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/parameters")
        return try decode(data, to: ApplicationParametersResponse.self)
    }

    /// Retrieves the application's WebApp / site configuration (branding, UI settings, etc.).
    ///
    /// - Returns: `ApplicationSiteResponse` with site presentation details.
    /// - Throws: Network / decoding / server errors.
    public func getApplicationSiteSettings() async throws -> ApplicationSiteResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/site")
        return try decode(data, to: ApplicationSiteResponse.self)
    }
}
