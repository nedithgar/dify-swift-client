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