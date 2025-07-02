import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - DifyClient Tests

@Suite("DifyClient Tests")
struct DifyClientTests {
    
    @Test("Initialize with valid API key")
    func testInitialization() async throws {
        let client = try DifyClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize with custom base URL")
    func testInitializationWithCustomBaseURL() async throws {
        let customURL = "https://custom-api.example.com/v1"
        let client = try DifyClient(apiKey: MockTestConfig.apiKey, baseURL: customURL)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString == customURL)
    }
    
    @Test("Initialize with empty API key throws error")
    func testInitializationWithEmptyAPIKey() async throws {
        #expect(throws: (any Error).self) {
            try DifyClient(apiKey: "")
        }
    }
    
    @Test("Initialize with invalid base URL throws error")
    func testInitializationWithInvalidBaseURL() async throws {
        #expect(throws: (any Error).self) {
            try DifyClient(apiKey: MockTestConfig.apiKey, baseURL: "invalid-url")
        }
    }
    
    @Test("Initialize with custom URLSession")
    func testInitializationWithCustomSession() async throws {
        let customSession = URLSession(configuration: .ephemeral)
        let client = try DifyClient(
            apiKey: MockTestConfig.apiKey,
            session: customSession
        )
        #expect(client.apiKey == MockTestConfig.apiKey)
    }
}

// MARK: - CompletionClient Tests

@Suite("CompletionClient Tests")
struct CompletionClientTests {
    
    @Test("Create completion client")
    func testCreateCompletionClient() async throws {
        let client = try CompletionClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Completion client inherits from DifyClient")
    func testCompletionClientInheritance() async throws {
        let client = try CompletionClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString.contains("dify.ai"))
    }
    
    @Test("Create completion message with mock response")
    func testCreateCompletionMessage() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockCompletionClient()
        
        // Test completion message creation
        let response = try await client.createCompletionMessage(
            inputs: ["query": "Test completion"],
            responseMode: .blocking,
            user: MockTestConfig.userId
        )
        
        #expect(response.answer == "This is a mock completion response.")
        #expect(response.messageId == "mock-completion-789")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Create streaming completion message")
    func testCreateStreamingCompletionMessage() async throws {
        // Setup streaming mock
        TestUtilities.setupStreamingMock()
        let client = try TestUtilities.createMockCompletionClient()
        
        // Test streaming completion
        let streamingResponse = try await client.createStreamingCompletionMessage(
            inputs: ["query": "Stream test"],
            user: MockTestConfig.userId
        )
        
        // Verify we can iterate over the streaming response
        var chunkCount = 0
        for try await chunk in streamingResponse {
            chunkCount += 1
            #expect(chunk.count > 0)
            if chunkCount >= 2 { break } // Don't iterate too long in test
        }
        
        #expect(chunkCount > 0)
        
        // Cleanup
        TestUtilities.cleanup()
    }
}

// MARK: - ChatClient Tests

@Suite("ChatClient Tests")
struct ChatClientTests {
    
    @Test("Create chat client")
    func testCreateChatClient() async throws {
        let client = try ChatClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Chat client inherits from DifyClient")
    func testChatClientInheritance() async throws {
        let client = try ChatClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString.contains("dify.ai"))
    }
    
    @Test("Create chat message with mock response")
    func testCreateChatMessage() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockChatClient()
        
        // Test chat message creation
        let response = try await client.createChatMessage(
            inputs: ["context": "test"],
            query: "Hello, how are you?",
            user: MockTestConfig.userId
        )
        
        #expect(response.answer == "This is a mock response from the chat API.")
        #expect(response.messageId == "mock-message-123")
        #expect(response.conversationId == "mock-conversation-456")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Create chat message with files")
    func testCreateChatMessageWithFiles() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockChatClient()
        
        // Create test files
        let imageFile = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/test.jpg"
        )
        
        let documentFile = APIFile(
            type: .document,
            transferMethod: .localFile,
            uploadFileId: "file-123"
        )
        
        // Test chat message with files
        let response = try await client.createChatMessage(
            inputs: [:],
            query: "Analyze these files",
            user: MockTestConfig.userId,
            files: [imageFile, documentFile]
        )
        
        #expect(response.messageId == "mock-message-123")
        #expect(response.answer.contains("mock response"))
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Create streaming chat message")
    func testCreateStreamingChatMessage() async throws {
        // Setup streaming mock
        TestUtilities.setupStreamingMock()
        let client = try TestUtilities.createMockChatClient()
        
        // Test streaming chat
        let streamingResponse = try await client.createStreamingChatMessage(
            inputs: [:],
            query: "Tell me a story",
            user: MockTestConfig.userId
        )
        
        // Verify we can iterate over the streaming response
        var chunkCount = 0
        for try await chunk in streamingResponse {
            chunkCount += 1
            #expect(chunk.count > 0)
            if chunkCount >= 2 { break } // Don't iterate too long in test
        }
        
        #expect(chunkCount > 0)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Get conversations")
    func testGetConversations() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockChatClient()
        
        // Test getting conversations
        let response = try await client.getConversations(user: MockTestConfig.userId)
        
        #expect(response.data.count == 2)
        #expect(response.data[0].name == "Test Conversation 1")
        #expect(response.data[1].name == "Test Conversation 2")
        #expect(response.hasMore == false)
        
        // Cleanup
        TestUtilities.cleanup()
    }
}

