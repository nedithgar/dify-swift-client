import Foundation
import Testing
@testable import DifySwiftClient

@Suite("DifyClient Tests")
final class DifyClientTests: DifyTestCase {
    
    @Test("Client Initialization")
    func testClientInitialization() async throws {
        // Test default initialization
        let client = try DifyClient(apiKey: "test-key")
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
        
        // Test custom base URL
        let customClient = try DifyClient(apiKey: "test-key", baseURL: "https://custom.api.com/v2")
        #expect(customClient.apiKey == "test-key")
        #expect(customClient.baseURL.absoluteString == "https://custom.api.com/v2")
    }
    
    @Test("Create URL Request - Basic")
    func testCreateBasicURLRequest() async throws {
        let client = TestUtilities.createTestClient()
        
        let request = try client.createURLRequest(method: .GET, endpoint: "test")
        
        #expect(request.url?.absoluteString == "https://api.dify.ai/v1/test")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-api-key")
    }
    
    @Test("Create URL Request - With Query Parameters")
    func testCreateRequestWithQueryParameters() async throws {
        let client = TestUtilities.createTestClient()
        
        let request = try client.createURLRequest(
            method: .GET,
            endpoint: "test",
            params: [
                "page": "1",
                "limit": "20"
            ]
        )
        
        #expect(request.url?.absoluteString.contains("page=1") == true)
        #expect(request.url?.absoluteString.contains("limit=20") == true)
    }
    
    @Test("Send Request - Basic GET")
    func testSendRequest() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register test-specific mock
        mockSession.register(
            method: "GET",
            urlPattern: "/test",
            response: MockResponse.json(["result": "success"])
        )
        
        let data = try await client.sendRequest(method: .GET, endpoint: "test")
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        #expect(result?["result"] as? String == "success")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "GET",
            urlPattern: "/test",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Send Request - With Body")
    func testSendRequestWithBody() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register test-specific mock
        mockSession.register(
            method: "POST",
            urlPattern: "/test",
            response: MockResponse.json(["result": "created"])
        )
        
        struct TestBody: Codable {
            let name: String
            let value: Int
        }
        
        let body = TestBody(name: "test", value: 42)
        let data = try await client.sendRequest(method: .POST, endpoint: "test", body: body)
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        #expect(result?["result"] as? String == "created")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/test",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Decode Response")
    func testDecodeResponse() async throws {
        let client = TestUtilities.createTestClient()
        
        struct TestResponse: Codable {
            let name: String
            let value: Int
        }
        
        let jsonData = """
        {
            "name": "test",
            "value": 42
        }
        """.data(using: .utf8)!
        
        let response = try client.decode(jsonData, to: TestResponse.self)
        
        #expect(response.name == "test")
        #expect(response.value == 42)
    }
    
    @Test("HTTP Error Handling - 404")
    func testHTTP404Error() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        mockSession.register(
            method: "GET",
            urlPattern: "/not-found",
            response: MockResponse.error(
                statusCode: 404,
                code: "not_found",
                message: "Resource not found"
            )
        )
        
        await assertThrowsError({
            _ = try await client.sendRequest(method: .GET, endpoint: "not-found")
        }, expectedError: DifyError.httpError(404, "Resource not found"))
    }
    
    @Test("HTTP Error Handling - 401")
    func testHTTP401Error() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        mockSession.register(
            method: "GET",
            urlPattern: "/unauthorized",
            response: MockResponse.error(
                statusCode: 401,
                code: "unauthorized",
                message: "Invalid API key"
            )
        )
        
        await assertThrowsError({
            _ = try await client.sendRequest(method: .GET, endpoint: "unauthorized")
        }, expectedError: DifyError.httpError(401, "Invalid API key"))
    }
    
    @Test("Network Error Handling")
    func testNetworkError() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Don't register any mock - this will cause the mock session to return an error
        do {
            _ = try await client.sendRequest(method: .GET, endpoint: "test")
            Issue.record("Expected network error but request succeeded")
        } catch {
            // We expect an NSError from the mock session when no mock is registered
            #expect(error is NSError)
            let nsError = error as NSError
            #expect(nsError.domain == "IsolatedMockURLProtocol")
            #expect(nsError.code == 404)
        }
    }
    
    @Test("JSON Decoding Error")
    func testJSONDecodingError() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register mock with invalid JSON for expected response type
        mockSession.register(
            method: "GET",
            urlPattern: "/invalid-json",
            response: MockResponse(
                statusCode: 200,
                data: "invalid json".data(using: .utf8)
            )
        )
        
        do {
            struct TestResponse: Decodable { let name: String }
            let data = try await client.sendRequest(method: .GET, endpoint: "invalid-json")
            _ = try client.decode(data, to: TestResponse.self)
            Issue.record("Expected decoding error but request succeeded")
        } catch let difyError as DifyError {
            // DifyError.decodingError produces a DifyError with specific message
            // We expect any DifyError with decoding-related message
            #expect(difyError.message?.contains("decode") == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}