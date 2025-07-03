import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for completion-based interactions with Dify
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class CompletionClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Completion Methods
    
    /// Create a completion message
    /// - Parameters:
    ///   - inputs: Input parameters for the completion
    ///   - responseMode: Response mode (blocking or streaming)
    ///   - user: User identifier
    ///   - files: Optional files to include with the request
    /// - Returns: Completion message response
    public func createCompletionMessage(
        inputs: [String: String],
        responseMode: ResponseMode,
        user: String,
        files: [APIFile]? = nil
    ) async throws -> CompletionMessageResponse {
        struct CompletionRequest: Codable {
            let inputs: [String: String]
            let responseMode: ResponseMode
            let user: String
            let files: [APIFile]?
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case responseMode = "response_mode"
                case user
                case files
            }
        }
        
        let request = CompletionRequest(
            inputs: inputs,
            responseMode: responseMode,
            user: user,
            files: files
        )
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/completion-messages",
            body: request,
            stream: responseMode == .streaming
        )
        
        return try decode(data, to: CompletionMessageResponse.self)
    }
    
    /// Create a streaming completion message
    /// - Parameters:
    ///   - inputs: Input parameters for the completion
    ///   - user: User identifier
    ///   - files: Optional files to include with the request
    /// - Returns: Async sequence of data chunks
    public func createStreamingCompletionMessage(
        inputs: [String: String],
        user: String,
        files: [APIFile]? = nil
    ) async throws -> StreamingResponse {
        struct CompletionRequest: Codable {
            let inputs: [String: String]
            let responseMode: ResponseMode
            let user: String
            let files: [APIFile]?
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case responseMode = "response_mode"
                case user
                case files
            }
        }
        
        let request = CompletionRequest(
            inputs: inputs,
            responseMode: .streaming,
            user: user,
            files: files
        )
        
        let url = baseURL.appendingPathComponent("/completion-messages")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.POST.rawValue
        try urlRequest.setJSONBody(request)
        
        return createStreamingResponse(for: urlRequest)
    }
}