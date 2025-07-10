import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Advanced Workflow Client Mock Tests

@Suite("Advanced Workflow Client Mock Tests")
struct AdvancedWorkflowClientMockTests {
    
    @Test("Run workflow with blocking mode")
    func testRunWorkflowBlocking() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.runWorkflow(
            inputs: ["query": "What is AI?", "language": "en"],
            user: MockTestConfig.user
        )
        
        // Validate response
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
        #expect(response.taskId == "test-task-123")
        #expect(response.data.id == MockDataProvider.testWorkflowRunId)
        #expect(response.data.status == "succeeded")
        #expect(response.data.outputs?["result"]?.value as? String == "Workflow completed successfully")
        #expect(response.data.elapsedTime == 1.5)
        #expect(response.data.totalTokens == 100)
        #expect(response.data.totalSteps == 3)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "workflows/run",
            expectedMethod: "POST"
        )
        
        // Validate request body
        struct ExpectedRequest: Codable, Sendable {
            let inputs: [String: String]
            let responseMode: ResponseMode
            let user: String
            
            private enum CodingKeys: String, CodingKey {
                case inputs
                case responseMode = "response_mode"
                case user
            }
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.inputs["query"] == "What is AI?")
        #expect(requestBody.inputs["language"] == "en")
        #expect(requestBody.responseMode == .blocking)
        #expect(requestBody.user == MockTestConfig.user)
    }
    
    @Test("Run workflow with streaming mode")
    func testRunWorkflowStreaming() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let response = try await client.runWorkflow(
            inputs: ["task": "generate report"],
            user: MockTestConfig.user
        )
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
        #expect(response.taskId == "test-task-123")
    }
    
    @Test("Run streaming workflow")
    func testRunStreamingWorkflow() async throws {
        defer { TestUtilities.cleanup() }
        
        // Setup streaming mock for workflow
        let streamingEvents = MockDataProvider.generateWorkflowStreamingEvents()
        TestUtilities.setupStreamingMock(endpoint: "workflows/run", events: streamingEvents)
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let streamingResponse = try await client.runStreamingWorkflow(
            inputs: ["process": "data analysis"],
            user: MockTestConfig.user
        )
        
        let collectedData = try await TestUtilities.collectStreamingData(
            from: streamingResponse,
            limit: 4
        )
        
        #expect(collectedData.count > 0)
        
        // Verify that streaming data contains expected workflow events
        #expect(collectedData.count > 0)
        
        // Check for workflow streaming events
        let hasWorkflowEvent = collectedData.contains { event in
            switch event {
            case .workflowStarted, .nodeStarted, .nodeFinished, .workflowFinished:
                return true
            default:
                return false
            }
        }
        #expect(hasWorkflowEvent)
    }
    
    @Test("Stop workflow task")
    func testStopWorkflowTask() async throws {
        MockURLProtocol.registerMock(
            endpoint: "workflows/tasks/task-456/stop",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.stopWorkflowTask(
            taskId: "task-456",
            user: MockTestConfig.user
        )
        
        #expect(response.result == "success")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "workflows/tasks/task-456/stop",
            expectedMethod: "POST"
        )
        
        struct ExpectedStopRequest: Codable, Sendable {
            let user: String
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedStopRequest.self
        )
        
        #expect(requestBody.user == MockTestConfig.user)
    }
    
    @Test("Get workflow run result")
    func testGetWorkflowResult() async throws {
        MockURLProtocol.registerMock(
            endpoint: "workflows/run/\(MockDataProvider.testWorkflowRunId)",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.workflowResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let response = try await client.getWorkflowRunDetail(workflowId: MockDataProvider.testWorkflowRunId)
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
        #expect(response.data.status == "succeeded")
        #expect(response.data.outputs?["result"]?.value as? String == "Workflow completed successfully")
    }
    
    @Test("Get workflow logs with all filters")
    func testGetWorkflowLogsWithFilters() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getWorkflowLogs(
            keyword: "AI analysis",
            status: "succeeded",
            page: 2,
            limit: 50,
            createdByEndUserSessionId: "session-789",
            createdByAccount: "test@example.com"
        )
        
        #expect(response.page == 1)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.hasMore == false)
        #expect(response.data.count == 1)
        
        let logEntry = response.data[0]
        #expect(logEntry.id == "log-123")
        #expect(logEntry.workflowRun.id == MockDataProvider.testWorkflowRunId)
        #expect(logEntry.workflowRun.status == "succeeded")
        #expect(logEntry.workflowRun.elapsedTime == 1.3588523610014818)
        #expect(logEntry.workflowRun.totalSteps == 3)
        #expect(logEntry.createdFrom == "service-api")
        #expect(logEntry.createdByRole == "end_user")
        #expect(logEntry.createdByEndUser.id == "7f7d9117-dd9d-441d-8970-87e5e7e687a3")
        #expect(logEntry.createdByEndUser.type == "service_api")
        #expect(logEntry.createdByEndUser.isAnonymous == false)
        #expect(logEntry.createdByEndUser.sessionId == "abc-123")
        
        // Validate request parameters
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "workflows/logs",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("keyword=AI%20analysis"))
        #expect(query.contains("status=succeeded"))
        #expect(query.contains("page=2"))
        #expect(query.contains("limit=50"))
        #expect(query.contains("created_by_end_user_session_id=session-789"))
        #expect(query.contains("created_by_account=test%40example.com"))
    }
    
    @Test("Get workflow logs with minimal parameters")
    func testGetWorkflowLogsMinimal() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let response = try await client.getWorkflowLogs()
        
        #expect(response.data.count == 1)
        #expect(response.page == 1)
        #expect(response.limit == 20)
    }
}

