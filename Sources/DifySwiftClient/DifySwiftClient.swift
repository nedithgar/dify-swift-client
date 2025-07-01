import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Base client for interacting with the Dify API
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
open class DifyClient {
    
    // MARK: - Properties
    
    public let apiKey: String
    public let baseURL: URL
    private let session: URLSession
    
    // MARK: - Initialization
    
    /// Initialize a new Dify client
    /// - Parameters:
    ///   - apiKey: Your Dify API key
    ///   - baseURL: Base URL for the Dify API (defaults to https://api.dify.ai/v1)
    ///   - session: URLSession to use for requests (defaults to shared session)
    public init(apiKey: String, baseURL: String = "https://api.dify.ai/v1", session: URLSession = .shared) throws {
        guard !apiKey.isEmpty else {
            throw DifyError.invalidAPIKey
        }
        
        guard let url = URL(string: baseURL), url.scheme != nil else {
            throw DifyError.invalidURL(baseURL)
        }
        
        self.apiKey = apiKey
        self.baseURL = url
        self.session = session
    }
    
    // MARK: - Request Methods
    
    /// Send a request to the Dify API
    /// - Parameters:
    ///   - method: HTTP method
    ///   - endpoint: API endpoint (will be appended to base URL)
    ///   - body: Request body (will be JSON encoded)
    ///   - queryItems: Query parameters
    ///   - stream: Whether this is a streaming request
    /// - Returns: Response data
    internal func sendRequest<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: T? = nil as String?,
        queryItems: [URLQueryItem] = [],
        stream: Bool = false
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url.appendingQueryItems(queryItems))
        request.httpMethod = method.rawValue
        
        // Set headers
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Set body if provided
        if let body = body {
            try request.setJSONBody(body)
        }
        
        if stream {
            return try await sendStreamingRequest(request)
        } else {
            return try await sendStandardRequest(request)
        }
    }
    
    /// Send a request with file uploads
    /// - Parameters:
    ///   - method: HTTP method
    ///   - endpoint: API endpoint
    ///   - parameters: Form parameters
    ///   - files: Files to upload
    /// - Returns: Response data
    internal func sendRequestWithFiles(
        method: HTTPMethod,
        endpoint: String,
        parameters: [String: String],
        files: [(key: String, filename: String, data: Data, mimeType: String)]
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Set headers
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Set multipart body
        request.setMultipartBody(parameters: parameters, fileData: files)
        
        return try await sendStandardRequest(request)
    }
    
    private func sendStandardRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw DifyError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        return data
    }
    
    private func sendStreamingRequest(_ request: URLRequest) async throws -> Data {
        // For now, return standard request. Streaming will be handled by the specific methods
        return try await sendStandardRequest(request)
    }
    
    /// Create a streaming response for the given request
    /// - Parameter request: URLRequest to stream
    /// - Returns: StreamingResponse for async iteration
    internal func createStreamingResponse(for request: URLRequest) -> StreamingResponse {
        var streamingRequest = request
        streamingRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return StreamingResponse(urlRequest: streamingRequest, session: session)
    }
    
    // MARK: - Utility Methods
    
    /// Decode response data to the specified type
    /// - Parameters:
    ///   - data: Response data
    ///   - type: Type to decode to
    /// - Returns: Decoded object
    internal func decode<T: Codable>(_ data: Data, to type: T.Type) throws -> T {
        do {
            return try JSONDecoder.difyDecoder.decode(type, from: data)
        } catch {
            throw DifyError.decodingError(error)
        }
    }
    
    // MARK: - Base API Methods
    
    /// Send message feedback
    /// - Parameters:
    ///   - messageId: ID of the message to provide feedback for
    ///   - rating: Rating (like/dislike)
    ///   - user: User identifier
    /// - Returns: Message feedback response
    public func messageFeedback(messageId: String, rating: String, user: String) async throws -> MessageFeedbackResponse {
        struct FeedbackRequest: Codable {
            let rating: String
            let user: String
        }
        
        let request = FeedbackRequest(rating: rating, user: user)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/messages/\(messageId)/feedbacks",
            body: request
        )
        
        return try decode(data, to: MessageFeedbackResponse.self)
    }
    
    /// Get application parameters
    /// - Parameter user: User identifier
    /// - Returns: Application parameters response
    public func getApplicationParameters(user: String) async throws -> ApplicationParametersResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/parameters",
            queryItems: queryItems
        )
        
        return try decode(data, to: ApplicationParametersResponse.self)
    }
    
    /// Upload a file
    /// - Parameters:
    ///   - user: User identifier
    ///   - fileData: File data to upload
    ///   - filename: Name of the file
    ///   - mimeType: MIME type of the file
    /// - Returns: File upload response
    public func uploadFile(user: String, fileData: Data, filename: String, mimeType: String) async throws -> FileUploadResponse {
        let data = try await sendRequestWithFiles(
            method: .POST,
            endpoint: "/files/upload",
            parameters: ["user": user],
            files: [(key: "file", filename: filename, data: fileData, mimeType: mimeType)]
        )
        
        return try decode(data, to: FileUploadResponse.self)
    }
    
    /// Convert text to audio
    /// - Parameters:
    ///   - text: Text to convert
    ///   - user: User identifier
    ///   - streaming: Whether to use streaming mode
    /// - Returns: Text to audio response
    public func textToAudio(text: String, user: String, streaming: Bool = false) async throws -> TextToAudioResponse {
        struct TextToAudioRequest: Codable {
            let text: String
            let user: String
            let streaming: Bool
        }
        
        let request = TextToAudioRequest(text: text, user: user, streaming: streaming)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/text-to-audio",
            body: request
        )
        
        return try decode(data, to: TextToAudioResponse.self)
    }
    
    /// Get meta information
    /// - Parameter user: User identifier
    /// - Returns: Meta response
    public func getMeta(user: String) async throws -> MetaResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/meta",
            queryItems: queryItems
        )
        
        return try decode(data, to: MetaResponse.self)
    }
}
