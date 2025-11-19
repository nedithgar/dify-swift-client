import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for executing and managing Workflow applications in the Dify API.
///
/// ## Overview
/// Provides both blocking (final response) and streaming interfaces for running generic
/// workflow applications or a specific workflow version by id. It also exposes helper
/// endpoints for inspecting run details, retrieving logs, stopping tasks in progress,
/// and fetching application metadata (info / parameters / WebApp settings).
///
/// ## Thread Safety
/// Instances are intended to be used from concurrent contexts. This class is marked
/// `@unchecked Sendable`, but callers must avoid mutating shared state in captured
/// inputs while a request is in flight.
///
/// ## Error Handling
/// All async APIs `throw` if network transport fails, if the server returns a non‑success
/// status code (as normalized by ``DifyClient``), or if decoding the response model fails.
///
/// ## See Also
/// - `runWorkflow(inputs:user:files:traceId:)`
/// - `runStreamingWorkflow(inputs:user:files:traceId:)`
/// - `runWorkflow(workflowId:inputs:user:files:traceId:)`
/// - `runStreamingWorkflow(workflowId:inputs:user:files:traceId:)`
/// - `getWorkflowRunDetail(workflowRunId:)`
/// - `stopWorkflowTask(taskId:user:)`
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class WorkflowClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Workflow Execution
    
    /// Runs a workflow (generic workflow application context) and waits for the complete result.
    ///
    /// Use this when you have a workflow application endpoint (no explicit workflow version id)
    /// and you want the final aggregated response instead of a stream of intermediate events.
    ///
    /// - Parameters:
    ///   - inputs: Dictionary of workflow input variables (primitive JSON‑compatible values).
    ///   - user: Stable unique identifier of the end user invoking the workflow.
    ///   - files: Optional list of files to upload or associate with this run.
    ///   - traceId: Optional external correlation or trace identifier for observability.
    /// - Returns: The final decoded `WorkflowResponse` once execution completes.
    /// - Throws: Network/transport errors, server‑side errors (normalized by `DifyClient`), or decoding errors.
    ///
    /// ## Example
    /// ```swift
    /// let client = try WorkflowClient(apiKey: "<API_KEY>")
    /// let response = try await client.runWorkflow(
    ///     inputs: ["question": "What can you do?"],
    ///     user: "user-123"
    /// )
    /// print(response.data.status)
    /// ```
    ///
    /// - SeeAlso: `runStreamingWorkflow(inputs:user:files:traceId:)`
    public func runWorkflow(inputs: [String: Any], user: String, files: [APIFile]? = nil, traceId: String? = nil) async throws -> WorkflowResponse {
        let requestBody = WorkflowRequestBody(inputs: inputs, responseMode: .blocking, user: user, files: files, traceId: traceId)
        let data = try await sendRequest(method: .POST, endpoint: "/workflows/run", body: requestBody)
        return try decode(data, to: WorkflowResponse.self)
    }
    
    /// Runs a workflow and returns a stream of intermediate events (node output, logs, final result).
    ///
    /// Use this to build responsive UIs that reflect real‑time progress. The returned
    /// `AsyncThrowingStream` ends when a terminal event is received or an error occurs.
    ///
    /// - Parameters:
    ///   - inputs: Dictionary of workflow input variables.
    ///   - user: Stable unique identifier of the end user.
    ///   - files: Optional list of files to upload for this run.
    ///   - traceId: Optional external correlation or trace identifier.
    /// - Returns: An asynchronous stream yielding `StreamingWorkflowResponse` events.
    /// - Throws: If request creation fails, networking fails, the server returns an error, or streaming parsing fails.
    ///
    /// ## Example
    /// ```swift
    /// let client = try WorkflowClient(apiKey: "<API_KEY>")
    /// let stream = try await client.runStreamingWorkflow(
    ///     inputs: ["question": "Explain streaming"],
    ///     user: "user-123"
    /// )
    /// for try await event in stream {
    ///     switch event.kind {
    ///     case .nodeStarted:    print("node started")
    ///     case .textChunk:      print(event.textChunk?.data ?? "")
    ///     case .workflowFinished: print("done")
    ///     default: break
    ///     }
    /// }
    /// ```
    ///
    /// - Important: On Apple platforms, streaming leverages `URLSession.bytes` when available; in tests and on Linux it uses a buffered fallback for deterministic SSE parsing.
    /// - SeeAlso: `runWorkflow(inputs:user:files:traceId:)`
    public func runStreamingWorkflow(inputs: [String: Any], user: String, files: [APIFile]? = nil, traceId: String? = nil) async throws -> AsyncThrowingStream<StreamingWorkflowResponse, Error> {
        let requestBody = WorkflowRequestBody(inputs: inputs, responseMode: .streaming, user: user, files: files, traceId: traceId)
        let request = try createURLRequest(method: .POST, endpoint: "/workflows/run", body: requestBody)
        return try await createStreamingResponse(for: request)
    }

    /// Runs a specific workflow version by its id and waits for the complete result.
    ///
    /// Use this variant when you need explicit control over the workflow version (instead of the
    /// generic application endpoint).
    ///
    /// - Parameters:
    ///   - workflowId: The identifier of the workflow version to execute.
    ///   - inputs: Dictionary of workflow input variables.
    ///   - user: Stable unique identifier of the end user.
    ///   - files: Optional list of files to upload for this run.
    ///   - traceId: Optional external correlation or trace identifier.
    /// - Returns: The final `WorkflowResponse` when execution completes.
    /// - Throws: Network/transport errors, server‑side errors, or decoding errors.
    ///
    /// - SeeAlso: `runStreamingWorkflow(workflowId:inputs:user:files:traceId:)`
    public func runWorkflow(workflowId: String, inputs: [String: Any], user: String, files: [APIFile]? = nil, traceId: String? = nil) async throws -> WorkflowResponse {
        let requestBody = WorkflowRequestBody(inputs: inputs, responseMode: .blocking, user: user, files: files, traceId: traceId)
        let data = try await sendRequest(method: .POST, endpoint: "/workflows/\(workflowId)/run", body: requestBody)
        return try decode(data, to: WorkflowResponse.self)
    }

    /// Runs a specific workflow version by its id and streams intermediate events.
    ///
    /// - Parameters:
    ///   - workflowId: Identifier of the workflow version to execute.
    ///   - inputs: Dictionary of workflow input variables.
    ///   - user: Stable unique identifier of the end user.
    ///   - files: Optional list of files to upload for this run.
    ///   - traceId: Optional external correlation or trace identifier.
    /// - Returns: An `AsyncThrowingStream` yielding `StreamingWorkflowResponse` events.
    /// - Throws: If creating the request fails, networking fails, the server returns an error, or parsing streaming events fails.
    ///
    /// - SeeAlso: `runWorkflow(workflowId:inputs:user:files:traceId:)`
    public func runStreamingWorkflow(workflowId: String, inputs: [String: Any], user: String, files: [APIFile]? = nil, traceId: String? = nil) async throws -> AsyncThrowingStream<StreamingWorkflowResponse, Error> {
        let requestBody = WorkflowRequestBody(inputs: inputs, responseMode: .streaming, user: user, files: files, traceId: traceId)
        let request = try createURLRequest(method: .POST, endpoint: "/workflows/\(workflowId)/run", body: requestBody)
        return try await createStreamingResponse(for: request)
    }
    
    /// Stops a running workflow task (best‑effort cancellation of in‑progress node execution).
    ///
    /// The `taskId` is typically obtained from a streaming event that exposes cancellable task
    /// identifiers. The server may respond that the task has already completed.
    ///
    /// - Parameters:
    ///   - taskId: Identifier of the running task to stop.
    ///   - user: Stable unique identifier of the end user.
    /// - Returns: A `BaseResponse` describing the cancellation result.
    /// - Throws: Network / server / decoding errors.
    ///
    /// - SeeAlso: `runStreamingWorkflow(inputs:user:files:traceId:)`, `runStreamingWorkflow(workflowId:inputs:user:files:traceId:)`
    public func stopWorkflowTask(taskId: String, user: String) async throws -> BaseResponse {
        let requestBody = ["user": user]
        let data = try await sendRequest(method: .POST, endpoint: "/workflows/tasks/\(taskId)/stop", body: requestBody)
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Retrieves the (possibly in‑progress) execution detail for a workflow run.
    ///
    /// Use this to poll for state when you are not using the streaming API or want to reload
    /// state after a client restart.
    ///
    /// - Parameter workflowRunId: The unique run/execution identifier.
    /// - Returns: A `WorkflowRunDetailResponse` containing current execution details.
    /// - Throws: Network / server / decoding errors.
    public func getWorkflowRunDetail(workflowRunId: String) async throws -> WorkflowRunDetailResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/workflows/run/\(workflowRunId)")
        return try decode(data, to: WorkflowRunDetailResponse.self)
    }

    /// Deprecated: Use `getWorkflowRunDetail(workflowRunId:)` instead.
    @available(*, deprecated, renamed: "getWorkflowRunDetail(workflowRunId:)")
    public func getWorkflowRunDetail(workflowId: String) async throws -> WorkflowRunDetailResponse {
        return try await getWorkflowRunDetail(workflowRunId: workflowId)
    }
    
    /// Retrieves workflow execution logs (historical runs) with optional filters.
    ///
    /// - Parameters:
    ///   - keyword: Full‑text search keyword applied to log entries or run metadata.
    ///   - status: Filter by run status (for example, `succeeded`, `failed`, `stopped`).
    ///   - page: 1‑based page index. Default is `1`.
    ///   - limit: Page size. Default is `20`.
    ///   - createdByEndUserSessionId: Filter by originating end‑user session id.
    ///   - createdByAccount: Filter by account email (for administrative contexts).
    /// - Returns: A `WorkflowLogsResponse` containing paginated log items.
    /// - Throws: Network / server / decoding errors.
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
    
    /// Fetches basic application information/metadata for the workflow app.
    ///
    /// - Returns: An `ApplicationInfoResponse` describing the application.
    /// - Throws: Network / server / decoding errors.
    public func getApplicationInfo() async throws -> ApplicationInfoResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/info")
        return try decode(data, to: ApplicationInfoResponse.self)
    }
    
    /// Fetches application parameters (input schema, UI form configuration, file upload settings).
    ///
    /// - Returns: An `ApplicationParametersResponse` with parameter configuration.
    /// - Throws: Network / server / decoding errors.
    public func getApplicationParameters() async throws -> ApplicationParametersResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/parameters")
        return try decode(data, to: ApplicationParametersResponse.self)
    }
    
    /// Fetches WebApp (site) settings for the workflow application.
    ///
    /// - Returns: An `ApplicationWebAppSettingsResponse` with WebApp UI settings.
    /// - Throws: Network / server / decoding errors.
    public func getApplicationWebAppSettings() async throws -> ApplicationWebAppSettingsResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/site")
        return try decode(data, to: ApplicationWebAppSettingsResponse.self)
    }
    
    // MARK: - Private Helpers
    
    /// Internal request body wrapper for workflow executions.
    ///
    /// Converts a user‑supplied `[String: Any]` input map into `[String: AnyCodable]` for
    /// JSON encoding while also surfacing response mode, user identity, file attachments,
    /// and an optional trace identifier.
    private struct WorkflowRequestBody: Codable {
        let inputs: [String: AnyCodable]
        let responseMode: ResponseMode
        let user: String
        let files: [APIFile]?
        let traceId: String?

        init(inputs: [String: Any], responseMode: ResponseMode, user: String, files: [APIFile]?, traceId: String?) {
            self.inputs = inputs.mapValues { AnyCodable($0) }
            self.responseMode = responseMode
            self.user = user
            self.files = files
            self.traceId = traceId
        }

        private enum CodingKeys: String, CodingKey {
            case inputs, user, files
            case responseMode = "response_mode"
            case traceId = "trace_id"
        }
    }
}