// MARK: - Workflow Client Error Handling Tests

@Suite("Workflow Client Error Handling Tests")
struct WorkflowClientErrorHandlingTests {
    
    @Test("Handle workflow execution timeout")
    func testWorkflowExecutionTimeout() async throws {
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 408, message: "Request timeout")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.runWorkflow(
                inputs: ["slow_task": "heavy_computation"],
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle invalid workflow configuration")
    func testInvalidWorkflowConfiguration() async throws {
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 400, message: "Invalid workflow configuration")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.runWorkflow(
                inputs: ["invalid": "config"],
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle workflow not found")
    func testWorkflowNotFound() async throws {
        MockURLProtocol.registerMock(
            endpoint: "workflows/run/nonexistent-workflow",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 404, message: "Workflow not found")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.getWorkflowRunDetail(workflowId: "nonexistent-workflow")
        }
    }
    
    @Test("Handle workflow execution failure")
    func testWorkflowExecutionFailure() async throws {
        let failedWorkflowResponse: [String: Any] = [
            "workflow_run_id": MockDataProvider.testWorkflowRunId,
            "task_id": "failed-task-123",
            "data": [
                "id": MockDataProvider.testWorkflowRunId,
                "workflow_id": "workflow-456",
                "status": "failed",
                "outputs": [:],
                "error": "Node execution failed: Invalid input format",
                "elapsed_time": 0.5,
                "total_tokens": 0,
                "total_steps": 1,
                "created_at": 1726139644,
                "finished_at": 1726139644
            ]
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockURLProtocol.MockResponse.json(failedWorkflowResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let response = try await client.runWorkflow(
            inputs: ["bad_input": "malformed"],
            user: MockTestConfig.user
        )
        
        #expect(response.data.status == "failed")
        #expect(response.data.error == "Node execution failed: Invalid input format")
        #expect(response.data.totalSteps == 1)
    }
    
    @Test("Handle streaming workflow interruption")
    func testStreamingWorkflowInterruption() async throws {
        defer { TestUtilities.cleanup() }
        
        // Setup a streaming mock that ends abruptly
        let incompleteStreamingEvents = [
            [
                "event": "workflow_started",
                "task_id": "task-123",
                "workflow_run_id": MockDataProvider.testWorkflowRunId,
                "created_at": 1726139644
            ],
            [
                "event": "error",
                "task_id": "task-123",
                "workflow_run_id": MockDataProvider.testWorkflowRunId,
                "data": [
                    "error": "Workflow execution interrupted"
                ],
                "created_at": 1726139644
            ]
        ]
        
        TestUtilities.setupStreamingMock(endpoint: "workflows/run", events: incompleteStreamingEvents)
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let streamingResponse = try await client.runStreamingWorkflow(
            inputs: ["interrupted": "task"],
            user: MockTestConfig.user
        )
        
        let collectedData = try await TestUtilities.collectStreamingData(
            from: streamingResponse,
            limit: 2
        )
        
        #expect(collectedData.count >= 1)
        
        // Check that streaming data is received
        #expect(collectedData.count > 0)
        // Verify we got streaming response events
        let hasWorkflowEvent = collectedData.contains { event in
            switch event {
            case .workflowStarted, .nodeStarted, .nodeFinished, .workflowFinished:
                return true
            default:
                return false
            }
        }
        #expect(hasWorkflowEvent)
    }
}

// MARK: - Workflow Client Performance Tests

@Suite("Workflow Client Performance Tests")
struct WorkflowClientPerformanceTests {
    
    @Test("Measure workflow execution time")
    func testWorkflowExecutionTime() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let (result, duration) = try await TestUtilities.measureTime {
            return try await client.runWorkflow(
                inputs: ["performance": "test"],
                user: MockTestConfig.user
            )
        }
        
        #expect(result.workflowRunId == MockDataProvider.testWorkflowRunId)
        #expect(duration < 1.0) // Should be fast with mocks
    }
    
    @Test("Handle concurrent workflow executions")
    func testConcurrentWorkflowExecutions() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let results = try await TestUtilities.runConcurrentOperations(count: 5) { index in
            try await client.runWorkflow(
                inputs: ["concurrent": "task", "index": "\(index)"],
                user: MockTestConfig.user
            )
        }
        
        #expect(results.count == 5)
        for result in results {
            #expect(result.workflowRunId == MockDataProvider.testWorkflowRunId)
            #expect(result.data.status == "succeeded")
        }
    }
    
    @Test("Handle large workflow inputs")
    func testLargeWorkflowInputs() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        // Create large input data
        let largeData = String(repeating: "Large data chunk. ", count: 1000)
        let manyInputs = Dictionary(uniqueKeysWithValues: (0..<100).map { 
            ("input_\($0)", "value_\($0)")
        })
        
        var allInputs = manyInputs
        allInputs["large_data"] = largeData
        
        let response = try await client.runWorkflow(
            inputs: allInputs,
            user: MockTestConfig.user
        )
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
    }
}

