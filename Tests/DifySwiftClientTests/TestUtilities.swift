import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Test Utilities

/// Helper functions for setting up tests and creating mock clients
struct TestUtilities {
    
    // MARK: - Mock Client Creation
    
    /// Create a DifyClient with mock URLSession
    static func createMockDifyClient(apiKey: String = "test-api-key") throws -> DifyClient {
        let mockSession = MockURLSessionFactory.createMockSession()
        return try DifyClient(apiKey: apiKey, session: mockSession)
    }
    
    /// Create a ChatClient with mock URLSession
    static func createMockChatClient(apiKey: String = "test-api-key") throws -> ChatClient {
        let mockSession = MockURLSessionFactory.createMockSession()
        return try ChatClient(apiKey: apiKey, session: mockSession)
    }
    
    /// Create a CompletionClient with mock URLSession
    static func createMockCompletionClient(apiKey: String = "test-api-key") throws -> CompletionClient {
        let mockSession = MockURLSessionFactory.createMockSession()
        return try CompletionClient(apiKey: apiKey, session: mockSession)
    }
    
    /// Create a WorkflowClient with mock URLSession
    static func createMockWorkflowClient(apiKey: String = "test-api-key") throws -> WorkflowClient {
        let mockSession = MockURLSessionFactory.createMockSession()
        return try WorkflowClient(apiKey: apiKey, session: mockSession)
    }
    
    /// Create a KnowledgeBaseClient with mock URLSession
    static func createMockKnowledgeBaseClient(apiKey: String = "test-api-key") throws -> KnowledgeBaseClient {
        let mockSession = MockURLSessionFactory.createMockSession()
        return try KnowledgeBaseClient(apiKey: apiKey, session: mockSession)
    }
    
    // MARK: - Test Setup and Teardown
    
    /// Setup method to be called before each test
    static func setUp() {
        MockURLProtocol.reset()
        MockStreamingURLProtocol.reset()
    }
    
    /// Teardown method to be called after each test
    static func tearDown() {
        MockURLProtocol.reset()
        MockStreamingURLProtocol.reset()
    }
    
    // MARK: - Test Data Helpers
    
    /// Create test file data
    static func createTestFileData(size: Int = 1024) -> Data {
        return Data(repeating: 0x42, count: size)
    }
    
    /// Create test image data (PNG)
    static func createTestImageData() -> Data {
        // Minimal PNG header
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        return Data(pngHeader + Array(repeating: 0x00, count: 100))
    }
    
    /// Create test audio data
    static func createTestAudioData() -> Data {
        return Data(repeating: 0x44, count: 1000)
    }
    
    /// Create test API file
    static func createTestAPIFile(type: FileType = .document, transferMethod: FileTransferMethod = .localFile) -> APIFile {
        return APIFile(
            type: type,
            transferMethod: transferMethod,
            url: transferMethod == .remoteUrl ? "https://example.com/file.txt" : nil,
            uploadFileId: transferMethod == .localFile ? "upload-123" : nil
        )
    }
    
    /// Create test process rule
    static func createTestProcessRule(mode: String = "automatic") -> ProcessRule {
        return ProcessRule(
            mode: mode,
            rules: mode == "custom" ? ["max_tokens": "1000"] : nil
        )
    }
    
    // MARK: - Assertion Helpers
    
    /// Assert that two dictionaries are equal
    static func assertDictionariesEqual<K: Hashable, V: Equatable>(_ dict1: [K: V], _ dict2: [K: V], file: StaticString = #file, line: UInt = #line) {
        #expect(dict1.count == dict2.count, "Dictionary counts don't match", sourceLocation: SourceLocation(file: file, line: line))
        
        for (key, value) in dict1 {
            #expect(dict2[key] == value, "Values for key '\(key)' don't match", sourceLocation: SourceLocation(file: file, line: line))
        }
    }
    
    /// Assert that a URL contains expected query parameters
    static func assertURLContainsParameters(_ url: URL, expectedParams: [String: String], file: StaticString = #file, line: UInt = #line) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            #expect(Bool(false), "URL should contain query parameters", sourceLocation: SourceLocation(file: file, line: line))
            return
        }
        
