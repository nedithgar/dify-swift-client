import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for executing and managing workflows in the Dify API.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class WorkflowClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Workflow Execution
    
    /// Runs a workflow and waits for the complete result.
    /// - Parameters:
    ///   - inputs: A dictionary of input variables for the workflow.
    ///   - user: A unique identifier for the end-user.
    /// - Returns: A `WorkflowResponse` object containing the final result of the workflow execution.
    public func runWorkflow(inputs: [String: Any], user: String) async throws -> WorkflowResponse {
        let requestBody = WorkflowRequestBody(inputs: inputs, responseMode: .blocking, user: user)
        let data = try await sendRequest(method: .POST, endpoint: "/workflows/run", body: requestBody)
        return try decode(data, to: WorkflowResponse.self)
    }
    
    /// Runs a workflow and streams the events.
    /// - Parameters:
    ///   - inputs: A dictionary of input variables for the workflow.
    ///   - user: A unique identifier for the end-user.
    /// - Returns: An `AsyncThrowingStream` of `StreamingWorkflowResponse` events.
    public func runStreamingWorkflow(inputs: [String: Any], user: String) async throws -> AsyncThrowingStream<StreamingWorkflowResponse, Error> {
        let requestBody = WorkflowRequestBody(inputs: inputs, responseMode: .streaming, user: user)
        let request = try createURLRequest(method: .POST, endpoint: "/workflows/run", body: requestBody)
        return try await createStreamingResponse(for: request)
    }
    
    /// Stops a running workflow task.
    /// - Parameters:
    ///   - taskId: The ID of the task to stop, obtained from a streaming event.
    ///   - user: The user identifier.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func stopWorkflowTask(taskId: String, user: String) async throws -> BaseResponse {
        let requestBody = ["user": user]
        let data = try await sendRequest(method: .POST, endpoint: "/workflows/tasks/\(taskId)/stop", body: requestBody)
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Gets the current execution results of a workflow task based on the workflow execution ID.
    /// - Parameter workflowId: The workflow execution ID.
    /// - Returns: A `WorkflowRunDetailResponse` containing the execution details.
    public func getWorkflowRunDetail(workflowId: String) async throws -> WorkflowRunDetailResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/workflows/run/\(workflowId)")
        return try decode(data, to: WorkflowRunDetailResponse.self)
    }
    
    /// Gets workflow logs with pagination and filtering options.
    /// - Parameters:
    ///   - keyword: Optional keyword to search.
    ///   - status: Optional status filter (succeeded/failed/stopped).
    ///   - page: Current page number (default: 1).
    ///   - limit: Number of items per page (default: 20).
    ///   - createdByEndUserSessionId: Optional filter by end user session ID.
    ///   - createdByAccount: Optional filter by account email.
    /// - Returns: A `WorkflowLogsResponse` containing the paginated logs.
    public func getWorkflowLogs(
        keyword: String? = nil,
        status: String? = nil,
        page: Int = 1,
        limit: Int = 20,
        createdByEndUserSessionId: String? = nil,
        createdByAccount: String? = nil
    ) async throws -> WorkflowLogsResponse {
        var params: [String: String] = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        if let keyword = keyword {
            params["keyword"] = keyword
        }
        if let status = status {
            params["status"] = status
        }
        if let createdByEndUserSessionId = createdByEndUserSessionId {
            params["created_by_end_user_session_id"] = createdByEndUserSessionId
        }
        if let createdByAccount = createdByAccount {
            params["created_by_account"] = createdByAccount
        }
        
        let data = try await sendRequest(method: .GET, endpoint: "/workflows/logs", params: params)
        return try decode(data, to: WorkflowLogsResponse.self)
    }
    
    /// Gets basic information about the workflow application.
    /// - Returns: An `ApplicationInfoResponse` containing the application details.
    public func getApplicationInfo() async throws -> ApplicationInfoResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/info")
        return try decode(data, to: ApplicationInfoResponse.self)
    }
    
    /// Gets application parameters information including input forms and file upload configurations.
    /// - Returns: An `ApplicationParametersResponse` containing the parameter details.
    public func getApplicationParameters() async throws -> ApplicationParametersResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/parameters")
        return try decode(data, to: ApplicationParametersResponse.self)
    }
    
    /// Gets the WebApp settings of the application.
    /// - Returns: An `ApplicationWebAppSettingsResponse` containing the WebApp settings.
    public func getApplicationWebAppSettings() async throws -> ApplicationWebAppSettingsResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/site")
        return try decode(data, to: ApplicationWebAppSettingsResponse.self)
    }
    
    // MARK: - Private Helpers
    
    private struct WorkflowRequestBody: Codable {
        let inputs: [String: AnyCodable]
        let responseMode: ResponseMode
        let user: String
        
        init(inputs: [String: Any], responseMode: ResponseMode, user: String) {
            self.inputs = inputs.mapValues { AnyCodable($0) }
            self.responseMode = responseMode
            self.user = user
        }
        
        private enum CodingKeys: String, CodingKey {
            case inputs, user
            case responseMode = "response_mode"
        }
    }
}