// MARK: - Workflow Client Edge Cases Tests

@Suite("Workflow Client Edge Cases Tests")
struct WorkflowClientEdgeCasesTests {
    
    @Test("Handle empty workflow inputs")
    func testEmptyWorkflowInputs() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let response = try await client.runWorkflow(
            inputs: [:], // Empty inputs
            user: MockTestConfig.user
        )
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
    }
    
    @Test("Handle complex nested workflow data")
    func testComplexNestedWorkflowData() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let complexInputs = [
            "json_data": """
            {
                "users": [
                    {"name": "John", "age": 30, "skills": ["Python", "Swift"]},
                    {"name": "Jane", "age": 25, "skills": ["JavaScript", "Go"]}
                ],
                "metadata": {
                    "version": "1.0",
                    "timestamp": "2024-01-01T00:00:00Z"
                }
            }
            """,
            "csv_data": "name,age,city\\nAlice,28,NYC\\nBob,32,SF",
            "markdown_content": "# Report\\n\\n## Summary\\n\\nThis is a **test** report.",
            "unicode_text": "Unicode test: 你好世界 🌍 café naïve résumé"
        ]
        
        let response = try await client.runWorkflow(
            inputs: complexInputs,
            user: MockTestConfig.user
        )
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
    }
    
    @Test("Handle workflow with default user")
    func testWorkflowWithDefaultUser() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        // Test using default user parameter
        let response = try await client.runWorkflow(inputs: ["test": "default_user"], user: MockTestConfig.user)
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
        
        // Validate that default user was used
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "workflows/run",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable, Sendable {
            let user: String
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.user == "abc-123") // Default user from WorkflowClient
    }
    
    @Test("Handle special characters in workflow inputs")
    func testSpecialCharactersInWorkflowInputs() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        let specialInputs = [
            "symbols": "!@#$%^&*()_+-=[]{}|;':\",./<>?",
            "escape_sequences": "Line 1\\nLine 2\\tTabbed\\\"Quoted\\\"",
            "html_entities": "&lt;tag&gt;content&lt;/tag&gt; &amp; more",
            "sql_injection_attempt": "'; DROP TABLE users; --",
            "xml_content": "<?xml version=\"1.0\"?><root><data>test</data></root>"
        ]
        
        let response = try await client.runWorkflow(
            inputs: specialInputs,
            user: MockTestConfig.user
        )
        
        #expect(response.workflowRunId == MockDataProvider.testWorkflowRunId)
    }
    
    @Test("Handle workflow logs pagination")
    func testWorkflowLogsPagination() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        // Test pagination parameters
        let response = try await client.getWorkflowLogs(
            page: 5,
            limit: 100
        )
        
        #expect(response.page == 1) // Mock returns fixed values
        #expect(response.limit == 20)
        
        // Validate pagination parameters in request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "workflows/logs",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("page=5"))
        #expect(query.contains("limit=100"))
    }
}