        let actualParams = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        assertDictionariesEqual(actualParams, expectedParams, file: file, line: line)
    }
    
    /// Assert that a request has expected headers
    static func assertRequestHasHeaders(_ request: URLRequest, expectedHeaders: [String: String], file: StaticString = #file, line: UInt = #line) {
        for (key, expectedValue) in expectedHeaders {
            let actualValue = request.value(forHTTPHeaderField: key)
            #expect(actualValue == expectedValue, "Header '\(key)' should be '\(expectedValue)' but was '\(actualValue ?? "nil")'", sourceLocation: SourceLocation(file: file, line: line))
        }
    }
    
    /// Assert that a request has expected HTTP method
    static func assertRequestHasMethod(_ request: URLRequest, expectedMethod: HTTPMethod, file: StaticString = #file, line: UInt = #line) {
        #expect(request.httpMethod == expectedMethod.rawValue, "HTTP method should be '\(expectedMethod.rawValue)' but was '\(request.httpMethod ?? "nil")'", sourceLocation: SourceLocation(file: file, line: line))
    }
    
    /// Assert that a request has expected endpoint
    static func assertRequestHasEndpoint(_ request: URLRequest, expectedEndpoint: String, file: StaticString = #file, line: UInt = #line) {
        guard let url = request.url else {
            #expect(Bool(false), "Request should have a URL", sourceLocation: SourceLocation(file: file, line: line))
            return
        }
        
        #expect(url.path == expectedEndpoint, "Request endpoint should be '\(expectedEndpoint)' but was '\(url.path)'", sourceLocation: SourceLocation(file: file, line: line))
    }
    
    // MARK: - Streaming Test Helpers
    
    /// Collect all items from an AsyncThrowingStream
    static func collectStreamItems<T>(_ stream: AsyncThrowingStream<T, Error>) async throws -> [T] {
        var items: [T] = []
        
        for try await item in stream {
            items.append(item)
        }
        
        return items
    }
    
    /// Collect limited number of items from an AsyncThrowingStream
    static func collectStreamItems<T>(_ stream: AsyncThrowingStream<T, Error>, limit: Int) async throws -> [T] {
        var items: [T] = []
        var count = 0
        
        for try await item in stream {
            items.append(item)
            count += 1
            if count >= limit {
                break
            }
        }
        
        return items
    }
    
    // MARK: - Error Testing Helpers
    
    /// Test that an async function throws a specific error
    static func assertThrowsError<T: Error & Equatable>(_ expectedError: T, _ operation: () async throws -> Void, file: StaticString = #file, line: UInt = #line) async {
        do {
            try await operation()
            #expect(Bool(false), "Operation should have thrown an error", sourceLocation: SourceLocation(file: file, line: line))
        } catch let error as T {
            #expect(error == expectedError, "Expected error '\(expectedError)' but got '\(error)'", sourceLocation: SourceLocation(file: file, line: line))
        } catch {
            #expect(Bool(false), "Expected error of type '\(T.self)' but got '\(type(of: error))'", sourceLocation: SourceLocation(file: file, line: line))
        }
    }
    
    /// Test that an async function throws any error
    static func assertThrowsAnyError(_ operation: () async throws -> Void, file: StaticString = #file, line: UInt = #line) async {
        do {
            try await operation()
            #expect(Bool(false), "Operation should have thrown an error", sourceLocation: SourceLocation(file: file, line: line))
        } catch {
            // Expected to throw
        }
    }
    
    /// Test that an async function does not throw
    static func assertDoesNotThrow(_ operation: () async throws -> Void, file: StaticString = #file, line: UInt = #line) async {
        do {
            try await operation()
        } catch {
            #expect(Bool(false), "Operation should not have thrown an error but threw: \(error)", sourceLocation: SourceLocation(file: file, line: line))
        }
    }
    
    // MARK: - Performance Testing
    
    /// Measure the execution time of an async operation
    static func measureTime<T>(_ operation: () async throws -> T) async rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let endTime = Date()
        return (result, endTime.timeIntervalSince(startTime))
    }
    
    // MARK: - JSON Testing Helpers
    
    /// Parse JSON string to dictionary
    static func parseJSONToDictionary(_ jsonString: String) throws -> [String: Any] {
        guard let data = jsonString.data(using: .utf8) else {
            throw DifyError.decodingError(NSError(domain: "TestError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"]))
        }
        
        return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
    
    /// Compare JSON objects for equality
    static func compareJSONObjects(_ obj1: Any, _ obj2: Any) -> Bool {
        if let data1 = try? JSONSerialization.data(withJSONObject: obj1, options: [.sortedKeys]),
           let data2 = try? JSONSerialization.data(withJSONObject: obj2, options: [.sortedKeys]) {
            return data1 == data2
        }
        return false
    }
}