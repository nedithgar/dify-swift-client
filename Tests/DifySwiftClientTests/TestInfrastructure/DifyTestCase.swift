import Foundation
import Testing
@testable import DifySwiftClient

/// Base test case providing common setup and teardown for Dify SDK tests
@Suite("Dify SDK Tests")
struct DifyTestCase {
    
    // MARK: - Properties
    
    let apiKey = "test-api-key"
    let baseURL = "https://api.dify.ai/v1"
    
    // MARK: - Lifecycle
    
    init() async throws {
        // Setup before all tests
        setupTestEnvironment()
    }
    
    deinit {
        // Cleanup after all tests
        cleanupTestEnvironment()
    }
    
    // MARK: - Setup & Teardown
    
    private func setupTestEnvironment() {
        // Reset mocks
        MockURLProtocol.reset()
        
        // Register MockURLProtocol globally for tests
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    private func cleanupTestEnvironment() {
        // Unregister MockURLProtocol
        URLProtocol.unregisterClass(MockURLProtocol.self)
        
        // Clear all mocks
        MockURLProtocol.reset()
    }
    
    // MARK: - Test Helpers
    
    /// Setup mocks before each test
    func setupMocks() {
        MockURLProtocol.reset()
        TestUtilities.setupCommonMocks()
    }
    
    /// Verify no unexpected requests were made
    func verifyNoUnexpectedRequests() {
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let unexpectedRequests = capturedRequests.filter { request in
            // Filter out expected common requests
            guard let url = request.url?.absoluteString else { return true }
            return !url.contains("/info") && !url.contains("/parameters")
        }
        
        if !unexpectedRequests.isEmpty {
            let urls = unexpectedRequests.compactMap { $0.url?.absoluteString }.joined(separator: "\n")
            Issue.record("Unexpected requests captured:\n\(urls)")
        }
    }
    
    /// Assert async throwing operation throws specific error
    func assertThrowsError<T>(
        _ expression: () async throws -> T,
        expectedError: DifyError,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            Issue.record("Expected error \(expectedError) but no error was thrown", 
                        sourceLocation: SourceLocation(file: file, line: line))
        } catch {
            if let difyError = error as? DifyError {
                #expect(difyError == expectedError, 
                       "Expected error \(expectedError) but got \(difyError)")
            } else {
                Issue.record("Expected DifyError but got \(error)", 
                           sourceLocation: SourceLocation(file: file, line: line))
            }
        }
    }
    
    /// Wait for streaming events and collect them
    func collectStreamingEvents<T>(
        from stream: AsyncThrowingStream<T, Error>,
        maxEvents: Int = 10,
        timeout: TimeInterval = 5.0
    ) async throws -> [T] {
        var events: [T] = []
        let deadline = Date().addingTimeInterval(timeout)
        
        for try await event in stream {
            events.append(event)
            
            if events.count >= maxEvents {
                break
            }
            
            if Date() > deadline {
                Issue.record("Streaming timeout reached")
                break
            }
        }
        
        return events
    }
    
    /// Verify request headers
    func verifyRequestHeaders(
        _ request: URLRequest,
        expectedHeaders: [String: String]
    ) {
        for (key, expectedValue) in expectedHeaders {
            let actualValue = request.value(forHTTPHeaderField: key)
            #expect(actualValue == expectedValue,
                   "Header '\(key)' mismatch. Expected: '\(expectedValue)', Got: '\(actualValue ?? "nil")'")
        }
    }
    
    /// Verify request JSON body
    func verifyRequestBody<T: Decodable>(
        _ request: URLRequest,
        expectedType: T.Type,
        verification: (T) -> Void
    ) throws {
        guard let bodyData = request.httpBody else {
            Issue.record("Request has no body")
            return
        }
        
        let decoder = JSONDecoder.difyDecoder
        let decodedBody = try decoder.decode(T.self, from: bodyData)
        verification(decodedBody)
    }
}

// MARK: - Common Test Scenarios

extension DifyTestCase {
    
    /// Test successful API call
    func testSuccessfulResponse<T: Decodable>(
        client: DifyClient,
        endpoint: String,
        method: String = "GET",
        requestBody: Encodable? = nil,
        mockResponse: Any,
        expectedType: T.Type,
        verification: (T) -> Void
    ) async throws {
        // Setup mock
        MockURLProtocol.register(
            method: method,
            urlPattern: endpoint,
            response: MockResponse.json(mockResponse)
        )
        
        // Make request
        var request = try client.createRequest(endpoint: endpoint, method: method)
        if let body = requestBody {
            request.httpBody = try JSONEncoder.difyEncoder.encode(body)
        }
        
        let response: T = try await client.sendRequest(request)
        
        // Verify response
        verification(response)
        
        // Verify request was made
        TestUtilities.assertRequestCaptured(
            method: method,
            urlPattern: endpoint,
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    /// Test error response
    func testErrorResponse(
        client: DifyClient,
        endpoint: String,
        method: String = "GET",
        mockStatusCode: Int,
        mockErrorCode: String,
        mockErrorMessage: String,
        expectedError: DifyError
    ) async {
        // Setup mock
        MockURLProtocol.register(
            method: method,
            urlPattern: endpoint,
            response: MockResponse.error(
                statusCode: mockStatusCode,
                code: mockErrorCode,
                message: mockErrorMessage
            )
        )
        
        // Make request and expect error
        await assertThrowsError({
            let request = try client.createRequest(endpoint: endpoint, method: method)
            let _: [String: Any] = try await client.sendRequest(request)
        }, expectedError: expectedError)
    }
    
    /// Test streaming response
    func testStreamingResponse<T>(
        client: DifyClient,
        endpoint: String,
        method: String = "POST",
        requestBody: Encodable,
        mockEvents: [String],
        expectedEventCount: Int,
        eventVerification: ([T]) -> Void
    ) async throws where T: Decodable {
        // Setup mock
        MockURLProtocol.register(
            method: method,
            urlPattern: endpoint,
            response: MockResponse.streaming(mockEvents)
        )
        
        // Create request
        var request = try client.createRequest(endpoint: endpoint, method: method)
        request.httpBody = try JSONEncoder.difyEncoder.encode(requestBody)
        
        // Get streaming response
        let response = try await client.streamRequest(request)
        let stream = response.stream(T.self)
        
        // Collect events
        let events = try await collectStreamingEvents(from: stream, maxEvents: expectedEventCount)
        
        // Verify events
        #expect(events.count == expectedEventCount)
        eventVerification(events)
    }
}