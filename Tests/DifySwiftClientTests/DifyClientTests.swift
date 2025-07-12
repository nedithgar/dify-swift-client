import Foundation
import Testing
@testable import DifySwiftClient

@Suite("DifyClient Tests")
struct DifyClientTests: DifyTestCase {
    
    @Test("Client Initialization")
    func testClientInitialization() async throws {
        // Test default initialization
        let client = DifyClient(apiKey: "test-key")
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL == "https://api.dify.ai/v1")
        
        // Test custom base URL
        let customClient = DifyClient(apiKey: "test-key", baseURL: "https://custom.api.com/v2")
        #expect(customClient.apiKey == "test-key")
        #expect(customClient.baseURL == "https://custom.api.com/v2")
    }
    
    @Test("Create Request - Basic")
    func testCreateBasicRequest() async throws {
        let client = TestUtilities.createTestClient()
        
        let request = try client.createRequest(endpoint: "/test", method: "GET")
        
        #expect(request.url?.absoluteString == "https://api.dify.ai/v1/test")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-api-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
    
    @Test("Create Request - With Query Parameters")
    func testCreateRequestWithQueryParameters() async throws {
        let client = TestUtilities.createTestClient()
        
        let request = try client.createRequest(
            endpoint: "/test",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "20")
            ]
        )
        
        #expect(request.url?.absoluteString.contains("page=1") == true)
        #expect(request.url?.absoluteString.contains("limit=20") == true)
    }
    
    @Test("File Upload")
    func testFileUpload() async throws {
        setupMocks()
        let client = TestUtilities.createTestClient()
        
        let imageData = TestUtilities.createTestImageData()
        let file = APIFile(
            data: imageData,
            filename: "test.png",
            mimeType: "image/png"
        )
        
        let response = try await client.uploadFile(file: file, user: "test-user")
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
        #expect(response.name == "example.png")
        #expect(response.extension == "png")
        #expect(response.mimeType == "image/png")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            method: "POST",
            urlPattern: "/files/upload",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Get Application Info")
    func testGetApplicationInfo() async throws {
        setupMocks()
        let client = TestUtilities.createTestClient()
        
        let info = try await client.getApplicationInfo()
        
        #expect(info.name == "My Dify App")
        #expect(info.description == "This is a test application")
        #expect(info.tags == ["ai", "chatbot"])
        #expect(info.mode == .chat)
        #expect(info.authorName == "Dify")
    }
    
    @Test("Get Application Parameters")
    func testGetApplicationParameters() async throws {
        setupMocks()
        let client = TestUtilities.createTestClient()
        
        let params = try await client.getApplicationParameters()
        
        #expect(params.openingStatement == "Hello! How can I help you today?")
        #expect(params.suggestedQuestions?.count == 2)
        #expect(params.speechToText?.enabled == true)
        #expect(params.fileUpload?.image?.enabled == true)
        #expect(params.systemParameters?.imageSizeLimit == 10)
    }
    
    @Test("HTTP Error Handling - 404")
    func testHTTP404Error() async throws {
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/not-found",
            response: MockResponse.error(
                statusCode: 404,
                code: "not_found",
                message: "Resource not found"
            )
        )
        
        let client = TestUtilities.createTestClient()
        
        await assertThrowsError({
            let request = try client.createRequest(endpoint: "/not-found", method: "GET")
            let _: [String: Any] = try await client.sendRequest(request)
        }, expectedError: .httpError(statusCode: 404, message: "Resource not found"))
    }
    
    @Test("HTTP Error Handling - 401")
    func testHTTP401Error() async throws {
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/unauthorized",
            response: MockResponse.error(
                statusCode: 401,
                code: "unauthorized",
                message: "Invalid API key"
            )
        )
        
        let client = TestUtilities.createTestClient()
        
        await assertThrowsError({
            let request = try client.createRequest(endpoint: "/unauthorized", method: "GET")
            let _: [String: Any] = try await client.sendRequest(request)
        }, expectedError: .httpError(statusCode: 401, message: "Invalid API key"))
    }
    
    @Test("Network Error Handling")
    func testNetworkError() async throws {
        // Don't register any mock - this will cause MockURLProtocol to return an error
        let client = TestUtilities.createTestClient()
        
        do {
            let request = try client.createRequest(endpoint: "/test", method: "GET")
            let _: [String: Any] = try await client.sendRequest(request)
            Issue.record("Expected network error but request succeeded")
        } catch {
            // We expect an error here
            #expect(error is DifyError)
        }
    }
    
    @Test("JSON Decoding Error")
    func testJSONDecodingError() async throws {
        // Register mock with invalid JSON for expected response type
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/invalid-json",
            response: MockResponse(
                statusCode: 200,
                data: "invalid json".data(using: .utf8)
            )
        )
        
        let client = TestUtilities.createTestClient()
        
        do {
            let request = try client.createRequest(endpoint: "/invalid-json", method: "GET")
            let _: ApplicationInfo = try await client.sendRequest(request)
            Issue.record("Expected decoding error but request succeeded")
        } catch DifyError.decodingError {
            // Expected error
            #expect(true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}