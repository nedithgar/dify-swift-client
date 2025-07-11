import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("WorkflowClient Tests")
struct WorkflowClientTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - Workflow Execution Tests
    
    @Test("Run workflow with simple inputs")
    func testRunWorkflowWithSimpleInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.runWorkflow(
            inputs: ["query": "Hello world", "context": "test"],
            user: "test-user"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
        #expect(response.taskId == "task-123")
        #expect(response.data.status == "succeeded")
    }
    
    @Test("Run workflow with complex inputs")
    func testRunWorkflowWithComplexInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let complexInputs: [String: Any] = [
            "query": "Test query",
            "numbers": [1, 2, 3, 4, 5],
            "metadata": [
                "version": "1.0",
                "enabled": true,
                "config": [
                    "nested": "value"
                ]
            ],
            "files": [
                [
                    "name": "document.pdf",
                    "size": 1024
                ]
            ]
        ]
        
        let response = try await client.runWorkflow(
            inputs: complexInputs,
            user: "test-user"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
        #expect(response.data.status == "succeeded")
    }
    
    @Test("Run workflow with empty inputs")
    func testRunWorkflowWithEmptyInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.runWorkflow(
            inputs: [:],
            user: "test-user"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
    }
    
    @Test("Run workflow with API error")
    func testRunWorkflowWithAPIError() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Invalid workflow configuration")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.runWorkflow(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    @Test("Run workflow with workflow not found error")
    func testRunWorkflowWithWorkflowNotFoundError() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Workflow not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.runWorkflow(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    // MARK: - Streaming Workflow Tests
    
    @Test("Run streaming workflow")
    func testRunStreamingWorkflow() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        // Setup streaming mock
        MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingWorkflowData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try WorkflowClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.runStreamingWorkflow(
            inputs: ["query": "Test workflow"],
            user: "test-user"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream, limit: 2)
        
        #expect(events.count == 2)
    }
    
    @Test("Run streaming workflow with complex inputs")
    func testRunStreamingWorkflowWithComplexInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingWorkflowData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try WorkflowClient(apiKey: "test-api-key", session: streamingSession)
        
        let complexInputs: [String: Any] = [
            "query": "Complex workflow test",
            "parameters": [
                "temperature": 0.7,
                "max_tokens": 1000
            ],
            "files": ["file1.txt", "file2.pdf"]
        ]
        
        let stream = try await streamingClient.runStreamingWorkflow(
            inputs: complexInputs,
            user: "test-user"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream, limit: 2)
        
        #expect(events.count == 2)
    }
    
    @Test("Run streaming workflow with error")
    func testRunStreamingWorkflowWithError() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockStreamingURLProtocol.streamingError = DifyError.networkError(NSError(domain: "Test", code: 0, userInfo: nil))
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try WorkflowClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.runStreamingWorkflow(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        await TestUtilities.assertThrowsAnyError {
            _ = try await TestUtilities.collectStreamItems(stream)
        }
    }
    
    @Test("Run streaming workflow with malformed events")
    func testRunStreamingWorkflowWithMalformedEvents() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockStreamingURLProtocol.streamingData = [
            "data: {\"event\":\"workflow_started\",\"task_id\":\"task-123\",\"workflow_run_id\":\"workflow-run-123\",\"data\":{\"id\":\"workflow-123\",\"workflow_id\":\"workflow-def-123\",\"status\":\"running\",\"elapsed_time\":0.0,\"total_tokens\":0,\"total_steps\":3,\"created_at\":1640995200}}\n",
            "data: {invalid json}\n",
            "data: {\"event\":\"workflow_finished\",\"task_id\":\"task-123\",\"workflow_run_id\":\"workflow-run-123\",\"data\":{\"id\":\"workflow-123\",\"workflow_id\":\"workflow-def-123\",\"status\":\"succeeded\",\"elapsed_time\":1.5,\"total_tokens\":100,\"total_steps\":3,\"created_at\":1640995200,\"finished_at\":1640995201}}\n"
        ]
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try WorkflowClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.runStreamingWorkflow(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream)
        
        // Should receive 2 valid events, malformed event should be ignored
        #expect(events.count == 2)
    }
    
    // MARK: - Stop Workflow Task Tests
    
    @Test("Stop workflow task")
    func testStopWorkflowTask() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.stopWorkflowTask(taskId: "task-123", user: "test-user")
        
        #expect(response.result == "success")
    }
    
    @Test("Stop workflow task with invalid task ID")
    func testStopWorkflowTaskWithInvalidTaskID() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Task not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.stopWorkflowTask(taskId: "invalid-task", user: "test-user")
        }
    }
    
    @Test("Stop workflow task that's already completed")
    func testStopWorkflowTaskAlreadyCompleted() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Task already completed")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.stopWorkflowTask(taskId: "completed-task", user: "test-user")
        }
    }
    
    // MARK: - Workflow Run Detail Tests
    
    @Test("Get workflow run detail")
    func testGetWorkflowRunDetail() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowRunDetail)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowRunDetail(workflowId: "workflow-run-123")
        
        #expect(response.id == "workflow-run-123")
        #expect(response.status == "succeeded")
        #expect(response.totalSteps == 3)
        #expect(response.totalTokens == 100)
    }
    
    @Test("Get workflow run detail with invalid ID")
    func testGetWorkflowRunDetailWithInvalidID() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Workflow run not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getWorkflowRunDetail(workflowId: "invalid-workflow-run")
        }
    }
    
    @Test("Get workflow run detail for running workflow")
    func testGetWorkflowRunDetailForRunningWorkflow() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        var runningWorkflowDetail = MockDataProvider.mockWorkflowRunDetail
        // Create a mock response for running workflow (no finished_at)
        let runningDetail = WorkflowRunDetailResponse(
            id: runningWorkflowDetail.id,
            workflowId: runningWorkflowDetail.workflowId,
            status: "running",
            inputs: runningWorkflowDetail.inputs,
            outputs: nil,
            error: nil,
            totalSteps: runningWorkflowDetail.totalSteps,
            totalTokens: 0,
            createdAt: runningWorkflowDetail.createdAt,
            finishedAt: nil,
            elapsedTime: 0.5
        )
        
        let mockData = MockDataProvider.jsonData(runningDetail)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowRunDetail(workflowId: "workflow-run-123")
        
        #expect(response.status == "running")
        #expect(response.finishedAt == nil)
        #expect(response.outputs == nil)
    }
    
    // MARK: - Workflow Logs Tests
    
    @Test("Get workflow logs with default parameters")
    func testGetWorkflowLogsWithDefaultParameters() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowLogs)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowLogs()
        
        #expect(response.page == 1)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.data.count == 1)
        #expect(response.data[0].workflowRun.status == "succeeded")
    }
    
    @Test("Get workflow logs with all parameters")
    func testGetWorkflowLogsWithAllParameters() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowLogs)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowLogs(
            keyword: "test",
            status: "succeeded",
            page: 2,
            limit: 10,
            createdByEndUserSessionId: "session-123",
            createdByAccount: "user@example.com"
        )
        
        #expect(response.data.count == 1)
    }
    
    @Test("Get workflow logs with keyword filter")
    func testGetWorkflowLogsWithKeywordFilter() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowLogs)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowLogs(keyword: "search term")
        
        #expect(response.data.count == 1)
    }
    
    @Test("Get workflow logs with status filter")
    func testGetWorkflowLogsWithStatusFilter() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowLogs)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowLogs(status: "failed")
        
        #expect(response.data.count == 1)
    }
    
    @Test("Get workflow logs with pagination")
    func testGetWorkflowLogsWithPagination() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowLogs)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowLogs(page: 3, limit: 5)
        
        #expect(response.data.count == 1)
        #expect(response.page == 1) // Mock data returns page 1
        #expect(response.limit == 20) // Mock data returns limit 20
    }
    
    @Test("Get workflow logs with no results")
    func testGetWorkflowLogsWithNoResults() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        let emptyLogs = WorkflowLogsResponse(
            page: 1,
            limit: 20,
            total: 0,
            hasMore: false,
            data: []
        )
        
        let mockData = MockDataProvider.jsonData(emptyLogs)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getWorkflowLogs()
        
        #expect(response.data.count == 0)
        #expect(response.total == 0)
    }
    
    // MARK: - Application Information Tests
    
    @Test("Get application info")
    func testGetApplicationInfo() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationInfo)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "Test App")
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test("Get application parameters")
    func testGetApplicationParameters() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationParameters)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationParameters()
        
        #expect(response.openingStatement == "Hello! How can I help you today?")
        #expect(response.userInputForm?.count == 1)
        #expect(response.fileUpload?.image?.enabled == true)
    }
    
    @Test("Get application WebApp settings")
    func testGetApplicationWebAppSettings() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockApplicationWebAppSettings)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.getApplicationWebAppSettings()
        
        #expect(response.title == "Test Workflow App")
        #expect(response.icon == "🔧")
        #expect(response.showWorkflowSteps == true)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle nil values in inputs")
    func testHandleNilValuesInInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let inputsWithNil: [String: Any?] = [
            "query": "Test",
            "optional_field": nil,
            "context": "Some context"
        ]
        
        // Convert to non-optional dictionary
        let cleanInputs = inputsWithNil.compactMapValues { $0 }
        
        let response = try await client.runWorkflow(
            inputs: cleanInputs,
            user: "test-user"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
    }
    
    @Test("Handle nested objects in inputs")
    func testHandleNestedObjectsInInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let nestedInputs: [String: Any] = [
            "query": "Test",
            "config": [
                "level1": [
                    "level2": [
                        "level3": "deep value"
                    ]
                ]
            ],
            "array_of_objects": [
                ["id": 1, "name": "Item 1"],
                ["id": 2, "name": "Item 2"]
            ]
        ]
        
        let response = try await client.runWorkflow(
            inputs: nestedInputs,
            user: "test-user"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
    }
    
    @Test("Handle special characters in user ID")
    func testHandleSpecialCharactersInUserID() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.runWorkflow(
            inputs: ["query": "Test"],
            user: "user@example.com+test_123"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
    }
    
    @Test("Handle concurrent workflow executions")
    func testHandleConcurrentWorkflowExecutions() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        async let workflow1 = client.runWorkflow(inputs: ["query": "Workflow 1"], user: "user1")
        async let workflow2 = client.runWorkflow(inputs: ["query": "Workflow 2"], user: "user2")
        async let workflow3 = client.runWorkflow(inputs: ["query": "Workflow 3"], user: "user3")
        
        let (response1, response2, response3) = try await (workflow1, workflow2, workflow3)
        
        #expect(response1.workflowRunId == "workflow-run-123")
        #expect(response2.workflowRunId == "workflow-run-123")
        #expect(response3.workflowRunId == "workflow-run-123")
    }
    
    @Test("Handle workflow timeout")
    func testHandleWorkflowTimeout() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 408, message: "Request timeout")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.runWorkflow(
                inputs: ["query": "Long running task"],
                user: "test-user"
            )
        }
    }
    
    @Test("Handle workflow execution limits")
    func testHandleWorkflowExecutionLimits() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 429, message: "Too many requests")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.runWorkflow(
                inputs: ["query": "Test"],
                user: "test-user"
            )
        }
    }
    
    @Test("Handle workflow with error in execution")
    func testHandleWorkflowWithErrorInExecution() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        let errorWorkflowResponse = WorkflowResponse(
            workflowRunId: "workflow-run-123",
            taskId: "task-123",
            data: WorkflowData(
                id: "workflow-123",
                workflowId: "workflow-def-123",
                status: "failed",
                outputs: nil,
                error: "Workflow execution failed",
                elapsedTime: 1.5,
                totalTokens: 50,
                totalSteps: 3,
                createdAt: 1640995200,
                finishedAt: 1640995201
            )
        )
        
        let mockData = MockDataProvider.jsonData(errorWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.runWorkflow(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        #expect(response.data.status == "failed")
        #expect(response.data.error == "Workflow execution failed")
    }
    
    @Test("Handle large workflow inputs")
    func testHandleLargeWorkflowInputs() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockWorkflowResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        var largeInputs: [String: Any] = [:]
        for i in 0..<1000 {
            largeInputs["key\(i)"] = "value\(i)"
        }
        largeInputs["large_text"] = String(repeating: "A", count: 10000)
        
        let response = try await client.runWorkflow(
            inputs: largeInputs,
            user: "test-user"
        )
        
        #expect(response.workflowRunId == "workflow-run-123")
    }
    
    @Test("Handle malformed workflow logs response")
    func testHandleMalformedWorkflowLogsResponse() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        let malformedJSON = Data("{ invalid json }".utf8)
        
        MockURLProtocol.setMockResponse(data: malformedJSON, statusCode: 200)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.getWorkflowLogs()
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Handle streaming workflow with many events")
    func testHandleStreamingWorkflowWithManyEvents() async throws {
        let client = try TestUtilities.createMockWorkflowClient()
        
        var streamingData: [String] = []
        streamingData.append("data: {\"event\":\"workflow_started\",\"task_id\":\"task-123\",\"workflow_run_id\":\"workflow-run-123\",\"data\":{\"id\":\"workflow-123\",\"workflow_id\":\"workflow-def-123\",\"status\":\"running\",\"elapsed_time\":0.0,\"total_tokens\":0,\"total_steps\":100,\"created_at\":1640995200}}\n")
        
        for i in 0..<100 {
            streamingData.append("data: {\"event\":\"node_started\",\"task_id\":\"task-123\",\"data\":{\"id\":\"node-\(i)\",\"node_id\":\"node-\(i)\",\"node_type\":\"llm\",\"index\":\(i),\"title\":\"Node \(i)\",\"status\":\"running\",\"created_at\":1640995200}}\n")
            streamingData.append("data: {\"event\":\"node_finished\",\"task_id\":\"task-123\",\"data\":{\"id\":\"node-\(i)\",\"node_id\":\"node-\(i)\",\"node_type\":\"llm\",\"index\":\(i),\"title\":\"Node \(i)\",\"status\":\"succeeded\",\"created_at\":1640995200}}\n")
        }
        
        streamingData.append("data: {\"event\":\"workflow_finished\",\"task_id\":\"task-123\",\"workflow_run_id\":\"workflow-run-123\",\"data\":{\"id\":\"workflow-123\",\"workflow_id\":\"workflow-def-123\",\"status\":\"succeeded\",\"elapsed_time\":10.5,\"total_tokens\":1000,\"total_steps\":100,\"created_at\":1640995200,\"finished_at\":1640995210}}\n")
        
        MockStreamingURLProtocol.streamingData = streamingData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try WorkflowClient(apiKey: "test-api-key", session: streamingSession)
        
        let stream = try await streamingClient.runStreamingWorkflow(
            inputs: ["query": "Test"],
            user: "test-user"
        )
        
        let events = try await TestUtilities.collectStreamItems(stream)
        
        #expect(events.count == 201) // 1 workflow_started + 100 node_started + 100 node_finished + 1 workflow_finished
    }
}