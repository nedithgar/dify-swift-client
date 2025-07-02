import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Advanced Completion Client Mock Tests

@Suite("Advanced Completion Client Mock Tests")
struct AdvancedCompletionClientMockTests {
    
    @Test("Completion message creation with blocking mode")
    func testCreateCompletionMessageBlocking() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        await MockRequestCapture.startCapturing()
        defer { await MockRequestCapture.stopCapturing() }
        
        let response = try await client.createCompletionMessage(
            inputs: ["prompt": "Write a story about", "topic": "artificial intelligence"],
            responseMode: .blocking,
            user: MockTestConfig.user
        )
        
        // Validate response
        #expect(response.messageId == MockDataProvider.testMessageId)
        #expect(response.answer == "Based on your input, here's my response...")
        #expect(response.createdAt == 1726139644)
        
        // Validate request
        let requests = await MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "completion-messages",
            expectedMethod: "POST"
        )
        
        // Validate request body
        struct ExpectedRequest: Codable {
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
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.inputs["prompt"] == "Write a story about")
        #expect(requestBody.inputs["topic"] == "artificial intelligence")
        #expect(requestBody.responseMode == .blocking)
        #expect(requestBody.user == MockTestConfig.user)
        #expect(requestBody.files == nil)
    }
    
    @Test("Completion message creation with streaming mode")
    func testCreateCompletionMessageStreaming() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        await MockRequestCapture.startCapturing()
        defer { await MockRequestCapture.stopCapturing() }
        
        let response = try await client.createCompletionMessage(
            inputs: ["query": "Generate a poem"],
            responseMode: .streaming,
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
        
        // Validate that streaming mode was requested
        let requests = await MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "completion-messages",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable {
            let responseMode: ResponseMode
            
            private enum CodingKeys: String, CodingKey {
                case responseMode = "response_mode"
            }
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.responseMode == .streaming)
    }
    
    @Test("Completion message with files")
    func testCreateCompletionMessageWithFiles() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let files = [
            TestUtilities.createTestAPIFileRemote(),
            TestUtilities.createTestAPIFileLocal()
        ]
        
        let response = try await client.createCompletionMessage(
            inputs: ["context": "Analyze the following files"],
            responseMode: .blocking,
            user: MockTestConfig.user,
            files: files
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
        
        // Verify files were included in request
        await MockRequestCapture.startCapturing()
        defer { await MockRequestCapture.stopCapturing() }
        
        _ = try await client.createCompletionMessage(
            inputs: ["context": "Test"],
            responseMode: .blocking,
            user: MockTestConfig.user,
            files: files
        )
        
        let requests = await MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "completion-messages",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable {
            let files: [APIFile]?
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.files?.count == 2)
    }
    
    @Test("Streaming completion message creation")
    func testCreateStreamingCompletionMessage() async throws {
        defer { await TestUtilities.cleanup() }
        
        // Setup streaming mock for completion
        let streamingEvents = [
            [
                "event": "message",
                "message_id": MockDataProvider.testMessageId,
                "answer": "Once",
                "created_at": 1726139644
            ],
            [
                "event": "message",
                "message_id": MockDataProvider.testMessageId,
                "answer": " upon a time",
                "created_at": 1726139644
            ],
            [
                "event": "message_end",
                "message_id": MockDataProvider.testMessageId,
                "metadata": [
                    "usage": [
                        "prompt_tokens": 10,
                        "completion_tokens": 20,
                        "total_tokens": 30
                    ]
                ],
                "created_at": 1726139644
            ]
        ]
        
        await TestUtilities.setupStreamingMock(endpoint: "completion-messages", events: streamingEvents)
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let streamingResponse = try await client.createStreamingCompletionMessage(
            inputs: ["story_prompt": "fairy tale"],
            user: MockTestConfig.user
        )
        
        let collectedData = try await TestUtilities.collectStreamingData(
            from: streamingResponse,
            limit: 3
        )
        
        #expect(collectedData.count > 0)
        
        // Verify that streaming data contains expected events
        let firstChunk = collectedData.first!
        let dataString = String(data: firstChunk, encoding: .utf8) ?? ""
        #expect(dataString.contains("message"))
        #expect(dataString.contains(MockDataProvider.testMessageId))
    }
    
    @Test("Streaming completion with files")
    func testStreamingCompletionWithFiles() async throws {
        defer { await TestUtilities.cleanup() }
        
        let streamingEvents = [
            [
                "event": "message",
                "message_id": MockDataProvider.testMessageId,
                "answer": "Based on the provided files",
                "created_at": 1726139644
            ]
        ]
        
        await TestUtilities.setupStreamingMock(endpoint: "completion-messages", events: streamingEvents)
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let files = [TestUtilities.createTestAPIFileRemote()]
        
        let streamingResponse = try await client.createStreamingCompletionMessage(
            inputs: ["task": "summarize"],
            user: MockTestConfig.user,
            files: files
        )
        
        let collectedData = try await TestUtilities.collectStreamingData(
            from: streamingResponse,
            limit: 1
        )
        
        #expect(collectedData.count > 0)
    }
}

