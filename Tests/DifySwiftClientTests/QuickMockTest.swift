import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Quick Mock Infrastructure Test

@Suite("Quick Mock Infrastructure Test")
struct QuickMockInfrastructureTest {
    
    @Test("Basic mock URL protocol works")
    func testBasicMockURLProtocol() async throws {
        // Setup a simple mock
        MockURLProtocol.registerMock(
            endpoint: "test",
            response: MockURLProtocol.MockResponse.json(["status": "ok"])
        )
        defer { TestUtilities.cleanup() }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        let url = URL(string: "https://api.dify.ai/v1/test")!
        let request = URLRequest(url: url)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Issue.record("Expected HTTPURLResponse")
            return
        }
        
        #expect(httpResponse.statusCode == 200)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["status"] as? String == "ok")
    }
    
    @Test("Basic client creation works")
    func testBasicClientCreation() throws {
        let client = try TestUtilities.createMockDifyClient()
        #expect(client.apiKey == MockDataProvider.testApiKey)
    }
}