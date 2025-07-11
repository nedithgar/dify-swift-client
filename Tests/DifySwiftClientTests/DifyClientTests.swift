import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("DifyClient Tests")
struct DifyClientTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - Initialization Tests
    
    @Test("Initialize with valid API key and base URL")
    func testInitializationWithValidParameters() throws {
        let client = try DifyClient(apiKey: "test-api-key", baseURL: "https://api.dify.ai/v1")
        
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Initialize with custom base URL")
    func testInitializationWithCustomBaseURL() throws {
        let customURL = "https://custom.dify.ai/v1"
        let client = try DifyClient(apiKey: "test-api-key", baseURL: customURL)
        
        #expect(client.baseURL.absoluteString == customURL)
    }
    
    @Test("Initialize with empty API key throws error")
    func testInitializationWithEmptyAPIKey() {
        #expect(throws: DifyError.self) {
            try DifyClient(apiKey: "", baseURL: "https://api.dify.ai/v1")
        }
    }
    
    @Test("Initialize with invalid base URL throws error")
    func testInitializationWithInvalidBaseURL() {
        #expect(throws: DifyError.self) {
            try DifyClient(apiKey: "test-api-key", baseURL: "invalid-url")
        }
    }
    
    @Test("Initialize with base URL without scheme throws error")
    func testInitializationWithURLWithoutScheme() {
        #expect(throws: DifyError.self) {
            try DifyClient(apiKey: "test-api-key", baseURL: "api.dify.ai/v1")
        }
    }
    
    @Test("Initialize with custom URLSession")
    func testInitializationWithCustomSession() throws {
        let customSession = URLSession.shared
        let client = try DifyClient(apiKey: "test-api-key", baseURL: "https://api.dify.ai/v1", session: customSession)
        
        #expect(client.apiKey == "test-api-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    // MARK: - Request Creation Tests
    
    @Test("Create URL request with GET method")
    func testCreateURLRequestWithGET() throws {
        let client = try TestUtilities.createMockDifyClient()
        let request = try client.createURLRequest(method: .GET, endpoint: "/test")
        
        TestUtilities.assertRequestHasMethod(request, expectedMethod: .GET)
        TestUtilities.assertRequestHasEndpoint(request, expectedEndpoint: "/test")
        TestUtilities.assertRequestHasHeaders(request, expectedHeaders: ["Authorization": "Bearer test-api-key"])
    }
    
    @Test("Create URL request with POST method and JSON body")
    func testCreateURLRequestWithPOSTAndJSONBody() throws {
        let client = try TestUtilities.createMockDifyClient()
        let testBody = ["key": "value"]
        let request = try client.createURLRequest(method: .POST, endpoint: "/test", body: testBody)
        
        TestUtilities.assertRequestHasMethod(request, expectedMethod: .POST)
        TestUtilities.assertRequestHasEndpoint(request, expectedEndpoint: "/test")
        TestUtilities.assertRequestHasHeaders(request, expectedHeaders: [
            "Authorization": "Bearer test-api-key",
            "Content-Type": "application/json; charset=utf-8"
        ])
        
        #expect(request.httpBody != nil)
        
        // Verify JSON body content
        let bodyData = request.httpBody!
        let decodedBody = try JSONSerialization.jsonObject(with: bodyData) as! [String: String]
        #expect(decodedBody["key"] == "value")
    }
    
    @Test("Create URL request with query parameters")
    func testCreateURLRequestWithQueryParameters() throws {
        let client = try TestUtilities.createMockDifyClient()
        let params = ["param1": "value1", "param2": "value2"]
        let request = try client.createURLRequest(method: .GET, endpoint: "/test", params: params)
        
        TestUtilities.assertURLContainsParameters(request.url!, expectedParams: params)
    }
    
    @Test("Create URL request with multipart form data")
    func testCreateURLRequestWithMultipartFormData() throws {
        let client = try TestUtilities.createMockDifyClient()
        let multipart = MultipartFormData()
        multipart.addTextField(named: "field1", value: "value1")
        multipart.addFileField(named: "file1", fileName: "test.txt", data: Data("test".utf8), mimeType: "text/plain")
        
        let request = try client.createURLRequest(method: .POST, endpoint: "/test", multipart: multipart)
        
        TestUtilities.assertRequestHasMethod(request, expectedMethod: .POST)
        TestUtilities.assertRequestHasEndpoint(request, expectedEndpoint: "/test")
        
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(request.httpBody != nil)
    }
    
    // MARK: - Request Sending Tests
    
    @Test("Send request with successful response")
    func testSendRequestWithSuccessfulResponse() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let data = try await client.sendRequest(method: .GET, endpoint: "/test")
        
        #expect(data == mockData)
    }
    
    @Test("Send request with HTTP error response")
    func testSendRequestWithHTTPErrorResponse() async throws {
        let client = try TestUtilities.createMockDifyClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Not Found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.sendRequest(method: .GET, endpoint: "/test")
        }
    }
    
    @Test("Send request with network error")
    func testSendRequestWithNetworkError() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        MockURLProtocol.setMockError(networkError)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.sendRequest(method: .GET, endpoint: "/test")
        }
    }
    
    @Test("Send request with invalid response type")
    func testSendRequestWithInvalidResponseType() async throws {
        let client = try TestUtilities.createMockDifyClient()
        
        // Mock a response that's not HTTPURLResponse
        MockURLProtocol.requestHandler = { _ in
            let response = URLResponse(url: URL(string: "https://test.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            return (response as! HTTPURLResponse, Data(), nil)
        }
        
        await TestUtilities.assertThrowsAnyError {
            try await client.sendRequest(method: .GET, endpoint: "/test")
        }
    }
    
    // MARK: - Multipart Request Tests
    
    @Test("Send multipart request with successful response")
    func testSendMultipartRequestWithSuccessfulResponse() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockFileUpload)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let multipart = MultipartFormData()
        multipart.addTextField(named: "user", value: "test-user")
        multipart.addFileField(named: "file", fileName: "test.txt", data: Data("test".utf8), mimeType: "text/plain")
        
        let data = try await client.sendMultipartRequest(method: .POST, endpoint: "/upload", multipart: multipart)
        
        #expect(data == mockData)
    }
    
    @Test("Send multipart request with HTTP error")
    func testSendMultipartRequestWithHTTPError() async throws {
        let client = try TestUtilities.createMockDifyClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 413, message: "Payload Too Large")
        
        let multipart = MultipartFormData()
        multipart.addFileField(named: "file", fileName: "large.txt", data: Data(repeating: 0, count: 1000000), mimeType: "text/plain")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.sendMultipartRequest(method: .POST, endpoint: "/upload", multipart: multipart)
        }
    }
    
    // MARK: - Streaming Response Tests
    
    @Test("Create streaming response with successful data")
    func testCreateStreamingResponseWithSuccessfulData() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let request = try client.createURLRequest(method: .POST, endpoint: "/chat-messages", body: ["test": "data"])
        
        // Setup streaming mock
        MockStreamingURLProtocol.streamingData = MockDataProvider.mockStreamingChatData
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try DifyClient(apiKey: "test-api-key", session: streamingSession)
        let streamingRequest = try streamingClient.createURLRequest(method: .POST, endpoint: "/chat-messages", body: ["test": "data"])
        
        let stream: AsyncThrowingStream<StreamingChatMessageResponse, Error> = try await streamingClient.createStreamingResponse(for: streamingRequest)
        
        let items = try await TestUtilities.collectStreamItems(stream, limit: 2)
        
        #expect(items.count == 2)
    }
    
    @Test("Create streaming response with error")
    func testCreateStreamingResponseWithError() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let request = try client.createURLRequest(method: .POST, endpoint: "/chat-messages", body: ["test": "data"])
        
        // Setup streaming mock with error
        MockStreamingURLProtocol.streamingError = DifyError.networkError(NSError(domain: "Test", code: 0, userInfo: nil))
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockStreamingURLProtocol.self]
        let streamingSession = URLSession(configuration: config)
        
        let streamingClient = try DifyClient(apiKey: "test-api-key", session: streamingSession)
        let streamingRequest = try streamingClient.createURLRequest(method: .POST, endpoint: "/chat-messages", body: ["test": "data"])
        
        let stream: AsyncThrowingStream<StreamingChatMessageResponse, Error> = try await streamingClient.createStreamingResponse(for: streamingRequest)
        
        await TestUtilities.assertThrowsAnyError {
            _ = try await TestUtilities.collectStreamItems(stream)
        }
    }
    
    // MARK: - JSON Decoding Tests
    
    @Test("Decode valid JSON data")
    func testDecodeValidJSONData() throws {
        let client = try TestUtilities.createMockDifyClient()
        let mockResponse = MockDataProvider.mockBaseResponse
        let jsonData = MockDataProvider.jsonData(mockResponse)
        
        let decoded = try client.decode(jsonData, to: BaseResponse.self)
        
        #expect(decoded.result == mockResponse.result)
    }
    
    @Test("Decode invalid JSON data throws error")
    func testDecodeInvalidJSONDataThrowsError() throws {
        let client = try TestUtilities.createMockDifyClient()
        let invalidJSON = Data("invalid json".utf8)
        
        #expect(throws: DifyError.self) {
            try client.decode(invalidJSON, to: BaseResponse.self)
        }
    }
    
    @Test("Decode JSON with missing required fields throws error")
    func testDecodeJSONWithMissingRequiredFieldsThrowsError() throws {
        let client = try TestUtilities.createMockDifyClient()
        let incompleteJSON = Data("{}".utf8)
        
        #expect(throws: DifyError.self) {
            try client.decode(incompleteJSON, to: ApplicationInfoResponse.self)
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle DifyError from API response")
    func testHandleDifyErrorFromAPIResponse() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let errorResponse = DifyError(message: "API Error", code: "invalid_request", status: 400)
        let errorData = MockDataProvider.jsonData(errorResponse)
        
        MockURLProtocol.setMockResponse(data: errorData, statusCode: 400)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.sendRequest(method: .GET, endpoint: "/test")
        }
    }
    
    @Test("Handle HTTP error without DifyError body")
    func testHandleHTTPErrorWithoutDifyErrorBody() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let errorData = Data("Internal Server Error".utf8)
        
        MockURLProtocol.setMockResponse(data: errorData, statusCode: 500)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.sendRequest(method: .GET, endpoint: "/test")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Handle empty response data")
    func testHandleEmptyResponseData() async throws {
        let client = try TestUtilities.createMockDifyClient()
        
        MockURLProtocol.setMockResponse(data: Data(), statusCode: 200)
        
        let data = try await client.sendRequest(method: .GET, endpoint: "/test")
        
        #expect(data.isEmpty)
    }
    
    @Test("Handle large response data")
    func testHandleLargeResponseData() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let largeData = Data(repeating: 0x42, count: 1_000_000)
        
        MockURLProtocol.setMockResponse(data: largeData, statusCode: 200)
        
        let data = try await client.sendRequest(method: .GET, endpoint: "/test")
        
        #expect(data.count == 1_000_000)
    }
    
    @Test("Handle concurrent requests")
    func testHandleConcurrentRequests() async throws {
        let client = try TestUtilities.createMockDifyClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        // Send multiple concurrent requests
        async let request1 = client.sendRequest(method: .GET, endpoint: "/test1")
        async let request2 = client.sendRequest(method: .GET, endpoint: "/test2")
        async let request3 = client.sendRequest(method: .GET, endpoint: "/test3")
        
        let (data1, data2, data3) = try await (request1, request2, request3)
        
        #expect(data1 == mockData)
        #expect(data2 == mockData)
        #expect(data3 == mockData)
    }
    
    // MARK: - URL Building Tests
    
    @Test("Build URL with path components")
    func testBuildURLWithPathComponents() throws {
        let client = try TestUtilities.createMockDifyClient()
        let request = try client.createURLRequest(method: .GET, endpoint: "/datasets/123/documents/456")
        
        #expect(request.url?.path == "/datasets/123/documents/456")
    }
    
    @Test("Build URL with special characters in path")
    func testBuildURLWithSpecialCharactersInPath() throws {
        let client = try TestUtilities.createMockDifyClient()
        let request = try client.createURLRequest(method: .GET, endpoint: "/test/path with spaces")
        
        #expect(request.url?.path == "/test/path with spaces")
    }
    
    @Test("Build URL with encoded query parameters")
    func testBuildURLWithEncodedQueryParameters() throws {
        let client = try TestUtilities.createMockDifyClient()
        let params = ["query": "hello world", "special": "chars@#$%"]
        let request = try client.createURLRequest(method: .GET, endpoint: "/search", params: params)
        
        let url = request.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        #expect(components.queryItems?.count == 2)
        #expect(components.queryItems?.contains { $0.name == "query" && $0.value == "hello world" } == true)
        #expect(components.queryItems?.contains { $0.name == "special" && $0.value == "chars@#$%" } == true)
    }
}