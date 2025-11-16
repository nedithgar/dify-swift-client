import Foundation
import Testing
@testable import DifySwiftClient

// MARK: - Gating Flags (module-level to avoid macro circular refs)

let WF_IT_HAS_LIVE_CONFIG: Bool = {
    let environment = ProcessInfo.processInfo.environment
    // Require a narrowly scoped key for Workflow integration tests.
    // This key should belong to a published Workflow App in Dify.
    return (environment["DIFY_WORKFLOW_API_KEY"].map { !$0.isEmpty } ?? false)
}()

/// Integration tests for WorkflowClient using a real Dify instance.
///
/// Opt-in via environment variables:
/// - DIFY_WORKFLOW_API_KEY: required. App API key for a Workflow application.
/// - DIFY_BASE_URL: optional. Defaults to "https://api.dify.ai/v1" (must include /v1).
///
/// Notes:
/// - These tests are tolerant of server differences: inputs are derived from /parameters when possible.
/// - File attachment tests run only if the app allows uploads and the category/method are enabled.
@Suite(
    "WorkflowClient Integration",
    .disabled(if: !WF_IT_HAS_LIVE_CONFIG)
)
struct WorkflowClientIntegrationTest {

    // MARK: - Live Client Bootstrap

    private static func makeClient() throws -> WorkflowClient {
        let environment = ProcessInfo.processInfo.environment
        let workflowApiKey = environment["DIFY_WORKFLOW_API_KEY"] ?? ""
        let baseURL = environment["DIFY_BASE_URL"] ?? "https://api.dify.ai/v1"

        // Use a dedicated URLSession without MockURLProtocol to bypass unit-test mocking for live HTTP requests.
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = max(configuration.timeoutIntervalForRequest, 120)
        configuration.timeoutIntervalForResource = max(configuration.timeoutIntervalForResource, 300)
        let liveSession = URLSession(configuration: configuration)

        return try WorkflowClient(apiKey: workflowApiKey, baseURL: baseURL, session: liveSession)
    }

    private static func makeCompletionClient() throws -> CompletionClient {
        // Shares env + session settings with the workflow client; used for file uploads when allowed.
        let environment = ProcessInfo.processInfo.environment
        let workflowApiKey = environment["DIFY_WORKFLOW_API_KEY"] ?? ""
        let baseURL = environment["DIFY_BASE_URL"] ?? "https://api.dify.ai/v1"

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = max(configuration.timeoutIntervalForRequest, 120)
        configuration.timeoutIntervalForResource = max(configuration.timeoutIntervalForResource, 300)
        let liveSession = URLSession(configuration: configuration)

        return try CompletionClient(apiKey: workflowApiKey, baseURL: baseURL, session: liveSession)
    }

    // MARK: - Utilities

    private func makeUserId() -> String { "wf-it-" + UUID().uuidString.prefix(8) }
    private func makeTraceId() -> String { "trace-" + UUID().uuidString.lowercased() }

