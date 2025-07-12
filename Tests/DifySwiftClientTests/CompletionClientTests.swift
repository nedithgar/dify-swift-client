import Foundation
import Testing
@testable import DifySwiftClient

@Suite("CompletionClient Tests", .serialized)
final class CompletionClientTests: DifyTestCase {
    
    @Test("Client Initialization")
    func testCompletionClientInitialization() async throws {
        let client = try CompletionClient(apiKey: "test-key")
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create Completion Message")
    func testCreateCompletionMessage() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.json(MockDataProvider.completionResponse)
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        let response = try await client.createCompletionMessage(
            inputs: ["query": "What is the capital of France?"],
            user: "user-123"
        )
        
        #expect(response.event == "message")
        #expect(response.messageId == "9da23599-e713-473b-982c-4328d4f5c78a")
        #expect(response.mode == "completion")
        #expect(response.answer == "The capital of France is Paris.")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            method: "POST",
            urlPattern: "/completion-messages",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Create Completion Message with Files")
    func testCreateCompletionMessageWithFiles() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.json(MockDataProvider.completionResponse)
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        let files = [
            APIFile(
                type: .image,
                transferMethod: .remoteUrl,
                url: "https://example.com/image.png"
            )
        ]
        
        let response = try await client.createCompletionMessage(
            inputs: ["query": "Describe this image"],
            user: "user-123",
            files: files
        )
        
        #expect(!response.messageId.isEmpty)
        
        // Verify request body contains files
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/completion-messages") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
           let filesArray = bodyJSON["files"] as? [[String: Any]] {
            #expect(filesArray.count == 1)
            #expect(filesArray[0]["type"] as? String == "image")
            #expect(filesArray[0]["transfer_method"] as? String == "remote_url")
        }
    }
    
    @Test("Create Streaming Completion Message")
    func testCreateStreamingCompletionMessage() async throws {
        // Register streaming mock response
        // Create streaming events for completion API
        let streamingEvents = [
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": "The", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": " capital", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": " of", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": " France", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": " is", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": " Paris.", "created_at": 1679586595}"#,
            #"data: {"event": "message_end", "task_id": "task-123", "message_id": "msg-123", "metadata": {"usage": {"prompt_tokens": 10, "completion_tokens": 8, "total_tokens": 18}}}"#
        ]
        
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/completion-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(streamingEvents)
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        let stream = try await client.createStreamingCompletionMessage(
            inputs: ["query": "What is the capital of France?"],
            user: "user-123"
        )
        
        var events: [StreamingCompletionResponse] = []
        for try await event in stream {
            events.append(event)
            if events.count >= 7 { // We have 7 events in the mock data
                break
            }
        }
        
        #expect(events.count == 7)
        
        // Verify message events
        let messageEvents = events.compactMap { event -> MessageStreamEvent? in
            if case .message(let msg) = event { return msg }
            return nil
        }
        #expect(messageEvents.count == 6)
        
        // Verify the accumulated answer
        let fullAnswer = messageEvents.map { $0.answer }.joined()
        #expect(fullAnswer == "The capital of France is Paris.")
        
        // Verify message_end event
        let endEvents = events.compactMap { event -> MessageEndStreamEvent? in
            if case .messageEnd(let end) = event { return end }
            return nil
        }
        #expect(endEvents.count == 1)
        #expect(endEvents.first?.metadata.usage?.totalTokens == 18)
    }
    
    @Test("Stop Completion Message")
    func testStopCompletionMessage() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/completion-messages/task-123/stop",
            response: MockResponse.json(["result": "success"])
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        let response = try await client.stopCompletionMessage(
            taskId: "task-123",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            method: "POST",
            urlPattern: "/completion-messages/task-123/stop"
        )
    }
    
    @Test("Upload File")
    func testUploadFile() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.png",
            user: "user-123"
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
        #expect(response.name == "example.png")
        #expect(response.size == 1024)
        #expect(response.fileExtension == "png")
        #expect(response.mimeType == "image/png")
    }
    
    @Test("Upload File with Custom MIME Type")
    func testUploadFileWithCustomMimeType() async throws {
        // Register mock response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.jpg",
            user: "user-123",
            mimeType: "image/jpeg"
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
        
        // Verify the correct MIME type was sent
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/files/upload") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let contentType = request.value(forHTTPHeaderField: "Content-Type") {
            #expect(contentType.contains("multipart/form-data"))
        }
    }
    
    @Test("Error Handling - Invalid Input")
    func testErrorHandlingInvalidInput() async throws {
        // Register error response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.error(
                statusCode: 400,
                code: "invalid_param",
                message: "Input parameter is required"
            )
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        await assertThrowsError({
            _ = try await client.createCompletionMessage(
                inputs: [:], // Empty inputs
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(400, "Input parameter is required"))
    }
    
    @Test("Error Handling - Rate Limit")
    func testErrorHandlingRateLimit() async throws {
        // Register rate limit error
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.error(
                statusCode: 429,
                code: "rate_limit_exceeded",
                message: "Rate limit exceeded"
            )
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        await assertThrowsError({
            _ = try await client.createCompletionMessage(
                inputs: ["query": "Hello"],
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(429, "Rate limit exceeded"))
    }
    
    @Test("Error Handling - File Too Large")
    func testErrorHandlingFileTooLarge() async throws {
        // Register error response
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.error(
                statusCode: 413,
                code: "file_too_large",
                message: "File size exceeds limit"
            )
        )
        
        let client = TestUtilities.createTestCompletionClient()
        
        await assertThrowsError({
            _ = try await client.uploadFile(
                fileData: Data(repeating: 0, count: 1024 * 1024 * 20), // 20MB
                fileName: "large-file.png",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(413, "File size exceeds limit"))
    }
}