// MARK: - WorkflowClient Tests

@Suite("WorkflowClient Tests")
struct WorkflowClientTests {
    
    @Test("Create workflow client")
    func testCreateWorkflowClient() async throws {
        let client = try WorkflowClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Workflow client inherits from DifyClient")
    func testWorkflowClientInheritance() async throws {
        let client = try WorkflowClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString.contains("dify.ai"))
    }
    
    @Test("Run workflow with mock response")
    func testRunWorkflow() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockWorkflowClient()
        
        // Test workflow execution
        let response = try await client.run(
            inputs: ["input_key": "input_value"],
            responseMode: .blocking,
            user: MockTestConfig.userId
        )
        
        #expect(response.workflowRunId == "mock-workflow-run-789")
        #expect(response.taskId == "mock-task-456")
        #expect(response.data.status == "succeeded")
        #expect(response.data.outputs["result"] as? String == "Workflow completed successfully")
        #expect(response.data.elapsedTime == 2.5)
        #expect(response.data.totalSteps == 3)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Get workflow result")
    func testGetWorkflowResult() async throws {
        // Setup mock for workflow result
        MockURLProtocol.registerMock(
            endpoint: "workflows/run",
            response: MockResponse.json(MockDataProvider.workflowResponse)
        )
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        // Test getting workflow result
        let result = try await client.getResult(
            workflowRunId: MockTestConfig.workflowId
        )
        
        #expect(result.workflowRunId == "mock-workflow-run-789")
        #expect(result.data.status == "succeeded")
        
        // Cleanup
        TestUtilities.cleanup()
    }
}

// MARK: - KnowledgeBaseClient Tests

@Suite("KnowledgeBaseClient Tests")
struct KnowledgeBaseClientTests {
    
    @Test("Initialize with dataset ID")
    func testInitializeWithDatasetId() async throws {
        let client = try KnowledgeBaseClient(
            apiKey: MockTestConfig.apiKey,
            datasetId: MockTestConfig.datasetId
        )
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.datasetId == MockTestConfig.datasetId)
    }
    
    @Test("Initialize without dataset ID")
    func testInitializeWithoutDatasetId() async throws {
        let client = try KnowledgeBaseClient(apiKey: MockTestConfig.apiKey)
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.datasetId == nil)
    }
    
    @Test("Knowledge base client inherits from DifyClient")
    func testKnowledgeBaseClientInheritance() async throws {
        let client = try KnowledgeBaseClient(
            apiKey: MockTestConfig.apiKey,
            datasetId: MockTestConfig.datasetId
        )
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString.contains("dify.ai"))
    }
    
    @Test("Create dataset")
    func testCreateDataset() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        // Test dataset creation
        let response = try await client.createDataset(name: "Test Dataset")
        
        #expect(response.id == "mock-dataset-123")
        #expect(response.name == "Mock Dataset")
        #expect(response.description == "A dataset for testing")
        #expect(response.documentCount == 5)
        #expect(response.wordCount == 1000)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("Create document by text")
    func testCreateDocumentByText() async throws {
        // Setup mock
        TestUtilities.setupStandardMocks()
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        // Test document creation by text
        let response = try await client.createDocumentByText(
            name: "Test Document",
            text: "This is test content for the document."
        )
        
        #expect(response.document.id == "mock-document-123")
        #expect(response.document.name == "Test Document")
        #expect(response.document.tokens == 500)
        #expect(response.document.indexingStatus == "completed")
        #expect(response.batch == "mock-batch-789")
        
        // Cleanup
        TestUtilities.cleanup()
    }
}

// MARK: - Error Tests

@Suite("Error Tests")
struct ErrorTests {
    
