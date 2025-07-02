import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for workflow-based interactions with Dify
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class WorkflowClient: DifyClient {
    
    // MARK: - Workflow Methods
    
    /// Run a workflow
    /// - Parameters:
    ///   - inputs: Input parameters for the workflow
    ///   - responseMode: Response mode (streaming or blocking)
    ///   - user: User identifier
    /// - Returns: Workflow response
    public func run(
        inputs: [String: String],
        responseMode: ResponseMode = .streaming,
        user: String = "abc-123"
    ) async throws -> WorkflowResponse {
        struct WorkflowRequest: Codable {
            let inputs: [String: String]
            let responseMode: ResponseMode
            let user: String
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case responseMode = "response_mode"
                case user
            }
        }
        
        let request = WorkflowRequest(
            inputs: inputs,
            responseMode: responseMode,
            user: user
        )
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/workflows/run",
            body: request
        )
        
        return try decode(data, to: WorkflowResponse.self)
    }
    
    /// Run a workflow with streaming response
    /// - Parameters:
    ///   - inputs: Input parameters for the workflow
    ///   - user: User identifier
    /// - Returns: Async sequence of data chunks
    public func runStreaming(
        inputs: [String: String],
        user: String = "abc-123"
    ) async throws -> StreamingResponse {
        struct WorkflowRequest: Codable {
            let inputs: [String: String]
            let responseMode: ResponseMode
            let user: String
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case responseMode = "response_mode"
                case user
            }
        }
        
        let request = WorkflowRequest(
            inputs: inputs,
            responseMode: .streaming,
            user: user
        )
        
        let url = baseURL.appendingPathComponent("/workflows/run")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.POST.rawValue
        try urlRequest.setJSONBody(request)
        
        return createStreamingResponse(for: urlRequest)
    }
    
    /// Stop a workflow task
    /// - Parameters:
    ///   - taskId: Task ID to stop
    ///   - user: User identifier
    /// - Returns: Base response
    public func stop(taskId: String, user: String) async throws -> BaseResponse {
        struct StopRequest: Codable {
            let user: String
        }
        
        let request = StopRequest(user: user)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/workflows/tasks/\(taskId)/stop",
            body: request
        )
        
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Get workflow run result
    /// - Parameter workflowRunId: Workflow run ID
    /// - Returns: Workflow response
    public func getResult(workflowRunId: String) async throws -> WorkflowResponse {
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/workflows/run/\(workflowRunId)"
        )
        
        return try decode(data, to: WorkflowResponse.self)
    }
    
    /// Get workflow logs
    /// - Parameters:
    ///   - keyword: Optional keyword to search
    ///   - status: Optional status filter (succeeded/failed/stopped)
    ///   - page: Page number (default 1)
    ///   - limit: Records per page (default 20)
    ///   - createdByEndUserSessionId: Optional filter by end user session ID
    ///   - createdByAccount: Optional filter by account email
    /// - Returns: Workflow logs response
    public func getWorkflowLogs(
        keyword: String? = nil,
        status: String? = nil,
        page: Int = 1,
        limit: Int = 20,
        createdByEndUserSessionId: String? = nil,
        createdByAccount: String? = nil
    ) async throws -> WorkflowLogsResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let sessionId = createdByEndUserSessionId {
            queryItems.append(URLQueryItem(name: "created_by_end_user_session_id", value: sessionId))
        }
        if let account = createdByAccount {
            queryItems.append(URLQueryItem(name: "created_by_account", value: account))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/workflows/logs",
            queryItems: queryItems
        )
        
        return try decode(data, to: WorkflowLogsResponse.self)
    }
}