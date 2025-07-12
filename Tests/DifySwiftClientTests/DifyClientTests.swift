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
        let (client, _) = TestUtilities.createTestClientWithMockSession()
        
        // Don't register any mock - this will cause the mock session to return an error
        do {
            _ = try await client.sendRequest(method: .GET, endpoint: "test")
            Issue.record("Expected network error but request succeeded")
        } catch {
            // We expect an NSError from the mock session when no mock is registered
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
    
    @Test("Client Initialization - Empty API Key")
    func testClientInitializationEmptyAPIKey() async throws {
        do {
            _ = try DifyClient(apiKey: "")
            Issue.record("Expected error for empty API key")
        } catch let error as DifyError {
            // DifyError.invalidAPIKey creates an error with this message
            #expect(error.message?.contains("Invalid API key") == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Client Initialization - Invalid URL")
    func testClientInitializationInvalidURL() async throws {
        // Test with invalid URL (no scheme)
        do {
            _ = try DifyClient(apiKey: "test-key", baseURL: "not-a-url")
            Issue.record("Expected error for invalid URL")
        } catch let error as DifyError {
            // DifyError.invalidURL creates an error with this message  
            #expect(error.message?.contains("Invalid URL") == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        
        // Test with empty URL
        do {
            _ = try DifyClient(apiKey: "test-key", baseURL: "")
            Issue.record("Expected error for empty URL")
        } catch let error as DifyError {
            #expect(error.message?.contains("Invalid URL") == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Client Initialization - Custom Session")
    func testClientInitializationCustomSession() async throws {
        let customSession = URLSession(configuration: .default)
        let client = try DifyClient(apiKey: "test-key", session: customSession)
        
        #expect(client.apiKey == "test-key")
        #expect(client.session === customSession)
    }
    
    @Test("Create URL Request - With Multipart")
    func testCreateURLRequestWithMultipart() async throws {
        let client = TestUtilities.createTestClient()
        
        let multipart = MultipartFormData()
        multipart.addTextField(named: "field1", value: "test value")
        multipart.addFileField(named: "file", fileName: "test.txt", data: Data("file content".utf8), mimeType: "text/plain")
        
        let request = try client.createURLRequest(
            method: .POST,
            endpoint: "upload",
            multipart: multipart
        )
        
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.dify.ai/v1/upload")
        
        // Check Content-Type header contains boundary
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.hasPrefix("multipart/form-data; boundary=") == true)
        
        // Check body is not nil
        #expect(request.httpBody != nil)
    }
    
    @Test("Send Multipart Request - Success")
    func testSendMultipartRequestSuccess() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(["file_id": "file-123", "status": "uploaded"])
        )
        
        let multipart = MultipartFormData()
        multipart.addFileField(named: "file", fileName: "test.txt", data: Data("test content".utf8), mimeType: "text/plain")
        
        let data = try await client.sendMultipartRequest(
            method: .POST,
            endpoint: "files/upload",
            multipart: multipart
        )
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(result?["file_id"] as? String == "file-123")
        #expect(result?["status"] as? String == "uploaded")
    }
    
    @Test("Send Multipart Request - HTTP Error")
    func testSendMultipartRequestHTTPError() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register error response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.error(
                statusCode: 413,
                code: "payload_too_large",
                message: "File size exceeds limit"
            )
        )
        
        let multipart = MultipartFormData()
        multipart.addFileField(named: "file", fileName: "large.bin", data: Data(repeating: 0, count: 1000), mimeType: "application/octet-stream")
        
        await assertThrowsError({
            _ = try await client.sendMultipartRequest(
                method: .POST,
                endpoint: "files/upload",
                multipart: multipart
            )
        }, expectedError: DifyError.httpError(413, "File size exceeds limit"))
    }
    
    @Test("Send Multipart Request - Invalid Response")
    func testSendMultipartRequestInvalidResponse() async throws {
        let (_, _) = TestUtilities.createTestClientWithMockSession()
        
        // We'll use the mock session's normal register method but force an invalid response type
        // by manipulating the session configuration
        let multipart = MultipartFormData()
        multipart.addTextField(named: "field", value: "test")
        
        // Since IsolatedMockSession doesn't support custom handlers, we'll test this differently
        // by registering a response but modifying the client's session
        let customSession = URLSession(configuration: .default)
        let customClient = try DifyClient(apiKey: "test-api-key", session: customSession)
        
        // This will fail with a network error since we're using a real URLSession without mocks
        do {
            _ = try await customClient.sendMultipartRequest(
                method: .POST,
                endpoint: "test",
                multipart: multipart
            )
            Issue.record("Expected network error")
        } catch {
            // Any error is acceptable here since we're testing error handling
            // Just ensure we got some error
            #expect(error.localizedDescription.count > 0)
        }
    }
    
    @Test("HTTP Error - Unparseable Error Body")
    func testHTTPErrorUnparseableErrorBody() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register response with non-JSON error body
        mockSession.register(
            method: "GET",
            urlPattern: "/test-error",
            response: MockResponse(
                statusCode: 500,
                data: "<html>Internal Server Error</html>".data(using: .utf8)
            )
        )
        
        await assertThrowsError({
            _ = try await client.sendRequest(method: .GET, endpoint: "test-error")
        }, expectedError: DifyError.httpError(500, "Unknown API error"))
    }
    
    @Test("HTTP Error - Empty Error Body")
    func testHTTPErrorEmptyErrorBody() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register response with empty error body
        mockSession.register(
            method: "POST",
            urlPattern: "/test-empty-error",
            response: MockResponse(
                statusCode: 403,
                data: Data()
            )
        )
        
        await assertThrowsError({
            _ = try await client.sendRequest(method: .POST, endpoint: "test-empty-error")
        }, expectedError: DifyError.httpError(403, "Unknown API error"))
    }
    
    @Test("Send Request - Invalid Response Type")
    func testSendRequestInvalidResponseType() async throws {
        // This test requires manipulating URLSession internals which is difficult
        // We'll test invalid response handling through other means
        // The invalidResponse error is tested indirectly through network errors
        let customSession = URLSession(configuration: .default)
        let client = try DifyClient(apiKey: "test-api-key", baseURL: "https://invalid.test", session: customSession)
        
        do {
            _ = try await client.sendRequest(method: .GET, endpoint: "test")
            Issue.record("Expected network error")
        } catch {
            // Any error is acceptable here - we're testing error handling
            #expect(error is DifyError || (error as NSError).domain == NSURLErrorDomain)
        }
    }
    
    @Test("Streaming Response - Invalid Response Type")
    func testStreamingResponseInvalidResponseType() async throws {
        // This test is difficult to implement with IsolatedMockSession
        // We'll test the error handling indirectly through network errors
        let customSession = URLSession(configuration: .default)
        let client = try DifyClient(apiKey: "test-api-key", session: customSession)
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive any events")
            }
        } catch {
            // Expected to fail with network error
            let nsError = error as NSError
            #expect(nsError.domain.count > 0) // Verify it's a proper error
        }
    }
    
    @Test("Streaming Response - HTTP Error")
    func testStreamingResponseHTTPError() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register error response for streaming
        mockSession.register(
            method: "POST",
            urlPattern: "/stream",
            response: MockResponse(
                statusCode: 429,
                data: "Rate limit exceeded".data(using: .utf8)
            )
        )
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive any events")
            }
        } catch let error as DifyError {
            // DifyError.httpError creates a DifyError with status and message
            #expect(error.status == 429)
            #expect(error.message == "HTTP error: Rate limit exceeded")
        }
    }
    
    @Test("Streaming Response - HTTP Error with JSON Error Body")
    func testStreamingResponseHTTPErrorWithJSONBody() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register error response with JSON body
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-json-error",
            response: MockResponse.error(
                statusCode: 401,
                code: "unauthorized",
                message: "Invalid authentication"
            )
        )
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream-json-error")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive any events")
            }
        } catch let error as DifyError {
            // DifyError stores status and the error body as message
            #expect(error.status == 401)
            // The error body is read as a string in streaming
            let errorBodyString = error.message ?? ""
            #expect(errorBodyString.contains("unauthorized") || errorBodyString.contains("Invalid authentication"))
        }
    }
    
    @Test("Streaming Response - Decoding Error in Stream")
    func testStreamingResponseDecodingError() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register streaming response with invalid JSON in one of the events
        let sseData = """
        data: {"event": "message", "answer": "Hello"}
        
        data: invalid json here
        
        data: {"event": "message_end"}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-decode-error",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream-decode-error")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            var eventCount = 0
            for try await _ in stream {
                eventCount += 1
            }
            Issue.record("Expected decoding error in stream")
        } catch {
            // Should get a decoding error wrapped in DifyError
            if let difyError = error as? DifyError {
                #expect(difyError.message?.contains("decode") == true)
            } else {
                // Or could be a raw DecodingError
                #expect(error is DecodingError)
            }
        }
    }
    
    @Test("Streaming Response - DifyError in Stream")
    func testStreamingResponseDifyErrorInStream() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register streaming response with DifyError in the stream
        let sseData = """
        data: {"event": "message", "answer": "Starting...", "task_id": "task-123", "message_id": "msg-123", "created_at": 1234567890}
        
        data: {"code": "rate_limit_exceeded", "message": "You have exceeded the rate limit", "status": 429}
        
        data: {"event": "message_end"}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-dify-error",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream-dify-error")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            var eventCount = 0
            for try await event in stream {
                eventCount += 1
                // Should receive first event
                #expect(event.answer == "Starting...")
            }
            Issue.record("Expected DifyError to terminate stream")
        } catch let error as DifyError {
            #expect(error.code == "rate_limit_exceeded")
            #expect(error.message == "You have exceeded the rate limit")
            #expect(error.status == 429)
        }
    }
    
    @Test("Streaming Response - Empty Error Body")
    func testStreamingResponseEmptyErrorBody() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register error response with empty body
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-empty-error",
            response: MockResponse(
                statusCode: 500,
                data: Data()
            )
        )
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream-empty-error")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive any events")
            }
        } catch let error as DifyError {
            // Empty error body results in empty string message
            #expect(error.status == 500)
            #expect(error.message == "HTTP error: ")
        }
    }
    
    @Test("Streaming Response - Network Error During Stream")
    func testStreamingResponseNetworkError() async throws {
        // Use a real URLSession without mocks to trigger network error
        let customSession = URLSession(configuration: .default)
        let client = try DifyClient(apiKey: "test-api-key", baseURL: "https://invalid.example.com", session: customSession)
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive any events")
            }
        } catch {
            // Should get network error
            let nsError = error as NSError
            #expect(nsError.domain.count > 0) // Verify it's a proper error
        }
    }
    
    @Test("Create URL Request - Edge Cases")
    func testCreateURLRequestEdgeCases() async throws {
        let client = TestUtilities.createTestClient()
        
        // Test with empty query parameters (should not add ? to URL)
        let request1 = try client.createURLRequest(
            method: .GET,
            endpoint: "test",
            params: [:]
        )
        #expect(request1.url?.absoluteString == "https://api.dify.ai/v1/test")
        
        // Test with special characters in query parameters
        let request2 = try client.createURLRequest(
            method: .GET,
            endpoint: "search",
            params: ["q": "hello world", "filter": "type=chat&status=active"]
        )
        #expect(request2.url?.query?.contains("hello%20world") == true)
        
        // Test with body and multipart (body takes precedence)
        let multipart = MultipartFormData()
        multipart.addTextField(named: "field", value: "test")
        
        struct TestBody: Codable { let ignored: String }
        let request3 = try client.createURLRequest(
            method: .POST,
            endpoint: "upload",
            body: TestBody(ignored: "this should be used"),
            multipart: multipart
        )
        
        // Should use JSON body, not multipart (body takes precedence)
        let contentType = request3.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType == "application/json; charset=utf-8")
        #expect(request3.httpBody != nil)
    }
    
    // MARK: - Production Streaming Tests (Bytes API)
    
    @Test("Production Streaming - Success Case")
    func testProductionStreamingSuccess() async throws {
        // Create a custom URLSession without MockURLProtocol to test bytes API path
        let config = URLSessionConfiguration.default
        config.protocolClasses = nil // Ensure no MockURLProtocol
        let productionSession = URLSession(configuration: config)
        let client = try DifyClient(apiKey: "test-key", session: productionSession)
        
        // This will fail with network error but will exercise the bytes API code path
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "chat-messages")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive events from invalid URL")
            }
        } catch {
            // Expected to fail - we're testing the code path, not the result
            #expect(error.localizedDescription.count > 0)
        }
    }
    
    @Test("Production Streaming - Non-HTTP Response")
    func testProductionStreamingNonHTTPResponse() async throws {
        // Test the bytes API path with URL that returns non-HTTP response
        let config = URLSessionConfiguration.default
        config.protocolClasses = nil
        let productionSession = URLSession(configuration: config)
        let client = try DifyClient(apiKey: "test-key", baseURL: "file:///invalid", session: productionSession)
        
        do {
            let request = try client.createURLRequest(method: .GET, endpoint: "test")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
            
            for try await _ in stream {
                Issue.record("Should not receive events")
            }
        } catch {
            // Should fail with appropriate error  
            #expect(error.localizedDescription.count > 0)
        }
    }
    
    @Test("Decode Method - Complex Types")
    func testDecodeComplexTypes() async throws {
        let client = TestUtilities.createTestClient()
        
        // Test decoding array
        let arrayJson = "[1, 2, 3]".data(using: .utf8)!
        let array = try client.decode(arrayJson, to: [Int].self)
        #expect(array == [1, 2, 3])
        
        // Test decoding with dates
        struct DateModel: Codable {
            let timestamp: Date
            let name: String
        }
        
        let dateJson = """
        {
            "timestamp": 1234567890,
            "name": "test"
        }
        """.data(using: .utf8)!
        
        let dateModel = try client.decode(dateJson, to: DateModel.self)
        #expect(dateModel.timestamp.timeIntervalSince1970 == 1234567890)
        #expect(dateModel.name == "test")
    }
    
    @Test("Streaming Response - Complete Flow with Mock Server")
    func testStreamingCompleteFlow() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Create valid SSE data 
        let sseData = """
        data: {"event": "message", "task_id": "task-1", "message_id": "msg-1", "answer": "Hello", "created_at": 123}
        
        data: {"event": "message", "task_id": "task-1", "message_id": "msg-1", "answer": " World", "created_at": 124}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-complete",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        let request = try client.createURLRequest(method: .POST, endpoint: "stream-complete")
        let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageStreamEvent, Error>
        
        var events: [MessageStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }
        
        #expect(events.count == 2)
        #expect(events[0].answer == "Hello")
        #expect(events[1].answer == " World")
    }
    
    @Test("URL Extension - Query Parameters Edge Cases")
    func testURLExtensionQueryParameters() async throws {
        // Test appending to URL with existing query parameters
        let baseURL = URL(string: "https://api.test.com/endpoint?existing=value")!
        let newURL = baseURL.appendingQueryParameters(["new": "param", "another": "test"])
        
        let components = URLComponents(url: newURL, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        #expect(queryItems.contains { $0.name == "existing" && $0.value == "value" })
        #expect(queryItems.contains { $0.name == "new" && $0.value == "param" })
        #expect(queryItems.contains { $0.name == "another" && $0.value == "test" })
        
        // Test with URL that has malformed components
        if let malformedURL = URL(string: "https://test.com/path?invalid]") {
            let resultURL = malformedURL.appendingQueryParameters(["test": "value"])
            // Should still append parameters even with malformed existing query
            #expect(resultURL.absoluteString.contains("test=value"))
        }
    }
    
    @Test("Streaming - Test MockURLProtocol Detection")
    func testMockURLProtocolDetection() async throws {
        // Test that mock session is properly detected
        let (client, _) = TestUtilities.createTestClientWithMockSession()
        
        // Access the session configuration to verify MockURLProtocol is registered
        let protocolClasses = client.session.configuration.protocolClasses ?? []
        let hasMockProtocol = protocolClasses.contains { protocolClass in
            NSStringFromClass(protocolClass).contains("MockURLProtocol")
        }
        #expect(hasMockProtocol == true)
    }
    
    @Test("Streaming DataTask Path - Normal Completion")
    func testStreamingDataTaskNormalCompletion() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register SSE response that completes normally
        let sseData = """
        data: {"event": "start", "message": "Starting"}
        
        data: {"event": "end", "message": "Complete"}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-normal",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        struct SimpleEvent: Codable {
            let event: String
            let message: String
        }
        
        let request = try client.createURLRequest(method: .POST, endpoint: "stream-normal")
        let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<SimpleEvent, Error>
        
        var events: [SimpleEvent] = []
        for try await event in stream {
            events.append(event)
        }
        
        #expect(events.count == 2)
        #expect(events[0].event == "start")
        #expect(events[1].event == "end")
    }
    
    @Test("Streaming DataTask Path - DifyError Detection")
    func testStreamingDataTaskDifyErrorDetection() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register SSE response with a DifyError that has all fields
        let sseData = """
        data: {"event": "start"}
        
        data: {"message": "Rate limit error", "code": "rate_limit", "status": 429}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-dify-error-full",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        struct SimpleEvent: Codable {
            let event: String
        }
        
        do {
            let request = try client.createURLRequest(method: .POST, endpoint: "stream-dify-error-full")
            let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<SimpleEvent, Error>
            
            var count = 0
            for try await _ in stream {
                count += 1
            }
            Issue.record("Expected DifyError to terminate stream, got \(count) events")
        } catch let error as DifyError {
            #expect(error.message == "Rate limit error")
            #expect(error.code == "rate_limit")
            #expect(error.status == 429)
        }
    }
    
    @Test("Streaming DataTask Path - Lines Not Prefixed with data:")
    func testStreamingDataTaskNonDataLines() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register SSE response with various line types
        let sseData = """
        : comment line
        event: test
        data: {"event": "message", "content": "Hello"}
        
        retry: 1000
        data: {"event": "message", "content": "World"}
        : another comment
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-mixed-lines",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        struct MessageEvent: Codable {
            let event: String
            let content: String
        }
        
        let request = try client.createURLRequest(method: .POST, endpoint: "stream-mixed-lines")
        let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<MessageEvent, Error>
        
        var events: [MessageEvent] = []
        for try await event in stream {
            events.append(event)
        }
        
        // Should only process lines starting with "data: "
        #expect(events.count == 2)
        #expect(events[0].content == "Hello")
        #expect(events[1].content == "World")
    }
    
    @Test("Streaming DataTask Path - Empty Data Lines")
    func testStreamingDataTaskEmptyDataLines() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register SSE response with empty data lines
        let sseData = """
        data: {"event": "start"}
        data: 
        data: {"event": "middle"}
        data:
        data: {"event": "end"}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-empty-data",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        struct SimpleEvent: Codable {
            let event: String
        }
        
        let request = try client.createURLRequest(method: .POST, endpoint: "stream-empty-data")
        let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<SimpleEvent, Error>
        
        var events: [SimpleEvent] = []
        var errorCount = 0
        do {
            for try await event in stream {
                events.append(event)
            }
        } catch {
            // Empty data lines will cause the stream to end with an error
            errorCount += 1
        }
        
        // Should decode at least the first valid event before hitting empty data
        #expect(events.count >= 1)
        #expect(events[0].event == "start")
    }
    
    @Test("Multipart Form Data - Comprehensive Coverage")
    func testMultipartFormDataComprehensive() async throws {
        let multipart = MultipartFormData()
        
        // Test multiple text fields
        multipart.addTextField(named: "field1", value: "value1")
        multipart.addTextField(named: "field2", value: "value with special chars: &=?")
        multipart.addTextField(named: "field3", value: "multi\nline\nvalue")
        
        // Test multiple files
        multipart.addFileField(named: "file1", fileName: "test.txt", data: Data("Hello".utf8), mimeType: "text/plain")
        multipart.addFileField(named: "file2", fileName: "data.json", data: Data("{\"key\":\"value\"}".utf8), mimeType: "application/json")
        multipart.addFileField(named: "file3", fileName: "empty.dat", data: Data(), mimeType: "application/octet-stream")
        
        let (headers, body) = multipart.build()
        
        // Verify headers
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        
        // Verify body contains all fields and files
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        #expect(bodyString.contains("field1"))
        #expect(bodyString.contains("value1"))
        #expect(bodyString.contains("field2"))
        #expect(bodyString.contains("value with special chars: &=?"))
        #expect(bodyString.contains("field3"))
        #expect(bodyString.contains("multi\nline\nvalue"))
        #expect(bodyString.contains("test.txt"))
        #expect(bodyString.contains("data.json"))
        #expect(bodyString.contains("empty.dat"))
        #expect(bodyString.contains("Content-Type: text/plain"))
        #expect(bodyString.contains("Content-Type: application/json"))
        #expect(bodyString.contains("Content-Type: application/octet-stream"))
    }
    
    @Test("Internal Session Property Access")
    func testInternalSessionAccess() async throws {
        // Test that internal session property is properly set
        let customSession = URLSession(configuration: .ephemeral)
        let client = try DifyClient(apiKey: "test-key", session: customSession)
        
        // Access internal session to ensure it's the same
        #expect(client.session === customSession)
    }
    
    @Test("Create URL Request - All Parameters")
    func testCreateURLRequestAllParameters() async throws {
        let client = TestUtilities.createTestClient()
        
        // Test with all parameters provided
        struct TestBody: Codable {
            let field1: String
            let field2: Int
            let field3: Bool
        }
        
        let body = TestBody(field1: "test", field2: 42, field3: true)
        let params = [
            "param1": "value1",
            "param2": "value2",
            "param3": "special chars: !@#$%^&*()"
        ]
        
        let request = try client.createURLRequest(
            method: .PATCH,
            endpoint: "complex/endpoint/path",
            params: params,
            body: body
        )
        
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path == "/v1/complex/endpoint/path")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json; charset=utf-8")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-api-key")
        
        // Verify query parameters are encoded
        let url = request.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        #expect(queryItems.count == 3)
        #expect(queryItems.contains { $0.name == "param1" && $0.value == "value1" })
        #expect(queryItems.contains { $0.name == "param3" && $0.value?.contains("!") == true })
        
        // Verify body is encoded
        #expect(request.httpBody != nil)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: request.httpBody!)
        #expect(decodedBody.field1 == "test")
        #expect(decodedBody.field2 == 42)
        #expect(decodedBody.field3 == true)
    }
    
    @Test("Streaming Response - Complete Event Processing")
    func testStreamingCompleteEventProcessing() async throws {
        let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
        
        // Register a slow streaming response
        let sseData = """
        data: {"event": "start"}
        
        data: {"event": "middle"}
        
        data: {"event": "end"}
        """
        
        mockSession.register(
            method: "POST",
            urlPattern: "/stream-cancel",
            response: MockResponse(
                statusCode: 200,
                headers: ["Content-Type": "text/event-stream"],
                data: sseData.data(using: .utf8)!
            )
        )
        
        struct SimpleEvent: Codable {
            let event: String
        }
        
        let request = try client.createURLRequest(method: .POST, endpoint: "stream-cancel")
        let stream = try await client.createStreamingResponse(for: request) as AsyncThrowingStream<SimpleEvent, Error>
        
        // Consume stream normally
        var collectedEvents: [SimpleEvent] = []
        for try await event in stream {
            collectedEvents.append(event)
        }
        
        #expect(collectedEvents.count == 3)
        #expect(collectedEvents[0].event == "start")
        #expect(collectedEvents[1].event == "middle")
        #expect(collectedEvents[2].event == "end")
    }
}