    @Test("DifyError localized descriptions")
    func testDifyErrorLocalizedDescriptions() throws {
        let invalidURLError = DifyError.invalidURL("test-url")
        #expect(invalidURLError.localizedDescription.contains("Invalid URL: test-url"))
        
        let noDataError = DifyError.noData
        #expect(noDataError.localizedDescription.contains("No data received"))
        
        let httpError = DifyError.httpError(404, "Not Found")
        #expect(httpError.localizedDescription.contains("HTTP error 404"))
        
        let fileNotFoundError = DifyError.fileNotFound("/path/to/file")
        #expect(fileNotFoundError.localizedDescription.contains("File not found: /path/to/file"))
        
        let invalidAPIKeyError = DifyError.invalidAPIKey
        #expect(invalidAPIKeyError.localizedDescription.contains("Invalid API key"))
        
        let missingDatasetIdError = DifyError.missingDatasetId
        #expect(missingDatasetIdError.localizedDescription.contains("Dataset ID is required"))
    }
}

// MARK: - Model Tests

@Suite("Model Tests")
struct ModelTests {
    
    @Test("APIFile encoding and decoding")
    func testAPIFileEncodingDecoding() throws {
        let file = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/image.jpg"
        )
        
        let encoded = try JSONEncoder().encode(file)
        let decoded = try JSONDecoder().decode(APIFile.self, from: encoded)
        