// MARK: - Completion Client Error Handling Tests

@Suite("Completion Client Error Handling Tests")
struct CompletionClientErrorHandlingTests {
    
    @Test("Handle invalid inputs error")
    func testInvalidInputsError() async throws {
        await MockURLProtocol.registerMock(
            endpoint: "completion-messages",
            response: MockURLProtocol.MockResponse.httpError(
                statusCode: 400,
                message: "Invalid input parameters"
            )
        )
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createCompletionMessage(
                inputs: [:], // Empty inputs might be invalid
                responseMode: .blocking,
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle quota exceeded error")
    func testQuotaExceededError() async throws {
        await MockURLProtocol.registerMock(
            endpoint: "completion-messages",
            response: MockURLProtocol.MockResponse.httpError(
                statusCode: 403,
                message: "Quota exceeded"
            )
        )
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createCompletionMessage(
                inputs: ["prompt": "test"],
                responseMode: .blocking,
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle model not available error")
    func testModelNotAvailableError() async throws {
        await MockURLProtocol.registerMock(
            endpoint: "completion-messages",
            response: MockURLProtocol.MockResponse.httpError(
                statusCode: 503,
                message: "Model temporarily unavailable"
            )
        )
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createCompletionMessage(
                inputs: ["prompt": "test"],
                responseMode: .blocking,
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle timeout during streaming")
    func testStreamingTimeout() async throws {
        // Setup a mock that takes too long to respond
        await MockURLProtocol.setRequestHandler { request in
            if request.url?.path.contains("completion-messages") == true {
                // Simulate a slow response
                Thread.sleep(forTimeInterval: 0.1)
                return nil // Will trigger timeout
            }
            return nil
        }
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        // This test depends on the implementation handling timeouts appropriately
        let streamingResponse = try await client.createStreamingCompletionMessage(
            inputs: ["prompt": "test"],
            user: MockTestConfig.user
        )
        
        // Try to collect data with a short timeout
        do {
            let _ = try await TestUtilities.withTimeout(1.0) {
                return try await TestUtilities.collectStreamingData(
                    from: streamingResponse,
                    limit: 1
                )
            }
        } catch {
            // Expected timeout or similar error
            #expect(error is TestError)
        }
    }
}

// MARK: - Completion Client Performance Tests

@Suite("Completion Client Performance Tests")
struct CompletionClientPerformanceTests {
    
    @Test("Measure completion response time")
    func testCompletionResponseTime() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let (result, duration) = try await TestUtilities.measureTime {
            return try await client.createCompletionMessage(
                inputs: ["prompt": "Generate a short response"],
                responseMode: .blocking,
                user: MockTestConfig.user
            )
        }
        
        #expect(result.messageId == MockDataProvider.testMessageId)
        #expect(duration < 1.0) // Should be fast with mocks
    }
    
    @Test("Handle multiple concurrent completion requests")
    func testConcurrentCompletionRequests() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let results = try await TestUtilities.runConcurrentOperations(count: 10) { index in
            try await client.createCompletionMessage(
                inputs: ["prompt": "Request \(index)", "index": "\(index)"],
                responseMode: .blocking,
                user: MockTestConfig.user
            )
        }
        
        #expect(results.count == 10)
        for result in results {
            #expect(result.messageId == MockDataProvider.testMessageId)
            #expect(result.answer == "Based on your input, here's my response...")
        }
    }
    
    @Test("Handle large completion inputs")
    func testLargeCompletionInputs() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        // Create large input content
        let largeContent = String(repeating: "This is a very long text input. ", count: 1000)
        let manyInputs = Dictionary(uniqueKeysWithValues: (0..<50).map { 
            ("input_\($0)", "value_\($0)")
        })
        
        var allInputs = manyInputs
        allInputs["large_content"] = largeContent
        
        let response = try await client.createCompletionMessage(
            inputs: allInputs,
            responseMode: .blocking,
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
}

// MARK: - Completion Client Edge Cases Tests

@Suite("Completion Client Edge Cases Tests")
struct CompletionClientEdgeCasesTests {
    
    @Test("Handle empty inputs")
    func testEmptyInputs() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let response = try await client.createCompletionMessage(
            inputs: [:], // Empty inputs
            responseMode: .blocking,
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
    
    @Test("Handle inputs with nil/null values")
    func testInputsWithSpecialValues() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let response = try await client.createCompletionMessage(
            inputs: [
                "normal_input": "value",
                "empty_input": "",
                "whitespace_input": "   "
            ],
            responseMode: .blocking,
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
    
    @Test("Handle mixed file types")
    func testMixedFileTypes() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let files = [
            APIFile(type: .image, transferMethod: .remoteUrl, url: "https://example.com/image.jpg"),
            APIFile(type: .document, transferMethod: .localFile, uploadFileId: "doc-123"),
            APIFile(type: .audio, transferMethod: .remoteUrl, url: "https://example.com/audio.mp3"),
            APIFile(type: .video, transferMethod: .localFile, uploadFileId: "video-456"),
            APIFile(type: .custom, transferMethod: .remoteUrl, url: "https://example.com/custom.xyz")
        ]
        
        let response = try await client.createCompletionMessage(
            inputs: ["task": "analyze all files"],
            responseMode: .blocking,
            user: MockTestConfig.user,
            files: files
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
    
    @Test("Handle unicode and special characters in inputs")
    func testUnicodeInputs() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        let unicodeInputs = [
            "chinese": "你好世界",
            "arabic": "مرحبا بالعالم",
            "emoji": "🌍🚀💻🎉",
            "mathematical": "∑∞≠∅∈∀∃",
            "mixed": "Café in 中文 with 🎵 and ∑ math"
        ]
        
        let response = try await client.createCompletionMessage(
            inputs: unicodeInputs,
            responseMode: .blocking,
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
    
    @Test("Handle response mode validation")
    func testResponseModeValidation() async throws {
        await TestUtilities.setupStandardMocks()
        defer { await TestUtilities.cleanup() }
        
        let client = try await TestUtilities.createMockCompletionClient()
        
        // Test blocking mode
        let blockingResponse = try await client.createCompletionMessage(
            inputs: ["mode": "blocking"],
            responseMode: .blocking,
            user: MockTestConfig.user
        )
        
        #expect(blockingResponse.messageId == MockDataProvider.testMessageId)
        
        // Test streaming mode
        let streamingResponse = try await client.createCompletionMessage(
            inputs: ["mode": "streaming"],
            responseMode: .streaming,
            user: MockTestConfig.user
        )
        
        #expect(streamingResponse.messageId == MockDataProvider.testMessageId)
    }
}