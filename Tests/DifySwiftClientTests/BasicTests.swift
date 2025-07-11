import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("Basic Tests")
struct BasicTests {
    
    @Test("Initialize DifyClient with valid parameters")
    func testDifyClientInitialization() throws {
        let client = try DifyClient(apiKey: "test-key", baseURL: "https://api.dify.ai/v1")
        
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize DifyClient with invalid API key")
    func testDifyClientInitializationWithInvalidAPIKey() {
        #expect(throws: DifyError.self) {
            try DifyClient(apiKey: "", baseURL: "https://api.dify.ai/v1")
        }
    }
    
    @Test("Initialize DifyClient with invalid URL")
    func testDifyClientInitializationWithInvalidURL() {
        #expect(throws: DifyError.self) {
            try DifyClient(apiKey: "test-key", baseURL: "invalid-url")
        }
    }
    
    @Test("Initialize ChatClient")
    func testChatClientInitialization() throws {
        let client = try ChatClient(apiKey: "test-key", baseURL: "https://api.dify.ai/v1")
        
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize CompletionClient")
    func testCompletionClientInitialization() throws {
        let client = try CompletionClient(apiKey: "test-key", baseURL: "https://api.dify.ai/v1")
        
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize WorkflowClient")
    func testWorkflowClientInitialization() throws {
        let client = try WorkflowClient(apiKey: "test-key", baseURL: "https://api.dify.ai/v1")
        
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize KnowledgeBaseClient")
    func testKnowledgeBaseClientInitialization() throws {
        let client = try KnowledgeBaseClient(apiKey: "test-key", baseURL: "https://api.dify.ai/v1")
        
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("DifyError factory methods")
    func testDifyErrorFactoryMethods() {
        let invalidURL = DifyError.invalidURL()
        #expect(invalidURL.message == "Invalid URL provided.")
        
        let invalidAPIKey = DifyError.invalidAPIKey()
        #expect(invalidAPIKey.message == "Invalid API key provided.")
        
        let httpError = DifyError.httpError(404, "Not Found")
        #expect(httpError.message == "HTTP error: Not Found")
        #expect(httpError.status == 404)
    }
    
    @Test("APIFile initialization")
    func testAPIFileInitialization() {
        let remoteFile = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/image.jpg",
            uploadFileId: nil
        )
        
        #expect(remoteFile.type == .image)
        #expect(remoteFile.transferMethod == .remoteUrl)
        #expect(remoteFile.url == "https://example.com/image.jpg")
        #expect(remoteFile.uploadFileId == nil)
        
        let localFile = APIFile(
            type: .document,
            transferMethod: .localFile,
            url: nil,
            uploadFileId: "file-123"
        )
        
        #expect(localFile.type == .document)
        #expect(localFile.transferMethod == .localFile)
        #expect(localFile.url == nil)
        #expect(localFile.uploadFileId == "file-123")
    }
    
    @Test("ProcessRule initialization")
    func testProcessRuleInitialization() {
        let automaticRule = ProcessRule(mode: "automatic")
        #expect(automaticRule.mode == "automatic")
        #expect(automaticRule.rules == nil)
        
        let customRule = ProcessRule(
            mode: "custom",
            rules: ["max_tokens": "1000"]
        )
        #expect(customRule.mode == "custom")
        #expect(customRule.rules?["max_tokens"] == "1000")
    }
    
    @Test("URL extension appendingQueryParameters")
    func testURLExtensionAppendingQueryParameters() {
        let baseURL = URL(string: "https://api.example.com/test")!
        let parameters = ["param1": "value1", "param2": "value2"]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        #expect(resultURL.query?.contains("param1=value1") == true)
        #expect(resultURL.query?.contains("param2=value2") == true)
    }
    
    @Test("MultipartFormData basic functionality")
    func testMultipartFormDataBasicFunctionality() {
        let multipart = MultipartFormData()
        multipart.addTextField(named: "field1", value: "value1")
        multipart.addFileField(named: "file1", fileName: "test.txt", data: Data("test".utf8), mimeType: "text/plain")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("field1"))
        #expect(bodyString.contains("value1"))
        #expect(bodyString.contains("test.txt"))
    }
    
    @Test("Data extension append string")
    func testDataExtensionAppendString() {
        var data = Data()
        data.append("Hello")
        data.append(" ")
        data.append("World")
        
        let result = String(data: data, encoding: .utf8)!
        #expect(result == "Hello World")
    }
    
    @Test("ResponseMode enum")
    func testResponseModeEnum() {
        #expect(ResponseMode.blocking.rawValue == "blocking")
        #expect(ResponseMode.streaming.rawValue == "streaming")
    }
    
    @Test("FileTransferMethod enum")
    func testFileTransferMethodEnum() {
        #expect(FileTransferMethod.remoteUrl.rawValue == "remote_url")
        #expect(FileTransferMethod.localFile.rawValue == "local_file")
    }
    
    @Test("FileType enum")
    func testFileTypeEnum() {
        #expect(FileType.document.rawValue == "document")
        #expect(FileType.image.rawValue == "image")
        #expect(FileType.audio.rawValue == "audio")
        #expect(FileType.video.rawValue == "video")
        #expect(FileType.custom.rawValue == "custom")
    }
    
    @Test("HTTPMethod enum")
    func testHTTPMethodEnum() {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    }
    
    @Test("JSON encoders/decoders")
    func testJSONEncodersDecoders() {
        // Test that they can be created without errors
        let encoder = JSONEncoder.difyEncoder
        let decoder = JSONDecoder.difyDecoder
        
        #expect(encoder != nil)
        #expect(decoder != nil)
    }
    
    @Test("Basic model encoding/decoding")
    func testBasicModelEncodingDecoding() throws {
        let baseResponse = BaseResponse(result: "success")
        
        let data = try JSONEncoder.difyEncoder.encode(baseResponse)
        let decoded = try JSONDecoder.difyDecoder.decode(BaseResponse.self, from: data)
        
        #expect(decoded.result == "success")
    }
    
    @Test("AnyCodable with simple values")
    func testAnyCodableWithSimpleValues() throws {
        let intValue = AnyCodable(42)
        let stringValue = AnyCodable("hello")
        let boolValue = AnyCodable(true)
        let doubleValue = AnyCodable(3.14)
        
        let values = [
            "int": intValue,
            "string": stringValue,
            "bool": boolValue,
            "double": doubleValue
        ]
        
        let data = try JSONEncoder.difyEncoder.encode(values)
        let decoded = try JSONDecoder.difyDecoder.decode([String: AnyCodable].self, from: data)
        
        #expect(decoded["int"]?.value as? Int == 42)
        #expect(decoded["string"]?.value as? String == "hello")
        #expect(decoded["bool"]?.value as? Bool == true)
        #expect(decoded["double"]?.value as? Double == 3.14)
    }
}