        #expect(decoded.type == .image)
        #expect(decoded.transferMethod == .remoteUrl)
        #expect(decoded.url == "https://example.com/image.jpg")
        #expect(decoded.uploadFileId == nil)
    }
    
    @Test("ResponseMode encoding")
    func testResponseModeEncoding() throws {
        let blockingMode = ResponseMode.blocking
        let streamingMode = ResponseMode.streaming
        
        let blockingEncoded = try JSONEncoder().encode(blockingMode)
        let streamingEncoded = try JSONEncoder().encode(streamingMode)
        
        let blockingString = String(data: blockingEncoded, encoding: .utf8)
        let streamingString = String(data: streamingEncoded, encoding: .utf8)
        
        #expect(blockingString == "\"blocking\"")
        #expect(streamingString == "\"streaming\"")
    }
    
    @Test("ProcessRule with default values")
    func testProcessRuleDefaults() throws {
        let rule = ProcessRule()
        
        #expect(rule.mode == "automatic")
        #expect(rule.rules == nil)
        
        let encoded = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(ProcessRule.self, from: encoded)
        
        #expect(decoded.mode == "automatic")
        #expect(decoded.rules == nil)
    }
    
    @Test("SegmentData initialization")
    func testSegmentDataInitialization() throws {
        let segment = SegmentData(
            content: "Test content",
            answer: "Test answer",
            keywords: ["test", "content"],
            enabled: true
        )
        
        #expect(segment.content == "Test content")
        #expect(segment.answer == "Test answer")
        #expect(segment.keywords == ["test", "content"])
        #expect(segment.enabled == true)
        
        let encoded = try JSONEncoder().encode(segment)
        let decoded = try JSONDecoder().decode(SegmentData.self, from: encoded)
        
        #expect(decoded.content == "Test content")
        #expect(decoded.answer == "Test answer")
        #expect(decoded.keywords == ["test", "content"])
        #expect(decoded.enabled == true)
    }
    
    @Test("FileUploadResponse decoding")
    func testFileUploadResponseDecoding() throws {
        let jsonData = """
        {
            "id": "file_123",
            "name": "test.jpg",
            "size": 1024,
            "extension": "jpg",
            "mime_type": "image/jpeg",
            "created_by": "user_123",
            "created_at": 1234567890
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(FileUploadResponse.self, from: jsonData)
        
        #expect(response.id == "file_123")
        #expect(response.name == "test.jpg")
        #expect(response.size == 1024)
        #expect(response.fileExtension == "jpg")
        #expect(response.mimeType == "image/jpeg")
        #expect(response.createdBy == "user_123")
        #expect(response.createdAt == 1234567890)
    }
}

// MARK: - Utility Tests

@Suite("Utility Tests")
struct UtilityTests {
    
    @Test("URL query items extension")
    func testURLQueryItemsExtension() throws {
        let baseURL = URL(string: "https://example.com/path")!
        let queryItems = [
            URLQueryItem(name: "param1", value: "value1"),
            URLQueryItem(name: "param2", value: "value2")
        ]
        
        let resultURL = baseURL.appendingQueryItems(queryItems)
        
        #expect(resultURL.absoluteString.contains("param1=value1"))
        #expect(resultURL.absoluteString.contains("param2=value2"))
    }
    
    @Test("HTTPMethod raw values")
    func testHTTPMethodRawValues() throws {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    }
}

// MARK: - StreamingResponse Tests

@Suite("StreamingResponse Tests")
struct StreamingResponseTests {
    
    @Test("StreamingResponse can be created")
    func testStreamingResponseCreation() throws {
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        let streamingResponse = StreamingResponse(urlRequest: request, session: .shared)
        
        // Basic test to ensure the type can be created and has expected functionality
        let iterator = streamingResponse.makeAsyncIterator()
        // Just verify the iterator was created - no need to check for nil since it's not optional
        #expect(type(of: iterator) == StreamingResponse.AsyncIterator.self)
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {
    
    @Test("Can create all client types")
    func testCreateAllClientTypes() async throws {
        let apiKey = MockTestConfig.apiKey
        
        // Test that all client types can be created without throwing
        let difyClient = try DifyClient(apiKey: apiKey)
        let chatClient = try ChatClient(apiKey: apiKey)
        let completionClient = try CompletionClient(apiKey: apiKey)
        let workflowClient = try WorkflowClient(apiKey: apiKey)
        let knowledgeBaseClient = try KnowledgeBaseClient(apiKey: apiKey)
        
        // Verify they all have the same API key
        #expect(difyClient.apiKey == apiKey)
        #expect(chatClient.apiKey == apiKey)
        #expect(completionClient.apiKey == apiKey)
        #expect(workflowClient.apiKey == apiKey)
        #expect(knowledgeBaseClient.apiKey == apiKey)
    }
    
    @Test("End-to-end chat workflow with mocking")
    func testEndToEndChatWorkflow() async throws {
        // Setup comprehensive mocks
        TestUtilities.setupStandardMocks()
        
        // Test complete chat workflow
        let client = try TestUtilities.createMockChatClient()
        
        // 1. Create initial chat message
        let initialResponse = try await client.createChatMessage(
            inputs: [:],
            query: "Hello, I need help",
            user: MockTestConfig.userId
        )
        
        #expect(initialResponse.event == "message")
        #expect(initialResponse.conversationId == "mock-conversation-456")
        
        // 2. Continue conversation
        let followUpResponse = try await client.createChatMessage(
            inputs: [:],
            query: "Can you explain more?",
            user: MockTestConfig.userId,
            conversationId: initialResponse.conversationId
        )
        
        #expect(followUpResponse.conversationId == initialResponse.conversationId)
        
        // 3. Get conversations list
        let conversations = try await client.getConversations(user: MockTestConfig.userId)
        #expect(conversations.data.count >= 1)
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("End-to-end workflow execution with mocking")
    func testEndToEndWorkflowExecution() async throws {
        // Setup mocks
        TestUtilities.setupStandardMocks()
        
        let client = try TestUtilities.createMockWorkflowClient()
        
        // Run workflow
        let response = try await client.run(
            inputs: ["data": "test input"],
            responseMode: .blocking,
            user: MockTestConfig.userId
        )
        
        #expect(response.data.status == "succeeded")
        #expect(response.data.outputs.count > 0)
        
        // Get result
        let result = try await client.getResult(
            workflowRunId: response.workflowRunId
        )
        
        #expect(result.data.status == "succeeded")
        
        // Cleanup
        TestUtilities.cleanup()
    }
    
    @Test("APIFile with local file transfer method")
    func testAPIFileLocalFileTransferMethod() throws {
        let file = APIFile(
            type: .image,
            transferMethod: .localFile,
            uploadFileId: "file_123"
        )
        
        #expect(file.type == .image)
        #expect(file.transferMethod == .localFile)
        #expect(file.url == nil)
        #expect(file.uploadFileId == "file_123")
        
        // Test encoding/decoding
        let encoded = try JSONEncoder().encode(file)
        let decoded = try JSONDecoder().decode(APIFile.self, from: encoded)
        
        #expect(decoded.type == .image)
        #expect(decoded.transferMethod == .localFile)
        #expect(decoded.url == nil)
        #expect(decoded.uploadFileId == "file_123")
    }
    
    @Test("Complex ProcessRule creation")
    func testComplexProcessRuleCreation() throws {
        let preProcessingRules = [
            PreProcessingRule(id: "remove_extra_spaces", enabled: true),
            PreProcessingRule(id: "remove_urls_emails", enabled: false)
        ]
        
        let segmentation = Segmentation(separator: "\n", maxTokens: 500)
        
        let rules = ProcessRuleRules(
            preProcessingRules: preProcessingRules,
            segmentation: segmentation
        )
        
        let processRule = ProcessRule(mode: "custom", rules: rules)
        
        #expect(processRule.mode == "custom")
        #expect(processRule.rules?.preProcessingRules.count == 2)
        #expect(processRule.rules?.segmentation.maxTokens == 500)
        
        // Test encoding/decoding
        let encoded = try JSONEncoder().encode(processRule)
        let decoded = try JSONDecoder().decode(ProcessRule.self, from: encoded)
        
        #expect(decoded.mode == "custom")
        #expect(decoded.rules?.preProcessingRules.count == 2)
        #expect(decoded.rules?.segmentation.maxTokens == 500)
    }
}
