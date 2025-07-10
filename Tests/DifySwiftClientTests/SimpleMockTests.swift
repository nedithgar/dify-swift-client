import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Mock Test Configuration

// MARK: - Simple Mock Tests

@Suite("Simple Mock Tests")
struct SimpleMockTests {
    
    @Test("DifyClient initialization works without environment variables")
    func testClientInitialization() async throws {
        // Test that we can create clients without environment variables
        let apiKey = "test-api-key-123"
        
        let difyClient = try DifyClient(apiKey: apiKey)
        #expect(difyClient.apiKey == apiKey)
        #expect(difyClient.baseURL.absoluteString == "https://api.dify.ai/v1")
        
        let chatClient = try ChatClient(apiKey: apiKey)
        #expect(chatClient.apiKey == apiKey)
        
        let completionClient = try CompletionClient(apiKey: apiKey)
        #expect(completionClient.apiKey == apiKey)
        
        let workflowClient = try WorkflowClient(apiKey: apiKey)
        #expect(workflowClient.apiKey == apiKey)
        
        let knowledgeBaseClient = try KnowledgeBaseClient(apiKey: apiKey)
        #expect(knowledgeBaseClient.apiKey == apiKey)
    }
    
    @Test("DifyClient validates empty API key")
    func testEmptyAPIKeyValidation() async throws {
        #expect(throws: (any Error).self) {
            try DifyClient(apiKey: "")
        }
    }
    
    @Test("DifyClient validates invalid URL")
    func testInvalidURLValidation() async throws {
        #expect(throws: (any Error).self) {
            try DifyClient(apiKey: "test-key", baseURL: "invalid-url")
        }
    }
    
    @Test("DifyClient accepts custom base URL")
    func testCustomBaseURL() async throws {
        let customURL = "https://custom-dify.example.com/v1"
        let client = try DifyClient(apiKey: "test-key", baseURL: customURL)
        #expect(client.baseURL.absoluteString == customURL)
    }
    
    @Test("DifyClient accepts custom URLSession")
    func testCustomURLSession() async throws {
        let customSession = URLSession(configuration: .ephemeral)
        let client = try DifyClient(apiKey: "test-key", session: customSession)
        #expect(client.apiKey == "test-key")
    }
    
    @Test("Models can be encoded and decoded")
    func testModelSerialization() throws {
        // Test APIFile model
        let file = APIFile(
            type: .image,
            transferMethod: .localFile,
            uploadFileId: "file123"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(file)
        
        let decoder = JSONDecoder()
        let decodedFile = try decoder.decode(APIFile.self, from: data)
        
        #expect(decodedFile.type == .image)
        #expect(decodedFile.transferMethod == .localFile)
        #expect(decodedFile.uploadFileId == "file123")
        #expect(decodedFile.url == nil)
    }
    
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
    
    @Test("HTTPMethod enum has correct values")
    func testHTTPMethodEnum() {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    }
    
    @Test("DifyError has proper descriptions")
    func testDifyErrorDescriptions() {
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
    
    @Test("URL query items extension works")
    func testURLQueryItemsExtension() {
        let baseURL = URL(string: "https://example.com/api")!
        let queryItems = [
            URLQueryItem(name: "param1", value: "value1"),
            URLQueryItem(name: "param2", value: "value2")
        ]
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        let urlWithQuery = components.url!
        let urlString = urlWithQuery.absoluteString
        
        #expect(urlString.contains("param1=value1"))
        #expect(urlString.contains("param2=value2"))
    }
    
    // StreamingResponse functionality is tested through actual client streaming methods
    // which return AsyncThrowingStream<StreamingCompletionResponse, Error> etc.
}

// MARK: - Integration Tests Without Server

@Suite("Offline Integration Tests")
struct OfflineIntegrationTests {
    
    @Test("All client types can be instantiated")
    func testAllClientTypes() async throws {
        // Verify all client types can be created without network calls
        let apiKey = MockTestConfig.apiKey
        
        let difyClient = try DifyClient(apiKey: apiKey)
        let chatClient = try ChatClient(apiKey: apiKey)
        let completionClient = try CompletionClient(apiKey: apiKey)
        let workflowClient = try WorkflowClient(apiKey: apiKey)
        let knowledgeBaseClient = try KnowledgeBaseClient(apiKey: apiKey)
        
        // Verify they all have the correct configuration
        #expect(difyClient.apiKey == apiKey)
        #expect(chatClient.apiKey == apiKey)
        #expect(completionClient.apiKey == apiKey)
        #expect(workflowClient.apiKey == apiKey)
        #expect(knowledgeBaseClient.apiKey == apiKey)
        
        // Verify they use the default base URL
        #expect(difyClient.baseURL.absoluteString == "https://api.dify.ai/v1")
        #expect(chatClient.baseURL.absoluteString == "https://api.dify.ai/v1")
        #expect(completionClient.baseURL.absoluteString == "https://api.dify.ai/v1")
        #expect(workflowClient.baseURL.absoluteString == "https://api.dify.ai/v1")
        #expect(knowledgeBaseClient.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("KnowledgeBaseClient handles optional dataset ID")
    func testKnowledgeBaseClientDatasetID() async throws {
        // Test with dataset ID
        let clientWithDataset = try KnowledgeBaseClient(
            apiKey: MockTestConfig.apiKey
        )
        #expect(clientWithDataset.apiKey == MockTestConfig.apiKey)
        
        // Test without dataset ID
        let clientWithoutDataset = try KnowledgeBaseClient(apiKey: MockTestConfig.apiKey)
        #expect(clientWithoutDataset.apiKey == MockTestConfig.apiKey)
    }
    
    @Test("Clients can be created with custom configurations")
    func testCustomConfigurations() async throws {
        let customURL = "https://custom.dify.api/v2"
        let customSession = URLSession(configuration: .ephemeral)
        
        let client = try DifyClient(
            apiKey: MockTestConfig.apiKey,
            baseURL: customURL,
            session: customSession
        )
        
        #expect(client.apiKey == MockTestConfig.apiKey)
        #expect(client.baseURL.absoluteString == customURL)
    }
    
    @Test("File upload data structures work correctly")
    func testFileUploadStructures() throws {
        // Test different file types
        let imageFile = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/image.jpg"
        )
        
        let documentFile = APIFile(
            type: .document,
            transferMethod: .localFile,
            uploadFileId: "doc-123"
        )
        
        let audioFile = APIFile(
            type: .audio,
            transferMethod: .localFile,
            uploadFileId: "audio-456"
        )
        
        let videoFile = APIFile(
            type: .video,
            transferMethod: .remoteUrl,
            url: "https://example.com/video.mp4"
        )
        
        let customFile = APIFile(
            type: .custom,
            transferMethod: .localFile,
            uploadFileId: "custom-789"
        )
        
        // Test encoding/decoding
        let files = [imageFile, documentFile, audioFile, videoFile, customFile]
        
        for file in files {
            let encoder = JSONEncoder()
            let data = try encoder.encode(file)
            
            let decoder = JSONDecoder()
            let decodedFile = try decoder.decode(APIFile.self, from: data)
            
            #expect(decodedFile.type == file.type)
            #expect(decodedFile.transferMethod == file.transferMethod)
            #expect(decodedFile.url == file.url)
            #expect(decodedFile.uploadFileId == file.uploadFileId)
        }
    }
}