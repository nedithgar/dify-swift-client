import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Test Configuration

struct TestConfig {
    static let apiKey = ProcessInfo.processInfo.environment["DIFY_API_KEY"]
    static let baseURL = ProcessInfo.processInfo.environment["DIFY_BASE_URL"]
    static let userId = ProcessInfo.processInfo.environment["DIFY_USER_ID"]
}

// MARK: - DifyClient Tests

@Suite("DifyClient Tests")
struct DifyClientTests {
    
    @Test("Initialize with valid API key")
    func testInitialization() async throws {
        let client = try DifyClient(apiKey: TestConfig.apiKey)
        #expect(client.apiKey == TestConfig.apiKey)
        #expect(client.baseURL.absoluteString == TestConfig.baseURL)
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
            try DifyClient(apiKey: TestConfig.apiKey, baseURL: "invalid-url")
        }
    }
}

// MARK: - CompletionClient Tests

@Suite("CompletionClient Tests")
struct CompletionClientTests {
    
    @Test("Create completion client")
    func testCreateCompletionClient() async throws {
        let client = try CompletionClient(apiKey: TestConfig.apiKey)
        #expect(client.apiKey == TestConfig.apiKey)
        #expect(client.baseURL.absoluteString == TestConfig.baseURL)
    }
    
    @Test("Completion client inherits from DifyClient")
    func testCompletionClientInheritance() async throws {
        let client = try CompletionClient(apiKey: TestConfig.apiKey)
        #expect(client is DifyClient)
    }
}

// MARK: - ChatClient Tests

@Suite("ChatClient Tests")
struct ChatClientTests {
    
    @Test("Create chat client")
    func testCreateChatClient() async throws {
        let client = try ChatClient(apiKey: TestConfig.apiKey)
        #expect(client.apiKey == TestConfig.apiKey)
        #expect(client.baseURL.absoluteString == TestConfig.baseURL)
    }
    
    @Test("Chat client inherits from DifyClient")
    func testChatClientInheritance() async throws {
        let client = try ChatClient(apiKey: TestConfig.apiKey)
        #expect(client is DifyClient)
    }
}

// MARK: - WorkflowClient Tests

@Suite("WorkflowClient Tests")
struct WorkflowClientTests {
    
    @Test("Create workflow client")
    func testCreateWorkflowClient() async throws {
        let client = try WorkflowClient(apiKey: TestConfig.apiKey)
        #expect(client.apiKey == TestConfig.apiKey)
        #expect(client.baseURL.absoluteString == TestConfig.baseURL)
    }
    
    @Test("Workflow client inherits from DifyClient")
    func testWorkflowClientInheritance() async throws {
        let client = try WorkflowClient(apiKey: TestConfig.apiKey)
        #expect(client is DifyClient)
    }
}

// MARK: - KnowledgeBaseClient Tests

@Suite("KnowledgeBaseClient Tests")
struct KnowledgeBaseClientTests {
    
    @Test("Initialize with dataset ID")
    func testInitializeWithDatasetId() async throws {
        let client = try KnowledgeBaseClient(
            apiKey: TestConfig.apiKey,
            datasetId: "dataset_123"
        )
        #expect(client.datasetId == "dataset_123")
        #expect(client.apiKey == TestConfig.apiKey)
    }
    
    @Test("Initialize without dataset ID")
    func testInitializeWithoutDatasetId() async throws {
        let client = try KnowledgeBaseClient(apiKey: TestConfig.apiKey)
        #expect(client.datasetId == nil)
    }
    
    @Test("Knowledge base client inherits from DifyClient")
    func testKnowledgeBaseClientInheritance() async throws {
        let client = try KnowledgeBaseClient(apiKey: TestConfig.apiKey)
        #expect(client is DifyClient)
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
        
        // Basic test to ensure the type can be created
        #expect(streamingResponse.makeAsyncIterator() != nil)
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {
    
    @Test("Can create all client types")
    func testCreateAllClientTypes() async throws {
        let apiKey = TestConfig.apiKey
        
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
