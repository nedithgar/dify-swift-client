import Foundation
import Testing
@testable import DifySwiftClient

@Suite("Isolated Mock Session Tests")
final class IsolatedMockSessionTests: @unchecked Sendable {
    
    @Test("Parallel Isolation Test")
    func testParallelIsolation() async throws {
        // Create two separate mock sessions
        let (client1, mockSession1) = TestUtilities.createTestChatClientWithMockSession()
        let (client2, mockSession2) = TestUtilities.createTestChatClientWithMockSession()
        
        // Register different responses for each session
        mockSession1.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(["message": "Response from session 1"])
        )
        
        mockSession2.register(
            method: "POST",
            urlPattern: "/chat-messages",
            response: MockResponse.json(["message": "Response from session 2"])
        )
        
        // Make requests in parallel
        let requestBody = ["query": "test", "user": "user1"]
        
        async let response1 = client1.sendRequest(method: .POST, endpoint: "/chat-messages", body: requestBody)
        async let response2 = client2.sendRequest(method: .POST, endpoint: "/chat-messages", body: requestBody)
        
        // Verify responses
        let data1 = try await response1
        let data2 = try await response2
        
        let json1 = try JSONSerialization.jsonObject(with: data1) as? [String: Any]
        let json2 = try JSONSerialization.jsonObject(with: data2) as? [String: Any]
        
        let message1 = json1?["message"] as? String
        let message2 = json2?["message"] as? String
        
        #expect(message1 == "Response from session 1")
        #expect(message2 == "Response from session 2")
        
        // Verify each session captured only its own request
        let requests1 = mockSession1.getCapturedRequests()
        let requests2 = mockSession2.getCapturedRequests()
        
        #expect(requests1.count == 1)
        #expect(requests2.count == 1)
    }
    
    @Test("Session Reset Test")
    func testSessionReset() async throws {
        let mockSession = IsolatedMockSession()
        
        // Register a mock
        mockSession.register(
            method: "GET",
            urlPattern: "/test",
            response: MockResponse.json(["status": "ok"])
        )
        
        // Create a client with this session
        let client = try DifyClient(apiKey: "test", session: mockSession.urlSession)
        
        // Make a request
        _ = try await client.sendRequest(method: .GET, endpoint: "/test")
        
        // Verify request was captured
        #expect(mockSession.getCapturedRequests().count == 1)
        
        // Reset the session
        mockSession.reset()
        
        // Verify everything is cleared
        #expect(mockSession.getCapturedRequests().count == 0)
        
        // Try to make another request - should fail since mocks are cleared
        do {
            _ = try await client.sendRequest(method: .GET, endpoint: "/test")
            Issue.record("Expected request to fail after reset")
        } catch {
            // Expected to fail
            let nsError = error as NSError
            #expect(nsError.domain == "IsolatedMockURLProtocol")
        }
    }
}