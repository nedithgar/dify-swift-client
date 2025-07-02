import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Advanced Chat Client Mock Tests

@Suite("Advanced Chat Client Mock Tests")
struct AdvancedChatClientMockTests {
    
    @Test("Chat message creation with all parameters")
    func testCreateChatMessageWithAllParameters() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let files = [TestUtilities.createTestAPIFileRemote()]
        let response = try await client.createChatMessage(
            inputs: ["query": "test input"],
            query: "Hello, how are you?",
            user: MockTestConfig.user,
            responseMode: .blocking,
            conversationId: MockTestConfig.conversationId,
            files: files,
            autoGenerateName: false
        )
        
        // Validate response
        #expect(response.messageId == MockDataProvider.testMessageId)
        #expect(response.conversationId == MockDataProvider.testConversationId)
        #expect(response.answer == "Hello! How can I help you today?")
        #expect(response.createdAt == 1726139644)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "chat-messages",
            expectedMethod: "POST"
        )
        
        // Validate request body
        struct ExpectedRequest: Codable, Sendable {
            let inputs: [String: String]
            let query: String
            let user: String
            let responseMode: ResponseMode
            let conversationId: String?
            let files: [APIFile]?
            let autoGenerateName: Bool
            
            private enum CodingKeys: String, CodingKey {
                case inputs, query, user
                case responseMode = "response_mode"
                case conversationId = "conversation_id"
                case files
                case autoGenerateName = "auto_generate_name"
            }
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.inputs["query"] == "test input")
        #expect(requestBody.query == "Hello, how are you?")
        #expect(requestBody.user == MockTestConfig.user)
        #expect(requestBody.responseMode == .blocking)
        #expect(requestBody.conversationId == MockTestConfig.conversationId)
        #expect(requestBody.autoGenerateName == false)
        #expect(requestBody.files?.count == 1)
    }
    
    @Test("Chat message creation with minimal parameters")
    func testCreateChatMessageMinimal() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let response = try await client.createChatMessage(
            inputs: [:],
            query: "Simple query",
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
        #expect(response.answer == "Hello! How can I help you today?")
    }
    
    @Test("Streaming chat message creation")
    func testCreateStreamingChatMessage() async throws {
        defer { TestUtilities.cleanup() }
        
        // Setup streaming mock
        let streamingEvents = MockDataProvider.generateChatStreamingEvents()
        await TestUtilities.setupStreamingMock(endpoint: "chat-messages", events: streamingEvents)
        
        let client = try TestUtilities.createMockChatClient()
        
        let streamingResponse = try await client.createStreamingChatMessage(
            inputs: ["context": "test"],
            query: "Hello",
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
    
    @Test("Get suggested messages")
    func testGetSuggestedMessages() async throws {
        MockURLProtocol.registerMock(
            endpoint: "messages/\(MockDataProvider.testMessageId)/suggested",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.suggestedMessagesResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getSuggestedMessages(
            messageId: MockDataProvider.testMessageId,
            user: MockTestConfig.user
        )
        
        #expect(response.data.count == 3)
        #expect(response.data[0] == "What is the weather like today?")
        #expect(response.data[1] == "Tell me a joke")
        #expect(response.data[2] == "How can I improve my productivity?")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "messages/\(MockDataProvider.testMessageId)/suggested",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        #expect(url.query?.contains("user=\(MockTestConfig.user)") == true)
    }
    
    @Test("Stop message generation")
    func testStopMessage() async throws {
        MockURLProtocol.registerMock(
            endpoint: "chat-messages/task-123/stop",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.stopMessage(
            taskId: "task-123",
            user: MockTestConfig.user
        )
        
        #expect(response.result == "success")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "chat-messages/task-123/stop",
            expectedMethod: "POST"
        )
        
        struct ExpectedStopRequest: Codable {
            let user: String
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedStopRequest.self
        )
        
        #expect(requestBody.user == MockTestConfig.user)
    }
    
    @Test("Get conversations list")
    func testGetConversations() async throws {
        MockURLProtocol.registerMock(
            endpoint: "conversations",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.conversationsResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getConversations(
            user: MockTestConfig.user,
            lastId: "last-123",
            limit: 10,
            pinned: true
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == MockDataProvider.testConversationId)
        #expect(response.data[0].name == "Test Conversation")
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "conversations",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("user=\(MockTestConfig.user)"))
        #expect(query.contains("last_id=last-123"))
        #expect(query.contains("limit=10"))
        #expect(query.contains("pinned=true"))
    }
    
    @Test("Get conversation messages")
    func testGetConversationMessages() async throws {
        MockURLProtocol.registerMock(
            endpoint: "messages",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.conversationMessagesResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let response = try await client.getConversationMessages(
            user: MockTestConfig.user,
            conversationId: MockTestConfig.conversationId,
            firstId: "first-123",
            limit: 50
        )
        
        #expect(response.data.count == 1)
        #expect(response.data[0].id == MockDataProvider.testMessageId)
        #expect(response.data[0].conversationId == MockDataProvider.testConversationId)
        #expect(response.data[0].query == "Hello")
        #expect(response.data[0].answer == "Hi there! How can I help you?")
    }
    
    @Test("Rename conversation")
    func testRenameConversation() async throws {
        MockURLProtocol.registerMock(
            endpoint: "conversations/\(MockDataProvider.testConversationId)/name",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.renameConversation(
            conversationId: MockDataProvider.testConversationId,
            name: "New Conversation Name",
            autoGenerate: false,
            user: MockTestConfig.user
        )
        
        #expect(response.result == "success")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "conversations/\(MockDataProvider.testConversationId)/name",
            expectedMethod: "POST"
        )
        
        struct ExpectedRenameRequest: Codable {
            let name: String
            let autoGenerate: Bool
            let user: String
            
            private enum CodingKeys: String, CodingKey {
                case name
                case autoGenerate = "auto_generate"
                case user
            }
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRenameRequest.self
        )
        
        #expect(requestBody.name == "New Conversation Name")
        #expect(requestBody.autoGenerate == false)
        #expect(requestBody.user == MockTestConfig.user)
    }
    
    @Test("Delete conversation")
    func testDeleteConversation() async throws {
        MockURLProtocol.registerMock(
            endpoint: "conversations/\(MockDataProvider.testConversationId)",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let response = try await client.deleteConversation(
            conversationId: MockDataProvider.testConversationId,
            user: MockTestConfig.user
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Audio to text conversion")
    func testAudioToText() async throws {
        MockURLProtocol.registerMock(
            endpoint: "audio-to-text",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.chatMessageResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let audioData = TestUtilities.createTestAudioData()
        
        let response = try await client.audioToText(
            audioData: audioData,
            filename: "test-audio.wav",
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
        #expect(response.answer == "Hello! How can I help you today?")
    }
    
    @Test("Get conversation variables")
    func testGetConversationVariables() async throws {
        let conversationVariablesResponse: [String: Any] = [
            "limit": 20,
            "has_more": false,
            "data": [
                [
                    "id": "var-123",
                    "name": "user_name",
                    "value_type": "string",
                    "value": "John Doe",
                    "description": "User's name",
                    "created_at": 1726139644,
                    "updated_at": 1726139644
                ]
            ]
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "conversations/\(MockDataProvider.testConversationId)/variables",
            response: MockURLProtocol.MockResponse.json(conversationVariablesResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let response = try await client.getConversationVariables(
            conversationId: MockDataProvider.testConversationId,
            user: MockTestConfig.user,
            lastId: "last-var-456",
            limit: 10
        )
        
        #expect(response.limit == 20)
        #expect(response.hasMore == false)
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "var-123")
        #expect(response.data[0].name == "user_name")
        #expect(response.data[0].value == "John Doe")
    }
}

// MARK: - Chat Client Error Handling Tests

@Suite("Chat Client Error Handling Tests")
struct ChatClientErrorHandlingTests {
    
    @Test("Handle 401 Unauthorized error")
    func testUnauthorizedError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 401, message: "Invalid API key")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle 429 Rate Limit error")
    func testRateLimitError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 429, message: "Rate limit exceeded")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle 500 Server error")
    func testServerError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 500, message: "Internal server error")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle network error")
    func testNetworkError() async throws {
        let networkError = URLError(.notConnectedToInternet)
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse.networkError(networkError)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        await TestUtilities.expectError(URLError.self) {
            try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle malformed JSON response")
    func testMalformedResponse() async throws {
        let malformedData = "Invalid JSON".data(using: .utf8)!
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse(
                statusCode: 200,
                data: malformedData,
                headers: ["Content-Type": "application/json"]
            )
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.user
            )
        }
    }
}

// MARK: - Chat Client Edge Cases Tests

@Suite("Chat Client Edge Cases Tests")
struct ChatClientEdgeCasesTests {
    
    @Test("Handle empty response data")
    func testEmptyResponseData() async throws {
        MockURLProtocol.registerMock(
            endpoint: "chat-messages",
            response: MockURLProtocol.MockResponse(
                statusCode: 200,
                data: Data(),
                headers: ["Content-Type": "application/json"]
            )
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createChatMessage(
                inputs: [:],
                query: "Test",
                user: MockTestConfig.user
            )
        }
    }
    
    @Test("Handle large input parameters")
    func testLargeInputParameters() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        // Create large input data
        let largeText = String(repeating: "A", count: 10000)
        let largeInputs = Dictionary(uniqueKeysWithValues: (0..<100).map { ("key\($0)", "value\($0)") })
        
        let response = try await client.createChatMessage(
            inputs: largeInputs,
            query: largeText,
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
    
    @Test("Handle concurrent chat requests")
    func testConcurrentChatRequests() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let results = try await TestUtilities.runConcurrentOperations(count: 5) { index in
            try await client.createChatMessage(
                inputs: ["index": "\(index)"],
                query: "Concurrent request \(index)",
                user: MockTestConfig.user
            )
        }
        
        #expect(results.count == 5)
        for result in results {
            #expect(result.messageId == MockDataProvider.testMessageId)
        }
    }
    
    @Test("Handle special characters in inputs")
    func testSpecialCharactersInInputs() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockChatClient()
        
        let specialCharInputs = [
            "emoji": "🎉🚀💻",
            "unicode": "Café, naïve, résumé",
            "symbols": "!@#$%^&*()_+-=[]{}|;':\",./<>?",
            "newlines": "Line 1\nLine 2\nLine 3"
        ]
        
        let response = try await client.createChatMessage(
            inputs: specialCharInputs,
            query: "Testing special characters: 你好世界 🌍",
            user: MockTestConfig.user
        )
        
        #expect(response.messageId == MockDataProvider.testMessageId)
    }
}