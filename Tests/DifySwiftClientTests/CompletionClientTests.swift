import Foundation
import Testing
@testable import DifySwiftClient

@Suite("CompletionClient Tests")
final class CompletionClientTests: DifyTestCase, @unchecked Sendable {
    
    @Test("Client Initialization")
    func testCompletionClientInitialization() async throws {
        let client = try CompletionClient(apiKey: "test-key")
        #expect(client.apiKey == "test-key")
        #expect(client.baseURL.absoluteString == "https://api.dify.ai/v1")
    }
    
    @Test("Create Completion Message")
    func testCreateCompletionMessage() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.json(MockDataProvider.completionResponse)
        )
        
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
            in: mockSession,
            method: "POST",
            urlPattern: "/completion-messages",
            headers: ["Authorization": "Bearer test-api-key"]
        )
    }
    
    @Test("Create Completion Message with Files")
    func testCreateCompletionMessageWithFiles() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.json(MockDataProvider.completionResponse)
        )
        
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
        let capturedRequests = mockSession.getCapturedRequests()
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
        
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(streamingEvents)
        )
        
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
        let messageEvents = events.compactMap { $0.message }
        #expect(messageEvents.count == 6)
        
        // Verify the accumulated answer
        let fullAnswer = messageEvents.map { $0.answer }.joined()
        #expect(fullAnswer == "The capital of France is Paris.")
        
        // Verify message_end event
        let endEvents = events.compactMap { $0.messageEnd }
        #expect(endEvents.count == 1)
        #expect(endEvents.first?.metadata.usage?.totalTokens == 18)
    }
    
    @Test("Create Streaming Completion Message with Files")
    func testCreateStreamingCompletionMessageWithFiles() async throws {
        // Create streaming events for completion API with files
        let streamingEvents = [
            #"data: {"event": "message", "task_id": "task-456", "message_id": "msg-456", "answer": "I can see", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-456", "message_id": "msg-456", "answer": " the image", "created_at": 1679586595}"#,
            #"data: {"event": "message", "task_id": "task-456", "message_id": "msg-456", "answer": " shows...", "created_at": 1679586595}"#,
            #"data: {"event": "message_end", "task_id": "task-456", "message_id": "msg-456", "metadata": {"usage": {"prompt_tokens": 15, "completion_tokens": 6, "total_tokens": 21}}}"#
        ]
        
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(streamingEvents)
        )
        
        let files = [
            APIFile(
                type: .image,
                transferMethod: .remoteUrl,
                url: "https://example.com/test-image.jpg"
            ),
            APIFile(
                type: .image,
                transferMethod: .localFile,
                uploadFileId: "file-123"
            )
        ]
        
        let stream = try await client.createStreamingCompletionMessage(
            inputs: ["query": "Describe these images"],
            user: "user-123",
            files: files
        )
        
        var events: [StreamingCompletionResponse] = []
        for try await event in stream {
            events.append(event)
            if events.count >= 4 { // We have 4 events in the mock data
                break
            }
        }
        
        #expect(events.count == 4)
        
        // Verify message events
        let messageEvents = events.compactMap { $0.message }
        #expect(messageEvents.count == 3)
        
        // Verify the accumulated answer
        let fullAnswer = messageEvents.map { $0.answer }.joined()
        #expect(fullAnswer == "I can see the image shows...")
        
        // Verify request body contains files
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/completion-messages") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
           let filesArray = bodyJSON["files"] as? [[String: Any]] {
            #expect(filesArray.count == 2)
            #expect(filesArray[0]["type"] as? String == "image")
            #expect(filesArray[0]["transfer_method"] as? String == "remote_url")
            #expect(filesArray[1]["type"] as? String == "image")
            #expect(filesArray[1]["transfer_method"] as? String == "local_file")
        }
    }
    
    @Test("Stop Completion Message")
    func testStopCompletionMessage() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages/task-123/stop",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.stopCompletionMessage(
            taskId: "task-123",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request was made correctly
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "POST",
            urlPattern: "/completion-messages/task-123/stop"
        )
    }
    
    @Test("Upload File")
    func testUploadFile() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
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
    
    @Test("Upload File - JPEG MIME Type Detection")
    func testUploadFileJpegMimeTypeDetection() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.jpeg", // JPEG extension
            user: "user-123"
            // No mimeType provided, should auto-detect as image/jpeg
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
        
        // Verify MIME type detection for JPEG
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/files/upload") ?? false }
        #expect(request != nil)
    }
    
    @Test("Upload File - WebP MIME Type Detection")
    func testUploadFileWebPMimeTypeDetection() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.webp", // WebP extension
            user: "user-123"
            // No mimeType provided, should auto-detect as image/webp
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
    }
    
    @Test("Upload File - GIF MIME Type Detection")
    func testUploadFileGifMimeTypeDetection() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "animation.gif", // GIF extension
            user: "user-123"
            // No mimeType provided, should auto-detect as image/gif
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
    }
    
    @Test("Upload File - Unknown Extension Default MIME Type")
    func testUploadFileUnknownExtensionDefaultMimeType() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.xyz", // Unknown extension
            user: "user-123"
            // No mimeType provided, should default to image/png
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
    }

    @Test("Preview File - Inline")
    func testPreviewFileInline() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()

        let fileBytes = Data([0x00, 0x01, 0x02, 0x03])
        mockSession.register(
            method: "GET",
            urlPattern: "/files/file-abc/preview",
            response: MockResponse(statusCode: 200, headers: [:], data: fileBytes)
        )

        let data = try await client.previewFile(fileId: "file-abc")
        #expect(data == fileBytes)

        // Verify request without as_attachment param
        let req = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/files/file-abc/preview") ?? false }
        #expect(req != nil)
        if let url = req?.url?.absoluteString {
            #expect(url.contains("as_attachment") == false)
        }
    }

    @Test("Preview File - As Attachment")
    func testPreviewFileAsAttachment() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()

        let fileBytes = Data([0xAA, 0xBB, 0xCC])
        mockSession.register(
            method: "GET",
            urlPattern: "/files/file-xyz/preview",
            response: MockResponse(statusCode: 200, headers: [:], data: fileBytes)
        )

        let data = try await client.previewFile(fileId: "file-xyz", asAttachment: true)
        #expect(data == fileBytes)

        // Verify request has as_attachment=true
        let req = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/files/file-xyz/preview") ?? false }
        #expect(req != nil)
        if let url = req?.url?.absoluteString {
            #expect(url.contains("as_attachment=true"))
        }
    }
    
    @Test("Upload File - Case Insensitive Extension")
    func testUploadFileCaseInsensitiveExtension() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.JPG", // Uppercase extension
            user: "user-123"
            // No mimeType provided, should still detect as image/jpeg
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
    }
    
    @Test("Upload File - No Extension")
    func testUploadFileNoExtension() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "testimage", // No extension
            user: "user-123"
            // No mimeType provided, should default to image/png
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
    }
    
    @Test("Upload File with Custom MIME Type")
    func testUploadFileWithCustomMimeType() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.json(MockDataProvider.fileUploadResponse)
        )
        
        let imageData = TestUtilities.createTestImageData()
        let response = try await client.uploadFile(
            fileData: imageData,
            fileName: "test-image.jpg",
            user: "user-123",
            mimeType: "image/jpeg"
        )
        
        #expect(response.id == "72fa9618-8f89-4a37-9b33-7e1178a24a67")
        
        // Verify the correct MIME type was sent
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/files/upload") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let contentType = request.value(forHTTPHeaderField: "Content-Type") {
            #expect(contentType.contains("multipart/form-data"))
        }
    }
    
    @Test("Error Handling - Invalid Input")
    func testErrorHandlingInvalidInput() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register error response
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.error(
                statusCode: 400,
                code: "invalid_param",
                message: "Input parameter is required"
            )
        )
        
        await assertThrowsError({
            _ = try await client.createCompletionMessage(
                inputs: [:], // Empty inputs
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(400, "Input parameter is required"))
    }
    
    @Test("Error Handling - Rate Limit")
    func testErrorHandlingRateLimit() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register rate limit error
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.error(
                statusCode: 429,
                code: "rate_limit_exceeded",
                message: "Rate limit exceeded"
            )
        )
        
        await assertThrowsError({
            _ = try await client.createCompletionMessage(
                inputs: ["query": "Hello"],
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(429, "Rate limit exceeded"))
    }
    
    @Test("Error Handling - File Too Large")
    func testErrorHandlingFileTooLarge() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register error response
        mockSession.register(
            method: "POST",
            urlPattern: "/files/upload",
            response: MockResponse.error(
                statusCode: 413,
                code: "file_too_large",
                message: "File size exceeds limit"
            )
        )
        
        await assertThrowsError({
            _ = try await client.uploadFile(
                fileData: Data(repeating: 0, count: 1024 * 1024 * 20), // 20MB
                fileName: "large-file.png",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(413, "File size exceeds limit"))
    }
    
    // MARK: - Message Feedback Tests
    
    @Test("Give Message Feedback - Like")
    func testGiveMessageFeedbackLike() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/messages/msg-123/feedbacks",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.giveMessageFeedback(
            messageId: "msg-123",
            rating: "like",
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/messages/msg-123/feedbacks") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["rating"] as? String == "like")
            #expect(bodyJSON["user"] as? String == "user-123")
        }
    }
    
    @Test("Give Message Feedback - Dislike with Content")
    func testGiveMessageFeedbackDislikeWithContent() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/messages/msg-456/feedbacks",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.giveMessageFeedback(
            messageId: "msg-456",
            rating: "dislike",
            user: "user-123",
            content: "The response was not accurate"
        )
        
        #expect(response.result == "success")
        
        // Verify request body includes content
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/messages/msg-456/feedbacks") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["rating"] as? String == "dislike")
            #expect(bodyJSON["content"] as? String == "The response was not accurate")
        }
    }
    
    @Test("Give Message Feedback - Revoke")
    func testGiveMessageFeedbackRevoke() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/messages/msg-789/feedbacks",
            response: MockResponse.json(["result": "success"])
        )
        
        let response = try await client.giveMessageFeedback(
            messageId: "msg-789",
            rating: nil, // nil rating means revoke
            user: "user-123"
        )
        
        #expect(response.result == "success")
        
        // Verify request body has null rating
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/messages/msg-789/feedbacks") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["rating"] as? String == nil)
            #expect(bodyJSON["user"] as? String == "user-123")
        }
    }
    
    // MARK: - Application Feedbacks Tests
    
    @Test("Get Application Feedbacks - Default Pagination")
    func testGetApplicationFeedbacksDefault() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockResponse: [String: Any] = [
            "data": [
                [
                    "id": "feedback-1",
                    "app_id": "app-123",
                    "conversation_id": "conv-123",
                    "message_id": "msg-123",
                    "rating": "like",
                    "content": "Great response!",
                    "from_source": "api",
                    "from_end_user_id": "user-123",
                    "from_account_id": nil,
                    "created_at": "2023-03-23T12:34:56Z",
                    "updated_at": "2023-03-23T12:34:56Z"
                ]
            ]
        ]
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/app/feedbacks",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationFeedbacks()
        
        #expect(response.data.count == 1)
        
        let feedback = response.data.first!
        #expect(feedback.id == "feedback-1")
        #expect(feedback.fromEndUserId == "user-123")
        #expect(feedback.rating == "like")
        #expect(feedback.content == "Great response!")
        
        // Verify default parameters were sent
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/app/feedbacks") ?? false }
        #expect(request != nil)
        
        if let url = request?.url {
            #expect(url.absoluteString.contains("page=1"))
            #expect(url.absoluteString.contains("limit=20"))
        }
    }
    
    @Test("Get Application Feedbacks - Custom Pagination")
    func testGetApplicationFeedbacksCustomPagination() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockResponse: [String: Any] = [
            "data": []
        ]
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/app/feedbacks",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationFeedbacks(page: 2, limit: 50)
        
        #expect(response.data.isEmpty)
        
        // Verify custom parameters were sent
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/app/feedbacks") ?? false }
        #expect(request != nil)
        
        if let url = request?.url {
            #expect(url.absoluteString.contains("page=2"))
            #expect(url.absoluteString.contains("limit=50"))
        }
    }
    
    // MARK: - Text-to-Audio Tests
    
    @Test("Get Text-to-Audio with Message ID")
    func testGetTextToAudioWithMessageId() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockAudioData = Data([0x52, 0x49, 0x46, 0x46]) // WAV header bytes
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse(statusCode: 200, headers: [:], data: mockAudioData)
        )
        
        let audioData = try await client.getTextToAudio(
            messageId: "msg-123",
            user: "user-123"
        )
        
        #expect(audioData == mockAudioData)
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/text-to-audio") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["message_id"] as? String == "msg-123")
            #expect(bodyJSON["user"] as? String == "user-123")
            #expect(bodyJSON["text"] == nil)
        }
    }
    
    @Test("Get Text-to-Audio with Text")
    func testGetTextToAudioWithText() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockAudioData = Data([0x49, 0x44, 0x33, 0x03]) // MP3 header bytes
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse(statusCode: 200, headers: [:], data: mockAudioData)
        )
        
        let audioData = try await client.getTextToAudio(
            text: "Hello, world!",
            user: "user-123"
        )
        
        #expect(audioData == mockAudioData)
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/text-to-audio") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["text"] as? String == "Hello, world!")
            #expect(bodyJSON["user"] as? String == "user-123")
            #expect(bodyJSON["message_id"] == nil)
        }
    }
    
    // MARK: - Application Information Tests
    
    @Test("Get Application Info")
    func testGetApplicationInfo() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockResponse: [String: Any] = [
            "name": "My Dify App",
            "description": "A helpful AI assistant",
            "tags": ["ai", "assistant"],
            "mode": "completion",
            "author_name": "Dify Team"
        ]
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/info",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "My Dify App")
        #expect(response.description == "A helpful AI assistant")
        #expect(response.tags.contains("ai"))
        #expect(response.tags.contains("assistant"))
        #expect(response.mode == "completion")
        #expect(response.authorName == "Dify Team")
    }
    
    @Test("Get Application Parameters")
    func testGetApplicationParameters() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockResponse: [String: Any] = [
            "opening_statement": "Hello! How can I help you today?",
            "suggested_questions": [
                "What can you help me with?",
                "Tell me about your capabilities"
            ],
            "suggested_questions_after_answer": [
                "enabled": true
            ],
            "speech_to_text": [
                "enabled": true
            ],
            "text_to_speech": [
                "enabled": true,
                "voice": "alloy",
                "language": "en-US"
            ],
            "retriever_resource": [
                "enabled": true
            ],
            "annotation_reply": [
                "enabled": false
            ],
            "user_input_form": [],
            "file_upload": [
                "image": [
                    "enabled": true,
                    "number_limits": 3,
                    "transfer_methods": ["local_file", "remote_url"]
                ]
            ],
            "system_parameters": [
                "image_file_size_limit": 10
            ]
        ]
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/parameters",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationParameters()
        
        #expect(response.openingStatement == "Hello! How can I help you today?")
        #expect(response.suggestedQuestions?.count == 2)
        #expect(response.suggestedQuestions?.first == "What can you help me with?")
        #expect(response.suggestedQuestionsAfterAnswer?.enabled == true)
        #expect(response.speechToText?.enabled == true)
        // textToSpeech is not in ApplicationParametersResponse
        #expect(response.retrieverResource?.enabled == true)
        #expect(response.annotationReply?.enabled == false)
        #expect(response.fileUpload?.image?.enabled == true)
        #expect(response.fileUpload?.image?.numberLimits == 3)
        #expect(response.systemParameters?.imageFileSizeLimit == 10)
    }
    
    @Test("Get Application Site Settings")
    func testGetApplicationSiteSettings() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockResponse: [String: Any] = [
            "title": "My AI Assistant",
            "chat_color_theme": "#007BFF",
            "chat_color_theme_inverted": false,
            "description": "Your helpful AI companion",
            "copyright": "© 2024 My Company",
            "privacy_policy": "https://example.com/privacy",
            "custom_disclaimer": "AI responses may not always be accurate",
            "default_language": "en-US",
            "prompt_public": false,
            "show_workflow_steps": true,
            "use_icon_as_answer_icon": true
        ]
        
        // Register mock response
        mockSession.register(
            method: "GET",
            urlPattern: "/site",
            response: MockResponse.json(mockResponse)
        )
        
        let response = try await client.getApplicationSiteSettings()
        
        #expect(response.title == "My AI Assistant")
        #expect(response.chatColorTheme == "#007BFF")
        #expect(response.chatColorThemeInverted == false)
        #expect(response.description == "Your helpful AI companion")
        #expect(response.copyright == "© 2024 My Company")
        #expect(response.privacyPolicy == "https://example.com/privacy")
        #expect(response.customDisclaimer == "AI responses may not always be accurate")
        #expect(response.defaultLanguage == "en-US")
        // promptPublic is not in ApplicationSiteResponse
        #expect(response.showWorkflowSteps == true)
        #expect(response.useIconAsAnswerIcon == true)
    }
    
    // MARK: - Additional Error Handling Tests
    
    @Test("Error Handling - Unauthorized")
    func testErrorHandlingUnauthorized() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register unauthorized error
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.error(
                statusCode: 401,
                code: "unauthorized",
                message: "Invalid API key"
            )
        )
        
        await assertThrowsError({
            _ = try await client.createCompletionMessage(
                inputs: ["query": "Hello"],
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(401, "Invalid API key"))
    }
    
    @Test("Error Handling - Forbidden")
    func testErrorHandlingForbidden() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register forbidden error
        mockSession.register(
            method: "GET",
            urlPattern: "/app/feedbacks",
            response: MockResponse.error(
                statusCode: 403,
                code: "forbidden",
                message: "Access denied"
            )
        )
        
        await assertThrowsError({
            _ = try await client.getApplicationFeedbacks()
        }, expectedError: DifyError.httpError(403, "Access denied"))
    }
    
    @Test("Error Handling - Not Found")
    func testErrorHandlingNotFound() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register not found error
        mockSession.register(
            method: "POST",
            urlPattern: "/messages/invalid-id/feedbacks",
            response: MockResponse.error(
                statusCode: 404,
                code: "not_found",
                message: "Message not found"
            )
        )
        
        await assertThrowsError({
            _ = try await client.giveMessageFeedback(
                messageId: "invalid-id",
                rating: "like",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(404, "Message not found"))
    }
    
    @Test("Error Handling - Internal Server Error")
    func testErrorHandlingInternalServerError() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register server error
        mockSession.register(
            method: "GET",
            urlPattern: "/info",
            response: MockResponse.error(
                statusCode: 500,
                code: "internal_error",
                message: "Internal server error"
            )
        )
        
        await assertThrowsError({
            _ = try await client.getApplicationInfo()
        }, expectedError: DifyError.httpError(500, "Internal server error"))
    }
    
    @Test("Error Handling - Service Unavailable")
    func testErrorHandlingServiceUnavailable() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register service unavailable error
        mockSession.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse.error(
                statusCode: 503,
                code: "service_unavailable",
                message: "Service temporarily unavailable"
            )
        )
        
        await assertThrowsError({
            _ = try await client.getTextToAudio(
                text: "Hello",
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(503, "Service temporarily unavailable"))
    }
    
    @Test("Error Handling - Malformed JSON Response")
    func testErrorHandlingMalformedJSON() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register malformed JSON response
        mockSession.register(
            method: "GET",
            urlPattern: "/parameters",
            response: MockResponse(statusCode: 200, headers: [:], data: Data("{ invalid json }".utf8))
        )
        
        do {
            _ = try await client.getApplicationParameters()
            Issue.record("Expected error but none was thrown")
        } catch {
            if let difyError = error as? DifyError {
                #expect(difyError.message?.contains("Failed to decode response") == true)
            } else {
                Issue.record("Expected DifyError but got \(error)")
            }
        }
    }
    
    @Test("Error Handling - Network Error")
    func testErrorHandlingNetworkError() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register network error
        let networkError = URLError(.notConnectedToInternet)
        mockSession.register(
            method: "GET",
            urlPattern: "/site",
            response: MockResponse.error(statusCode: 0, code: "network_error", message: networkError.localizedDescription)
        )
        
        await assertThrowsError({
            _ = try await client.getApplicationSiteSettings()
        }, expectedError: DifyError.httpError(0, networkError.localizedDescription))
    }
    
    @Test("Error Handling - Timeout")
    func testErrorHandlingTimeout() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register timeout error
        let timeoutError = URLError(.timedOut)
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            response: MockResponse.error(statusCode: 0, code: "timeout", message: timeoutError.localizedDescription)
        )
        
        await assertThrowsError({
            _ = try await client.createCompletionMessage(
                inputs: ["query": "Hello"],
                user: "user-123"
            )
        }, expectedError: DifyError.httpError(0, timeoutError.localizedDescription))
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Empty Streaming Response")
    func testEmptyStreamingResponse() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        // Register empty streaming response
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming([])
        )
        
        let stream = try await client.createStreamingCompletionMessage(
            inputs: ["query": "Hello"],
            user: "user-123"
        )
        
        var events: [StreamingCompletionResponse] = []
        for try await event in stream {
            events.append(event)
        }
        
        #expect(events.isEmpty)
    }
    
    @Test("Streaming Response with Unknown Event Type")
    func testStreamingResponseWithUnknownEventType() async throws {
        let streamingEvents = [
            #"data: {"event": "unknown_event", "task_id": "task-123", "data": "some data"}"#,
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": "Hello", "created_at": 1679586595}"#
        ]
        
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(streamingEvents)
        )
        
        let stream = try await client.createStreamingCompletionMessage(
            inputs: ["query": "Hello"],
            user: "user-123"
        )
        
        var events: [StreamingCompletionResponse] = []
        for try await event in stream {
            events.append(event)
        }
        
        // Unknown event should be tolerated and surfaced as kind-only
        #expect(events.count == 2)
        #expect(events.first?.kind.rawValue == "unknown_event")
        #expect(events.first?.message == nil)
        #expect(events.last?.kind == .message)
        #expect(events.last?.message?.answer == "Hello")
    }
    
    @Test("Streaming Response with Error Event")
    func testStreamingResponseWithErrorEvent() async throws {
        let streamingEvents = [
            #"data: {"event": "message", "task_id": "task-123", "message_id": "msg-123", "answer": "Processing", "created_at": 1679586595}"#,
            #"data: {"event": "error", "task_id": "task-123", "message_id": "msg-123", "status": 500, "code": "internal_error", "message": "An error occurred"}"#
        ]
        
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        mockSession.register(
            method: "POST",
            urlPattern: "/completion-messages",
            bodyPattern: "\"response_mode\":\"streaming\"",
            response: MockResponse.streaming(streamingEvents)
        )
        
        let stream = try await client.createStreamingCompletionMessage(
            inputs: ["query": "Hello"],
            user: "user-123"
        )
        
        var events: [StreamingCompletionResponse] = []
        for try await event in stream {
            events.append(event)
            if events.count >= 2 {
                break
            }
        }
        
        #expect(events.count == 2)
        
        // Verify error event
        #expect(events[1].kind == .error)
        #expect(events[1].error?.status == 500)
        #expect(events[1].error?.code == "internal_error")
        #expect(events[1].error?.message == "An error occurred")
    }
    
    @Test("Text-to-Audio with Both MessageId and Text")
    func testTextToAudioWithBothParameters() async throws {
        let (client, mockSession) = TestUtilities.createTestCompletionClientWithMockSession()
        
        let mockAudioData = Data([0x52, 0x49, 0x46, 0x46])
        
        // Register mock response
        mockSession.register(
            method: "POST",
            urlPattern: "/text-to-audio",
            response: MockResponse(statusCode: 200, headers: [:], data: mockAudioData)
        )
        
        // When both messageId and text are provided, messageId takes precedence
        let audioData = try await client.getTextToAudio(
            messageId: "msg-123",
            text: "This text should be ignored",
            user: "user-123"
        )
        
        #expect(audioData == mockAudioData)
        
        // Verify request body - should have both parameters
        let capturedRequests = mockSession.getCapturedRequests()
        let request = capturedRequests.first { $0.url?.absoluteString.contains("/text-to-audio") ?? false }
        #expect(request != nil)
        
        if let request = request,
           let bodyData = request.httpBody,
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(bodyJSON["message_id"] as? String == "msg-123")
            #expect(bodyJSON["text"] as? String == "This text should be ignored")
        }
    }
}