    /// Resolve inputs for a run without requiring env overrides.
    /// Priority:
    /// 1) DIFY_WORKFLOW_INPUTS_JSON env (JSON object)
    /// 2) Build from /parameters user_input_form using defaults and required fields
    /// 3) Otherwise, empty dictionary (let app defaults handle)
    private func buildInputs(from params: ApplicationParametersResponse?) -> [String: Any] {
        let environment = ProcessInfo.processInfo.environment
        if let inputsJSON = environment["DIFY_WORKFLOW_INPUTS_JSON"], !inputsJSON.isEmpty,
           let data = inputsJSON.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return jsonObject
        }
        var inputs: [String: Any] = [:]
        guard let items = params?.userInputForm, !items.isEmpty else { return inputs }
        for item in items {
            if let text = item.textInput {
                let value = text.defaultValue.map { !$0.isEmpty ? $0 : "integration" } ?? "integration"
                if text.required || text.defaultValue != nil { inputs[text.variable] = value }
                continue
            }
            if let paragraph = item.paragraph {
                let value = paragraph.defaultValue.map { $0.isEmpty ? "integration paragraph" : $0 } ?? "integration paragraph"
                if paragraph.required || paragraph.defaultValue != nil { inputs[paragraph.variable] = value }
                continue
            }
            if let select = item.select {
                if let defaultValue = select.defaultValue, !defaultValue.isEmpty { inputs[select.variable] = defaultValue; continue }
                if let firstOption = select.options?.first { inputs[select.variable] = firstOption; continue }
                if select.required { inputs[select.variable] = "default" }
                continue
            }
        }
        return inputs
    }

    private struct FileUploadAllowance { let category: String; let method: String }

    /// Decide whether local file uploads are allowed and which category to use.
    private func allowedLocalUploadCategory(_ params: ApplicationParametersResponse?) -> FileUploadAllowance? {
        guard let uploadConfig = params?.fileUpload else { return nil }

        // Prefer document, fall back to image/audio/video if enabled for local_file
        let categories: [(String, UploadCategoryConfig?)] = [
            ("document", uploadConfig.document),
            ("image", uploadConfig.image),
            ("audio", uploadConfig.audio),
            ("video", uploadConfig.video),
            ("custom", uploadConfig.custom)
        ]
        for (name, option) in categories {
            if let categoryConfig = option, categoryConfig.enabled, categoryConfig.transferMethods.contains("local_file") {
                return FileUploadAllowance(category: name, method: "local_file")
            }
        }
        return nil
    }

    // MARK: - Tests

    @Test("Application info and parameters endpoints")
    func testApplicationInfoAndParameters() async throws {
        let client = try Self.makeClient()
        let applicationInfo = try await client.getApplicationInfo()
        #expect(!applicationInfo.name.isEmpty)
        _ = try await client.getApplicationParameters()
        _ = try await client.getApplicationWebAppSettings()
    }

    @Test("Run workflow (blocking) and fetch run detail")
    func testRunWorkflowBlockingAndDetail() async throws {
        let client = try Self.makeClient()
        let parameters = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: parameters)
        let userId = makeUserId()
        let traceId = makeTraceId()

        let response = try await client.runWorkflow(inputs: inputs, user: userId, files: nil, traceId: traceId)
        #expect(!response.workflowRunId.isEmpty)
        #expect(!response.taskId.isEmpty)
        #expect(!response.data.id.isEmpty)
        #expect(!response.data.status.isEmpty)

        let runDetail = try await client.getWorkflowRunDetail(workflowRunId: response.workflowRunId)
        #expect(runDetail.id == response.data.id)
        #expect(runDetail.workflowId == response.data.workflowId)
    }

    @Test("Run workflow by ID (blocking)")
    func testRunWorkflowByIdBlocking() async throws {
        let client = try Self.makeClient()
        let parameters = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: parameters)
        let userId = makeUserId()

        // Discover a workflowId by doing one run first
        let probeRunResponse = try await client.runWorkflow(inputs: inputs, user: userId)
        let workflowId = probeRunResponse.data.workflowId
        #expect(!workflowId.isEmpty)

        let runResponse = try await client.runWorkflow(workflowId: workflowId, inputs: inputs, user: userId)
        #expect(!runResponse.workflowRunId.isEmpty)
        #expect(runResponse.data.workflowId == workflowId)
    }

    @Test("Run workflow (streaming) yields start and finish events")
    func testRunWorkflowStreamingBasic() async throws {
        let client = try Self.makeClient()
        let parameters = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: parameters)
        let userId = makeUserId()
        let eventStream = try await client.runStreamingWorkflow(inputs: inputs, user: userId)

        var sawStarted = false
        var sawFinished = false
        var startedTaskId: String?
        for try await event in eventStream {
            switch event.kind.rawValue {
            case "workflow_started":
                sawStarted = true
                startedTaskId = event.workflowStarted?.taskId
            case "workflow_finished":
                sawFinished = true
                break
            default:
                break
            }
            if sawFinished { break }
        }
        #expect(sawStarted)
        #expect(sawFinished)

        // Best-effort stop (no-op if already finished)
        if let taskId = startedTaskId {
            _ = try? await client.stopWorkflowTask(taskId: taskId, user: userId)
        }
    }

    @Test("Run workflow by ID (streaming)")
    func testRunWorkflowByIdStreaming() async throws {
        let client = try Self.makeClient()
        let parameters = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: parameters)
        let userId = makeUserId()

        // Discover a workflowId
        let probeRunResponse = try await client.runWorkflow(inputs: inputs, user: userId)
        let workflowId = probeRunResponse.data.workflowId
        #expect(!workflowId.isEmpty)

        let eventStream = try await client.runStreamingWorkflow(workflowId: workflowId, inputs: inputs, user: userId)
        var sawFinished = false
        for try await event in eventStream {
            if event.kind == .workflowFinished { sawFinished = true; break }
        }
        #expect(sawFinished)
    }

    @Test("Workflow logs listing (first page)")
    func testGetWorkflowLogsListing() async throws {
        let client = try Self.makeClient()
        // Trigger at least one run to ensure there is something to list
        let parameters = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: parameters)
        _ = try? await client.runWorkflow(inputs: inputs, user: makeUserId())

        let workflowLogs = try await client.getWorkflowLogs(page: 1, limit: 5)
        #expect(workflowLogs.page == 1)
        #expect(workflowLogs.limit == 5)
        #expect(workflowLogs.data.count <= 5)
    }

    @Test("Run workflow with file attachment when allowed")
    func testRunWorkflowWithFileAttachmentIfEnabled() async throws {
        let client = try Self.makeClient()
        let parameters = try? await client.getApplicationParameters()
        guard let uploadAllowance = allowedLocalUploadCategory(parameters) else {
            // App does not accept local file uploads; silently pass this optional test
            return
        }

        // Upload a tiny file via CompletionClient (shared /files/upload endpoint)
        let completionClient = try Self.makeCompletionClient()
        let userId = makeUserId()
        let fileData = Data("workflow integration upload".utf8)
        let uploadedFile = try await completionClient.uploadFile(fileData: fileData, fileName: "wf-it.txt", user: userId, mimeType: "text/plain")

        // Build a single APIFile referencing the uploaded artifact
        let apiFileType = FileType(rawValue: uploadAllowance.category)
        let apiFile = APIFile(type: apiFileType, transferMethod: .localFile, url: nil, uploadFileId: uploadedFile.id)

        let inputs = buildInputs(from: parameters)
        let runResponse = try await client.runWorkflow(inputs: inputs, user: userId, files: [apiFile])
        #expect(!runResponse.workflowRunId.isEmpty)
    }
}
