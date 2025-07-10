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
        let client = try DifyClient(apiKey: "test-api-key")
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize with custom base URL")
    func testInitializationWithCustomBaseURL() async throws {
        let customURL = "https://custom-api.example.com/v1"
        let client = try DifyClient(apiKey: "test-api-key", baseURL: customURL)
        #expect(client.apiKey == "test-api-key")
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
            try DifyClient(apiKey: "test-api-key", baseURL: "invalid-url")
        }
    }
    
    @Test("Initialize with custom URLSession")
    func testInitializationWithCustomSession() async throws {
        let customSession = URLSession(configuration: .ephemeral)
        let client = try DifyClient(
            apiKey: "test-api-key",
            session: customSession
        )
        #expect(client.apiKey == "test-api-key")
    }
}

// MARK: - Client Types Tests

@Suite("Client Types Tests")
struct ClientTypesTests {
    
    @Test("Create completion client")
    func testCreateCompletionClient() async throws {
        let client = try CompletionClient(apiKey: "test-api-key")
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create chat client")
    func testCreateChatClient() async throws {
        let client = try ChatClient(apiKey: "test-api-key")
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create workflow client")
    func testCreateWorkflowClient() async throws {
        let client = try WorkflowClient(apiKey: "test-api-key")
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create knowledge base client")
    func testCreateKnowledgeBaseClient() async throws {
        let client = try KnowledgeBaseClient(apiKey: "test-api-key")
        #expect(client.apiKey == "test-api-key")
    }
    
    @Test("Create knowledge base client with custom base URL")
    func testCreateKnowledgeBaseClientWithCustomURL() async throws {
        let client = try KnowledgeBaseClient(apiKey: "test-api-key", baseURL: "https://custom.dify.ai/v1")
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://custom.dify.ai/v1")
    }
}

// MARK: - Model Tests

@Suite("Model Tests")
struct ModelTests {
    
    @Test("FileType enum has correct values")
    func testFileTypeEnum() {
        #expect(FileType.image.rawValue == "image")
        #expect(FileType.document.rawValue == "document")
        #expect(FileType.audio.rawValue == "audio")
        #expect(FileType.video.rawValue == "video")
        #expect(FileType.custom.rawValue == "custom")
    }
    
    @Test("FileTransferMethod enum has correct values")
    func testFileTransferMethodEnum() {
        #expect(FileTransferMethod.localFile.rawValue == "local_file")
        #expect(FileTransferMethod.remoteUrl.rawValue == "remote_url")
    }
    
    @Test("ResponseMode enum has correct values")
    func testResponseModeEnum() {
        #expect(ResponseMode.blocking.rawValue == "blocking")
        #expect(ResponseMode.streaming.rawValue == "streaming")
    }
    
    @Test("APIFile encoding and decoding")
    func testAPIFileEncodingDecoding() throws {
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
        
        #expect(decoded.type == file.type)
        #expect(decoded.transferMethod == file.transferMethod)
        #expect(decoded.url == file.url)
        #expect(decoded.uploadFileId == file.uploadFileId)
    }
    
    @Test("APIFile with remote URL")
    func testAPIFileWithRemoteURL() throws {
        let file = APIFile(
            type: .document,
            transferMethod: .remoteUrl,
            url: "https://example.com/doc.pdf"
        )
        
        #expect(file.type == .document)
        #expect(file.transferMethod == .remoteUrl)
        #expect(file.url == "https://example.com/doc.pdf")
        #expect(file.uploadFileId == nil)
    }
}

// MARK: - Error Tests

@Suite("Error Tests")
struct ErrorTests {
    
    @Test("DifyError localized descriptions")
    func testDifyErrorLocalizedDescriptions() throws {
        let invalidURLError = DifyError.invalidURL()
        #expect(invalidURLError.localizedDescription.contains("Invalid URL"))
        
        let invalidAPIKeyError = DifyError.invalidAPIKey()
        #expect(invalidAPIKeyError.localizedDescription.contains("Invalid API key"))
        
        let noDataError = DifyError.noData()
        #expect(noDataError.localizedDescription.contains("No data"))
        
        let invalidResponseError = DifyError.invalidResponse()
        #expect(invalidResponseError.localizedDescription.contains("Invalid response"))
        
        let missingDatasetError = DifyError.missingDatasetId()
        #expect(missingDatasetError.localizedDescription.contains("Dataset ID"))
        
        let fileNotFoundError = DifyError.fileNotFound("test.txt")
        #expect(fileNotFoundError.localizedDescription.contains("File not found"))
        
        let httpError = DifyError.httpError(404, "Not found")
        #expect(httpError.localizedDescription.contains("HTTP error 404"))
        #expect(httpError.localizedDescription.contains("Not found"))
    }
}

// MARK: - Utility Tests

@Suite("Utility Tests")
struct UtilityTests {
    
    @Test("HTTPMethod raw values")
    func testHTTPMethodRawValues() {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    }
    
    @Test("URL query items extension")
    func testURLQueryItemsExtension() throws {
        let baseURL = URL(string: "https://example.com/path")!
        let queryItems = [
            URLQueryItem(name: "param1", value: "value1"),
            URLQueryItem(name: "param2", value: "value2")
        ]
        
        let urlWithQuery = baseURL.appendingQueryItems(queryItems)
        let urlString = urlWithQuery.absoluteString
        
        #expect(urlString.contains("param1=value1"))
        #expect(urlString.contains("param2=value2"))
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {
    
    @Test("Can create all client types")
    func testCreateAllClientTypes() async throws {
        let apiKey = "test-api-key"
        
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
    
    // StreamingResponse functionality is tested through actual client streaming methods
    // which return AsyncThrowingStream<StreamingCompletionResponse, Error> etc.
}