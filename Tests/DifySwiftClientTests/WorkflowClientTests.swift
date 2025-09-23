import Foundation
import Testing
@testable import DifySwiftClient

@Suite("WorkflowClient Tests")
final class WorkflowClientTests: DifyTestCase, @unchecked Sendable {
    
    // MARK: - Run Workflow Tests
    
    @Test("Run Workflow - Blocking Mode")
    func testRunWorkflow() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register workflow run mock and ensure body contains trace_id and files
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/run",
            headers: nil,
            bodyPattern: "\"trace_id\":\"trace-123\"",
            response: MockResponse.json(MockDataProvider.workflowResponse)
        )
        
        // Run workflow
        let inputs = ["query": "Test input"]
        let response = try await client.runWorkflow(inputs: inputs, user: "test-user")
        
        // Verify response
        #expect(response.workflowRunId == "djflajgkldjgd")
        #expect(response.taskId == "9da23599-e713-473b-982c-4328d4f5c78a")
        #expect(response.data.workflowId == "fldjaslkfjlsda")
        #expect(response.data.outputs?["result"]?.value as? String == "Workflow completed successfully")
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/workflows/run",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    @Test("Run Streaming Workflow")
    func testRunStreamingWorkflow() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register streaming workflow mock
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/run",
            response: MockResponse.streaming(MockDataProvider.streamingWorkflowEvents)
        )
        
        // Run streaming workflow
        let inputs = ["query": "Test streaming"]
        let stream = try await client.runStreamingWorkflow(inputs: inputs, user: "test-user")
        
        // Collect events
        var events: [StreamingWorkflowResponse] = []
        do {
            for try await event in stream {
                events.append(event)
                if events.count >= 4 { // We expect 4 events
                    break
                }
            }
        } catch {
            Issue.record("Failed to parse streaming events: \(error)")
            throw error
        }
        
        // Verify events
        #expect(events.count == 4)
        
        // Verify workflow_started event
        if case .workflowStarted(let event) = events[0] {
            #expect(event.taskId == "5ad4cb98-f0c7-4085-b384-88c403be6290")
            #expect(event.workflowRunId == "5ad498-f0c7-4085-b384-88cbe6290")
        } else {
            Issue.record("Expected workflow_started event")
        }
        
        // Verify node_started event
        if case .nodeStarted(let event) = events[1] {
            #expect(event.data.nodeId == "start-node")
            #expect(event.data.nodeType == "start")
            #expect(event.data.title == "Start")
        } else {
            Issue.record("Expected node_started event")
        }
        
        // Verify node_finished event
        if case .nodeFinished(let event) = events[2] {
            #expect(event.data.nodeId == "start-node")
            #expect(event.data.status == "succeeded")
            #expect(event.data.elapsedTime == 0.324)
        } else {
            Issue.record("Expected node_finished event")
        }
        
        // Verify workflow_finished event
        if case .workflowFinished(let event) = events[3] {
            #expect(event.data.status == "succeeded")
            #expect(event.data.totalTokens == 100)
            #expect(event.data.totalSteps == 1)
            #expect(event.data.outputs?["result"]?.value as? String == "Success")
        } else {
            Issue.record("Expected workflow_finished event")
        }
    }

    @Test("Run Workflow - Blocking Mode with Files and TraceId")
    func testRunWorkflowWithFilesAndTraceId() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()

        // Register workflow run mock
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/run",
            response: MockResponse.json(MockDataProvider.workflowResponse)
        )

        let files = [
            APIFile(type: .image, transferMethod: .remoteUrl, url: "https://example.com/img.png")
        ]
        let traceId = "trace-123"

        // Run workflow
        let inputs = ["query": "Test input"]
        let response = try await client.runWorkflow(inputs: inputs, user: "test-user", files: files, traceId: traceId)

        // Verify response basic fields
        #expect(!response.workflowRunId.isEmpty)

        // Verify request captured
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/workflows/run",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }

    @Test("Run Workflow by ID - Blocking Mode")
    func testRunWorkflowByIdBlocking() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()

        let workflowId = "workflow-abc"
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/\(workflowId)/run",
            response: MockResponse.json(MockDataProvider.workflowResponse)
        )

        let response = try await client.runWorkflow(workflowId: workflowId, inputs: ["query": "hi"], user: "user-1")

        #expect(!response.workflowRunId.isEmpty)

        // Verify request URL
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/workflows/\(workflowId)/run",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }

    @Test("Run Workflow by ID - Streaming Mode")
    func testRunWorkflowByIdStreaming() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()

        let workflowId = "workflow-xyz"
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/\(workflowId)/run",
            headers: nil,
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(MockDataProvider.streamingWorkflowEvents)
        )

        let stream = try await client.runStreamingWorkflow(workflowId: workflowId, inputs: ["query": "stream"], user: "user-2")

        var events: [StreamingWorkflowResponse] = []
        for try await event in stream {
            events.append(event)
            if events.count >= 4 { break }
        }

        #expect(events.count == 4)

        // Verify workflow_run_id exposure on node events
        if case .nodeStarted(let nodeStart) = events[1] {
            #expect(nodeStart.workflowRunId == "5ad498-f0c7-4085-b384-88cbe6290")
        } else { Issue.record("Expected node_started event with workflow_run_id") }

        if case .nodeFinished(let nodeFinish) = events[2] {
            #expect(nodeFinish.workflowRunId == "5ad498-f0c7-4085-b384-88cbe6290")
        } else { Issue.record("Expected node_finished event with workflow_run_id") }
    }
    
    // MARK: - Stop Workflow Tests
    
    @Test("Stop Workflow Task")
    func testStopWorkflowTask() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        let taskId = "test-task-123"
        
        // Register stop task mock
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/tasks/\(taskId)/stop",
            response: MockResponse.json(["result": "success"])
        )
        
        // Stop task
        let response = try await client.stopWorkflowTask(taskId: taskId, user: "test-user")
        
        // Verify response
        #expect(response.result == "success")
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/workflows/tasks/\(taskId)/stop",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    // MARK: - Workflow Run Detail Tests
    
    @Test("Get Workflow Run Detail")
    func testGetWorkflowRunDetail() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        let workflowId = "test-workflow-123"
        
        // Register workflow run detail mock
        let mockDetail: [String: Any] = [
            "id": workflowId,
            "workflow_id": "base-workflow-id",
            "status": "succeeded",
            "inputs": ["query": "test input"],
            "outputs": ["result": "test output"],
            "error": NSNull(),
            "total_steps": 5,
            "total_tokens": 250,
            "created_at": 1679586595,
            "finished_at": 1679586695,
            "elapsed_time": 0.875
        ]
        
        mockSession.register(
            method: "GET",
            urlPattern: "/workflows/run/\(workflowId)",
            response: MockResponse.json(mockDetail)
        )
        
    // Get workflow run detail
    let response = try await client.getWorkflowRunDetail(workflowRunId: workflowId)
        
        // Verify response
        #expect(response.id == workflowId)
        #expect(response.workflowId == "base-workflow-id")
        #expect(response.status == "succeeded")
        #expect(response.totalSteps == 5)
        #expect(response.totalTokens == 250)
        #expect(response.inputs?["query"]?.value as? String == "test input")
        #expect(response.outputs?["result"]?.value as? String == "test output")
        #expect(response.finishedAt == 1679586695)
    }
    
    // MARK: - Workflow Logs Tests
    
    @Test("Get Workflow Logs")
    func testGetWorkflowLogs() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register workflow logs mock
        mockSession.register(
            method: "GET",
            urlPattern: "/workflows/logs",
            response: MockResponse.json(MockDataProvider.workflowLogs)
        )
        
        // Get workflow logs
        let response = try await client.getWorkflowLogs(
            keyword: "test",
            status: "succeeded",
            page: 1,
            limit: 20
        )
        
        // Verify response
        #expect(response.page == 1)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.hasMore == false)
        #expect(response.data.count == 1)
        
        // Verify log entry
        let logEntry = response.data[0]
        #expect(logEntry.id == "e41b93f1-7ca2-40fd-b3a8-999aeb499cc0")
        #expect(logEntry.workflowRun.status == "succeeded")
        #expect(logEntry.workflowRun.elapsedTime == 1.358)
        
        // Verify request parameters
        let capturedRequests = mockSession.getCapturedRequests()
        let logsRequest = capturedRequests.first { $0.url?.absoluteString.contains("/workflows/logs") ?? false }
        #expect(logsRequest != nil)
        
        if let url = logsRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            #expect(queryItems.contains { $0.name == "keyword" && $0.value == "test" })
            #expect(queryItems.contains { $0.name == "status" && $0.value == "succeeded" })
            #expect(queryItems.contains { $0.name == "page" && $0.value == "1" })
            #expect(queryItems.contains { $0.name == "limit" && $0.value == "20" })
        }
    }
    
    @Test("Get Workflow Logs with Filters")
    func testGetWorkflowLogsWithFilters() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register workflow logs mock
        mockSession.register(
            method: "GET",
            urlPattern: "/workflows/logs",
            response: MockResponse.json(MockDataProvider.workflowLogs)
        )
        
        // Get workflow logs with all filters
        let response = try await client.getWorkflowLogs(
            keyword: "search",
            status: "failed",
            page: 2,
            limit: 50,
            createdByEndUserSessionId: "session-123",
            createdByAccount: "user@example.com"
        )
        
        // Verify response structure
        #expect(response.page == 1) // Mock always returns page 1
        #expect(response.data.count == 1)
        
        // Verify all parameters were sent
        let capturedRequests = mockSession.getCapturedRequests()
        let logsRequest = capturedRequests.first { $0.url?.absoluteString.contains("/workflows/logs") ?? false }
        #expect(logsRequest != nil)
        
        if let url = logsRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            #expect(queryItems.contains { $0.name == "keyword" && $0.value == "search" })
            #expect(queryItems.contains { $0.name == "status" && $0.value == "failed" })
            #expect(queryItems.contains { $0.name == "page" && $0.value == "2" })
            #expect(queryItems.contains { $0.name == "limit" && $0.value == "50" })
            #expect(queryItems.contains { $0.name == "created_by_end_user_session_id" && $0.value == "session-123" })
            #expect(queryItems.contains { $0.name == "created_by_account" && $0.value == "user@example.com" })
        }
    }
    
    // MARK: - Application Info Tests
    
    @Test("Get Application Info")
    func testGetApplicationInfo() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register application info mock
        mockSession.register(
            method: "GET",
            urlPattern: "/info",
            response: MockResponse.json(MockDataProvider.applicationInfo)
        )
        
        // Get application info
        let response = try await client.getApplicationInfo()
        
        // Verify response
        #expect(response.name == "My Dify App")
        #expect(response.description == "This is a test application")
        #expect(response.mode == "chat")
    }
    
    @Test("Get Application Parameters")
    func testGetApplicationParameters() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register application parameters mock
        mockSession.register(
            method: "GET",
            urlPattern: "/parameters",
            response: MockResponse.json(MockDataProvider.applicationParameters)
        )
        
        // Get application parameters
        let response = try await client.getApplicationParameters()
        
        // Verify response
        #expect(response.userInputForm?.count == 0)
        #expect(response.fileUpload?.image?.enabled == true)
        #expect(response.fileUpload?.image?.numberLimits == 3)
        #expect(response.fileUpload?.image?.transferMethods.contains("remote_url") == true)
    }
    
    @Test("Get Application WebApp Settings")
    func testGetApplicationWebAppSettings() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register web app settings mock
        let mockSettings: [String: Any] = [
            "title": "My Workflow App",
            "icon_type": "emoji",
            "icon": "🤖",
            "icon_background": "#7C3AED",
            "description": "A powerful workflow application",
            "copyright": "© 2024 MyCompany",
            "privacy_policy": "https://example.com/privacy",
            "custom_disclaimer": "This is a test application",
            "default_language": "en-US",
            "prompt_public": false,
            "retriever_resource": [
                "enabled": true
            ],
            "annotation_reply": [
                "enabled": false
            ],
            "show_workflow_steps": true,
            "use_icon_as_answer_icon": false
        ]
        
        mockSession.register(
            method: "GET",
            urlPattern: "/site",
            response: MockResponse.json(mockSettings)
        )
        
        // Get web app settings
        let response = try await client.getApplicationWebAppSettings()
        
        // Verify response
        #expect(response.title == "My Workflow App")
        #expect(response.iconType == "emoji")
        #expect(response.icon == "🤖")
        #expect(response.iconBackground == "#7C3AED")
        #expect(response.description == "A powerful workflow application")
        #expect(response.copyright == "© 2024 MyCompany")
        #expect(response.privacyPolicy == "https://example.com/privacy")
        #expect(response.customDisclaimer == "This is a test application")
        #expect(response.defaultLanguage == "en-US")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Run Workflow - Network Error")
    func testRunWorkflowNetworkError() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register network error mock
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/run",
            response: MockResponse.error(
                statusCode: 500,
                code: "internal_server_error",
                message: "Internal server error"
            )
        )
        
        // Attempt to run workflow
        await assertThrowsError({
            _ = try await client.runWorkflow(inputs: ["query": "test"], user: "test-user")
        }, expectedError: DifyError(message: "HTTP error: Internal server error", code: nil, status: 500))
    }
    
    @Test("Run Streaming Workflow - Invalid Event")
    func testRunStreamingWorkflowInvalidEvent() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register streaming mock with invalid event
        let invalidEvents = [
            #"data: {"event": "unknown_event", "data": {}}"#
        ]
        
        mockSession.register(
            method: "POST",
            urlPattern: "/workflows/run",
            response: MockResponse.streaming(invalidEvents)
        )
        
        // Run streaming workflow
        let stream = try await client.runStreamingWorkflow(inputs: ["query": "test"], user: "test-user")
        
        // Expect decoding error
        do {
            for try await _ in stream {
                // Should throw before getting here
            }
            Issue.record("Expected decoding error for unknown event type")
        } catch {
            // Expected error - wrapped as DifyError
            if let difyError = error as? DifyError {
                #expect(difyError.message?.contains("Failed to decode response") == true)
            } else {
                Issue.record("Expected DifyError but got \(type(of: error)): \(error)")
            }
        }
    }
    
    @Test("Get Workflow Logs - Empty Response")
    func testGetWorkflowLogsEmptyResponse() async throws {
        let (client, mockSession) = TestUtilities.createTestWorkflowClientWithMockSession()
        
        // Register empty logs mock
        let emptyLogs: [String: Any] = [
            "page": 1,
            "limit": 20,
            "total": 0,
            "has_more": false,
            "data": []
        ]
        
        mockSession.register(
            method: "GET",
            urlPattern: "/workflows/logs",
            response: MockResponse.json(emptyLogs)
        )
        
        // Get workflow logs
        let response = try await client.getWorkflowLogs()
        
        // Verify empty response
        #expect(response.total == 0)
        #expect(response.hasMore == false)
        #expect(response.data.isEmpty)
    }
}