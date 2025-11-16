import Foundation
import Testing
@testable import DifySwiftClient

// MARK: - Gating Flags (module-level to avoid macro circular refs)

let WF_IT_HAS_LIVE_CONFIG: Bool = {
    let env = ProcessInfo.processInfo.environment
    // Require a narrowly scoped key for Workflow integration tests.
    // This key should belong to a published Workflow App in Dify.
    return (env["DIFY_WORKFLOW_API_KEY"].map { !$0.isEmpty } ?? false)
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
        let env = ProcessInfo.processInfo.environment
        let apiKey = env["DIFY_WORKFLOW_API_KEY"] ?? ""
        let baseURL = env["DIFY_BASE_URL"] ?? "https://api.dify.ai/v1"

        // Use a dedicated URLSession without MockURLProtocol to bypass unit-test mocking for live HTTP requests.
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = max(configuration.timeoutIntervalForRequest, 120)
        configuration.timeoutIntervalForResource = max(configuration.timeoutIntervalForResource, 300)
        let liveSession = URLSession(configuration: configuration)

        return try WorkflowClient(apiKey: apiKey, baseURL: baseURL, session: liveSession)
    }

    private static func makeCompletionClient() throws -> CompletionClient {
        // Shares env + session settings with the workflow client; used for file uploads when allowed.
        let env = ProcessInfo.processInfo.environment
        let apiKey = env["DIFY_WORKFLOW_API_KEY"] ?? ""
        let baseURL = env["DIFY_BASE_URL"] ?? "https://api.dify.ai/v1"

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = max(configuration.timeoutIntervalForRequest, 120)
        configuration.timeoutIntervalForResource = max(configuration.timeoutIntervalForResource, 300)
        let liveSession = URLSession(configuration: configuration)

        return try CompletionClient(apiKey: apiKey, baseURL: baseURL, session: liveSession)
    }

    // MARK: - Utilities

    private func makeUserId() -> String { "wf-it-" + UUID().uuidString.prefix(8) }
    private func makeTraceId() -> String { "trace-" + UUID().uuidString.lowercased() }

    /// Build inputs for a run by inspecting the app's /parameters configuration.
    /// Fills required fields with defaults when present; otherwise supplies sensible fallbacks.
    /// Always ensures a reasonable value for common key "user_input" to satisfy typical workflows.
    private func buildInputs(from params: ApplicationParametersResponse?) -> [String: Any] {
        var inputs: [String: Any] = [:]

        if let items = params?.userInputForm, !items.isEmpty {
            for item in items {
                if let t = item.textInput {
                    let value = t.defaultValue.isEmpty ? "integration" : t.defaultValue
                    inputs[t.variable] = value
                    continue
                }
                if let p = item.paragraph {
                    let value = p.defaultValue.isEmpty ? "integration paragraph" : p.defaultValue
                    inputs[p.variable] = value
                    continue
                }
                if let s = item.select {
                    let candidate = s.defaultValue.isEmpty ? (s.options.first ?? "option") : s.defaultValue
                    inputs[s.variable] = candidate
                    continue
                }
            }
        }

        // Heuristic fallback: most workflow apps expect `user_input`.
        if inputs["user_input"] == nil {
            inputs["user_input"] = "Hello from WorkflowClient integration test"
        }

        return inputs
    }

    private struct FileUploadAllowance { let category: String; let method: String }

    /// Decide whether local file uploads are allowed and which category to use.
    private func allowedLocalUploadCategory(_ params: ApplicationParametersResponse?) -> FileUploadAllowance? {
        guard let cfg = params?.fileUpload else { return nil }

        // Prefer document, fall back to image/audio/video if enabled for local_file
        let categories: [(String, UploadCategoryConfig?)] = [
            ("document", cfg.document),
            ("image", cfg.image),
            ("audio", cfg.audio),
            ("video", cfg.video),
            ("custom", cfg.custom)
        ]
        for (name, opt) in categories {
            if let c = opt, c.enabled, c.transferMethods.contains("local_file") {
                return FileUploadAllowance(category: name, method: "local_file")
            }
        }
        return nil
    }

    // MARK: - Tests

    @Test("Application info and parameters endpoints")
    func testApplicationInfoAndParameters() async throws {
        let client = try Self.makeClient()
        let info = try await client.getApplicationInfo()
        #expect(!info.name.isEmpty)
        // Parameters schema varies by deployment; treat decode failure as non-fatal for integration.
        _ = try? await client.getApplicationParameters()
        let site = try await client.getApplicationWebAppSettings()
        #expect(!site.title.isEmpty)
    }

    @Test("Run workflow (blocking) and fetch run detail")
    func testRunWorkflowBlockingAndDetail() async throws {
        let client = try Self.makeClient()
        let params = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: params)
        let user = makeUserId()
        let traceId = makeTraceId()

        let resp = try await client.runWorkflow(inputs: inputs, user: user, files: nil, traceId: traceId)
        #expect(!resp.workflowRunId.isEmpty)
        #expect(!resp.taskId.isEmpty)
        #expect(!resp.data.id.isEmpty)
        #expect(!resp.data.status.isEmpty)

        // Fetch run detail
        let detail = try await client.getWorkflowRunDetail(workflowRunId: resp.workflowRunId)
        #expect(detail.id == resp.data.id)
        #expect(detail.workflowId == resp.data.workflowId)
    }

    @Test("Run workflow by ID (blocking)")
    func testRunWorkflowByIdBlocking() async throws {
        let client = try Self.makeClient()
        let params = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: params)
        let user = makeUserId()

        // Discover a workflowId by doing one run first
        let probe = try await client.runWorkflow(inputs: inputs, user: user)
        let workflowId = probe.data.workflowId
        #expect(!workflowId.isEmpty)

        let run = try await client.runWorkflow(workflowId: workflowId, inputs: inputs, user: user)
        #expect(!run.workflowRunId.isEmpty)
        #expect(run.data.workflowId == workflowId)
    }

    @Test("Run workflow (streaming) yields start and finish events")
    func testRunWorkflowStreamingBasic() async throws {
        let client = try Self.makeClient()
        let params = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: params)
        let user = makeUserId()

        let stream = try await client.runStreamingWorkflow(inputs: inputs, user: user)

        var sawStarted = false
        var sawFinished = false
        var startedTaskId: String?
        for try await event in stream {
            switch event.kind.rawValue {
            case "workflow_started":
                sawStarted = true
                startedTaskId = event.workflowStarted?.taskId
            case "workflow_finished":
                sawFinished = true
                // End consumption early once we see terminal state
                break
            default:
                break
            }
            if sawFinished { break }
        }
        #expect(sawStarted)
        #expect(sawFinished)

        // Best-effort stop (no-op if already finished); should not throw for 2xx/204
        if let taskId = startedTaskId {
            _ = try? await client.stopWorkflowTask(taskId: taskId, user: user)
        }
    }

    @Test("Run workflow by ID (streaming)")
    func testRunWorkflowByIdStreaming() async throws {
        let client = try Self.makeClient()
        let params = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: params)
        let user = makeUserId()

        // Discover a workflowId
        let probe = try await client.runWorkflow(inputs: inputs, user: user)
        let workflowId = probe.data.workflowId
        #expect(!workflowId.isEmpty)

        let stream = try await client.runStreamingWorkflow(workflowId: workflowId, inputs: inputs, user: user)
        var sawFinish = false
        for try await event in stream {
            if event.kind == .workflowFinished { sawFinish = true; break }
        }
        #expect(sawFinish)
    }

    @Test("Workflow logs listing (first page)")
    func testGetWorkflowLogsListing() async throws {
        let client = try Self.makeClient()
        // Trigger at least one run to ensure there is something to list
        let params = try? await client.getApplicationParameters()
        let inputs = buildInputs(from: params)
        _ = try? await client.runWorkflow(inputs: inputs, user: makeUserId())

        let logs = try await client.getWorkflowLogs(page: 1, limit: 5)
        #expect(logs.page == 1)
        #expect(logs.limit == 5)
        #expect(logs.data.count <= 5)
    }

    @Test("Run workflow with file attachment when allowed")
    func testRunWorkflowWithFileAttachmentIfEnabled() async throws {
        let client = try Self.makeClient()
        let params = try? await client.getApplicationParameters()
        guard let allowance = allowedLocalUploadCategory(params) else {
            // App does not accept local file uploads; silently pass this optional test
            return
        }

        // Upload a tiny file via CompletionClient (shared /files/upload endpoint)
        let uploader = try Self.makeCompletionClient()
        let user = makeUserId()
        let fileData = Data("workflow integration upload".utf8)
        let uploaded = try await uploader.uploadFile(fileData: fileData, fileName: "wf-it.txt", user: user, mimeType: "text/plain")

        // Build a single APIFile referencing the uploaded artifact
        let fileType = FileType(rawValue: allowance.category)
        let apiFile = APIFile(type: fileType, transferMethod: .localFile, url: nil, uploadFileId: uploaded.id)

        let inputs = buildInputs(from: params)
        let run = try await client.runWorkflow(inputs: inputs, user: user, files: [apiFile])
        #expect(!run.workflowRunId.isEmpty)
    }
}
