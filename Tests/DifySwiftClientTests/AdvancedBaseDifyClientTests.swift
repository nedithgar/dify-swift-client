import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Advanced Base Dify Client Mock Tests

@Suite("Advanced Base Dify Client Mock Tests")
struct AdvancedBaseDifyClientMockTests {
    
    @Test("Send message feedback")
    func testMessageFeedback() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.messageFeedback(
            messageId: MockDataProvider.testMessageId,
            rating: "like",
            user: MockTestConfig.user
        )
        
        #expect(response.result == "success")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "messages/\(MockDataProvider.testMessageId)/feedbacks",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable, Sendable {
            let rating: String
            let user: String
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.rating == "like")
        #expect(requestBody.user == MockTestConfig.user)
    }
    
    @Test("Get application parameters")
    func testGetApplicationParameters() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getApplicationParameters(user: MockTestConfig.user)
        
        #expect(response.userInputForm.isEmpty) // Mock returns empty array
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "parameters",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("user=\(MockTestConfig.user)"))
    }
    
    @Test("Upload file")
    func testUploadFile() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let fileData = TestUtilities.createTestFileData(size: 2048)
        
        let response = try await client.uploadFile(
            user: MockTestConfig.user,
            fileData: fileData,
            filename: "test-upload.pdf",
            mimeType: "application/pdf"
        )
        
        #expect(response.id == "file-upload-123")
        #expect(response.name == "test-file.pdf")
        #expect(response.size == 1024)
        #expect(response.fileExtension == "pdf")
        #expect(response.mimeType == "application/pdf")
        #expect(response.createdBy == MockTestConfig.user)
    }
    
    @Test("Convert text to audio")
    func testTextToAudio() async throws {
        MockURLProtocol.registerMock(
            endpoint: "text-to-audio",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.textToAudioResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.textToAudio(
            text: "Hello, this is a test message for audio conversion.",
            user: MockTestConfig.user,
            streaming: false
        )
        
        #expect(response.taskId == "audio-task-123")
        #expect(response.audio?.starts(with: "data:audio/wav;base64,") == true)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "text-to-audio",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable, Sendable {
            let text: String
            let user: String
            let streaming: Bool
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.text == "Hello, this is a test message for audio conversion.")
        #expect(requestBody.user == MockTestConfig.user)
        #expect(requestBody.streaming == false)
    }
    
    @Test("Get meta information")
    func testGetMeta() async throws {
        let metaResponse: [String: Any] = [
            "tool": [
                "labels": [
                    "dalle2": "DALL-E 2",
                    "web_reader": "Web Reader"
                ]
            ]
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "meta",
            response: MockURLProtocol.MockResponse.json(metaResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getMeta(user: MockTestConfig.user)
        
        #expect(response.tool.labels["dalle2"] == "DALL-E 2")
        #expect(response.tool.labels["web_reader"] == "Web Reader")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "meta",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("user=\(MockTestConfig.user)"))
    }
    
    @Test("Get application info")
    func testGetApplicationInfo() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.getApplicationInfo()
        
        #expect(response.name == "Test Application")
        #expect(response.description == "A test application for mock testing")
        #expect(response.tags == ["test", "mock"])
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test("Get enhanced application parameters")
    func testGetEnhancedApplicationParameters() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getEnhancedApplicationParameters(user: MockTestConfig.user)
        
        #expect(response.openingStatement == "Welcome to our test application!")
        #expect(response.suggestedQuestions?.count == 2)
        #expect(response.suggestedQuestions?[0] == "How does this work?")
        #expect(response.suggestedQuestionsAfterAnswer?.enabled == true)
        #expect(response.speechToText?.enabled == false)
        #expect(response.textToSpeech?.enabled == true)
        #expect(response.textToSpeech?.voice == "alloy")
        #expect(response.textToSpeech?.language == "en-US")
        #expect(response.retrieverResource?.enabled == true)
        #expect(response.annotationReply?.enabled == false)
        #expect(response.fileUpload?.image?.enabled == true)
        #expect(response.fileUpload?.image?.numberLimits == 3)
        #expect(response.fileUpload?.image?.transferMethods == ["remote_url", "local_file"])
        #expect(response.systemParameters?.fileSizeLimit == 15)
        #expect(response.systemParameters?.imageSizeLimit == 10)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "parameters",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("user=\(MockTestConfig.user)"))
    }
    
    @Test("Get enhanced application parameters without user")
    func testGetEnhancedApplicationParametersWithoutUser() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getEnhancedApplicationParameters()
        
        #expect(response.openingStatement == "Welcome to our test application!")
        
        // Validate that no user parameter was sent
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "parameters",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(!query.contains("user="))
    }
    
    @Test("Get application meta")
    func testGetApplicationMeta() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.getApplicationMeta()
        
        #expect(response.toolIcons.count == 2)
        
        // Check different tool icon types
        if case .icon(let iconObject) = response.toolIcons["dalle2"] {
            #expect(iconObject.background == "#252530")
            #expect(iconObject.content == "🎨")
        } else {
            Issue.record("Expected icon object for dalle2")
        }
        
        if case .url(let urlString) = response.toolIcons["web_reader"] {
            #expect(urlString == "https://example.com/icon.png")
        } else {
            Issue.record("Expected URL string for web_reader")
        }
    }
    
    @Test("Get application site")
    func testGetApplicationSite() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.getApplicationSite()
        
        #expect(response.title == "Test Chat App")
        #expect(response.chatColorTheme == "indigo")
        #expect(response.chatColorThemeInverted == false)
        #expect(response.iconType == "emoji")
        #expect(response.icon == "🤖")
        #expect(response.iconBackground == "#FFEAD5")
        #expect(response.description == "A test chat application")
        #expect(response.copyright == "© 2024 Test Company")
        #expect(response.privacyPolicy == "https://example.com/privacy")
        #expect(response.customDisclaimer == "All generated by AI")
        #expect(response.defaultLanguage == "en-US")
        #expect(response.showWorkflowSteps == false)
        #expect(response.useIconAsAnswerIcon == false)
    }
    
    @Test("Send enhanced message feedback")
    func testSendEnhancedMessageFeedback() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.sendEnhancedMessageFeedback(
            messageId: MockDataProvider.testMessageId,
            rating: "like",
            user: MockTestConfig.user,
            content: "This response was very helpful and accurate!"
        )
        
        #expect(response.result == "success")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "messages/\(MockDataProvider.testMessageId)/feedbacks",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable, Sendable {
            let rating: String?
            let user: String
            let content: String?
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.rating == "like")
        #expect(requestBody.user == MockTestConfig.user)
        #expect(requestBody.content == "This response was very helpful and accurate!")
    }
    
    @Test("Send enhanced message feedback with null rating")
    func testSendEnhancedMessageFeedbackWithNullRating() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.sendEnhancedMessageFeedback(
            messageId: MockDataProvider.testMessageId,
            rating: nil, // Null rating
            user: MockTestConfig.user,
            content: "Just providing context without rating"
        )
        
        #expect(response.result == "success")
    }
    
    @Test("Get application feedbacks")
    func testGetApplicationFeedbacks() async throws {
        MockURLProtocol.registerMock(
            endpoint: "app/feedbacks",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationFeedbacksResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getApplicationFeedbacks(page: 2, limit: 50)
        
        #expect(response.data.count == 1)
        let feedback = response.data[0]
        #expect(feedback.id == "feedback-123")
        #expect(feedback.appId == "app-456")
        #expect(feedback.conversationId == MockDataProvider.testConversationId)
        #expect(feedback.messageId == MockDataProvider.testMessageId)
        #expect(feedback.rating == "like")
        #expect(feedback.content == "This response was very helpful!")
        #expect(feedback.fromSource == "api")
        #expect(feedback.fromEndUserId == MockTestConfig.user)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "app/feedbacks",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("page=2"))
        #expect(query.contains("limit=50"))
    }
    
    @Test("Get application feedbacks with default parameters")
    func testGetApplicationFeedbacksWithDefaults() async throws {
        MockURLProtocol.registerMock(
            endpoint: "app/feedbacks",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.applicationFeedbacksResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getApplicationFeedbacks()
        
        #expect(response.data.count == 1)
        
        // Validate default parameters
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "app/feedbacks",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("page=1"))
        #expect(query.contains("limit=20"))
    }
}

// MARK: - Advanced Annotation API Tests

@Suite("Advanced Annotation API Mock Tests")
struct AdvancedAnnotationAPIMockTests {
    
    @Test("Get annotations list")
    func testGetAnnotations() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.getAnnotations(page: 3, limit: 50)
        
        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.page == 1)
        
        let annotation = response.data[0]
        #expect(annotation.id == "annotation-123")
        #expect(annotation.question == "What is artificial intelligence?")
        #expect(annotation.answer == "Artificial intelligence is a branch of computer science...")
        #expect(annotation.hitCount == 5)
        #expect(annotation.createdAt == 1726139644)
        
        // Validate request parameters
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "apps/annotations",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("page=3"))
        #expect(query.contains("limit=50"))
    }
    
    @Test("Create annotation")
    func testCreateAnnotation() async throws {
        let createdAnnotation: [String: Any] = [
            "id": "new-annotation-456",
            "question": "How does machine learning work?",
            "answer": "Machine learning is a subset of AI that enables systems to learn...",
            "hit_count": 0,
            "created_at": 1726139700
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotations",
            response: MockURLProtocol.MockResponse.json(createdAnnotation)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let annotationRequest = AnnotationRequest(
            question: "How does machine learning work?",
            answer: "Machine learning is a subset of AI that enables systems to learn..."
        )
        
        let response = try await client.createAnnotation(request: annotationRequest)
        
        #expect(response.id == "new-annotation-456")
        #expect(response.question == "How does machine learning work?")
        #expect(response.answer == "Machine learning is a subset of AI that enables systems to learn...")
        #expect(response.hitCount == 0)
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "apps/annotations",
            expectedMethod: "POST"
        )
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: AnnotationRequest.self
        )
        
        #expect(requestBody.question == "How does machine learning work?")
        #expect(requestBody.answer == "Machine learning is a subset of AI that enables systems to learn...")
    }
    
    @Test("Update annotation")
    func testUpdateAnnotation() async throws {
        let updatedAnnotation: [String: Any] = [
            "id": "annotation-123",
            "question": "What is artificial intelligence?",
            "answer": "Updated: Artificial intelligence is a comprehensive field of computer science...",
            "hit_count": 7,
            "created_at": 1726139644
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotations/annotation-123",
            response: MockURLProtocol.MockResponse.json(updatedAnnotation)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let annotationRequest = AnnotationRequest(
            question: "What is artificial intelligence?",
            answer: "Updated: Artificial intelligence is a comprehensive field of computer science..."
        )
        
        let response = try await client.updateAnnotation(
            annotationId: "annotation-123",
            request: annotationRequest
        )
        
        #expect(response.id == "annotation-123")
        #expect(response.answer.starts(with: "Updated:"))
        #expect(response.hitCount == 7)
    }
    
    @Test("Delete annotation")
    func testDeleteAnnotation() async throws {
        MockURLProtocol.registerMock(
            endpoint: "apps/annotations/annotation-123",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.deleteAnnotation(annotationId: "annotation-123")
        #expect(response.result == "success")
    }
    
    @Test("Configure annotation reply settings")
    func testConfigureAnnotationReplySettings() async throws {
        MockURLProtocol.registerMock(
            endpoint: "apps/annotation-reply/enable",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationReplySettingsResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let settingsRequest = AnnotationReplySettingsRequest(
            scoreThreshold: 0.8,
            embeddingProviderName: "openai",
            embeddingModelName: "text-embedding-ada-002"
        )
        
        let response = try await client.configureAnnotationReplySettings(
            action: "enable",
            request: settingsRequest
        )
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "pending")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "apps/annotation-reply/enable",
            expectedMethod: "POST"
        )
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: AnnotationReplySettingsRequest.self
        )
        
        #expect(requestBody.scoreThreshold == 0.8)
        #expect(requestBody.embeddingProviderName == "openai")
        #expect(requestBody.embeddingModelName == "text-embedding-ada-002")
    }
    
    @Test("Configure annotation reply settings without request body")
    func testConfigureAnnotationReplySettingsWithoutBody() async throws {
        MockURLProtocol.registerMock(
            endpoint: "apps/annotation-reply/disable",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.annotationReplySettingsResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.configureAnnotationReplySettings(action: "disable")
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "pending")
    }
    
    @Test("Get annotation reply job status")
    func testGetAnnotationReplyJobStatus() async throws {
        let jobStatusResponse: [String: Any] = [
            "job_id": "job-123",
            "job_status": "completed",
            "error_msg": NSNull()
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "apps/annotation-reply/enable/status/job-123",
            response: MockURLProtocol.MockResponse.json(jobStatusResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let response = try await client.getAnnotationReplyJobStatus(
            action: "enable",
            jobId: "job-123"
        )
        
        #expect(response.jobId == "job-123")
        #expect(response.jobStatus == "completed")
        #expect(response.errorMsg == nil)
    }
}

// MARK: - Base Client Error Handling Tests

@Suite("Base Client Error Handling Tests")
struct BaseClientErrorHandlingTests {
    
    @Test("Handle file upload errors")
    func testFileUploadErrors() async throws {
        MockURLProtocol.registerMock(
            endpoint: "files/upload",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 400, message: "Invalid file type")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let invalidFileData = Data("not a real file".utf8)
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.uploadFile(
                user: MockTestConfig.user,
                fileData: invalidFileData,
                filename: "invalid.txt",
                mimeType: "text/plain"
            )
        }
    }
    
    @Test("Handle application info not found error")
    func testApplicationInfoNotFoundError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "info",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 404, message: "Application not found")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.getApplicationInfo()
        }
    }
    
    @Test("Handle text to audio service unavailable")
    func testTextToAudioServiceUnavailable() async throws {
        MockURLProtocol.registerMock(
            endpoint: "text-to-audio",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 503, message: "Audio service temporarily unavailable")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.textToAudio(
                text: "Test audio conversion",
                user: MockTestConfig.user
            )
        }
    }
}

// MARK: - Base Client Edge Cases Tests

@Suite("Base Client Edge Cases Tests")
struct BaseClientEdgeCasesTests {
    
    @Test("Handle large file uploads")
    func testLargeFileUploads() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        // Create a relatively large file (1MB)
        let largeFileData = TestUtilities.createTestFileData(size: 1024 * 1024)
        
        let response = try await client.uploadFile(
            user: MockTestConfig.user,
            fileData: largeFileData,
            filename: "large-file.pdf",
            mimeType: "application/pdf"
        )
        
        #expect(response.id == "file-upload-123")
        #expect(response.name == "test-file.pdf")
    }
    
    @Test("Handle special characters in text to audio")
    func testTextToAudioWithSpecialCharacters() async throws {
        MockURLProtocol.registerMock(
            endpoint: "text-to-audio",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.textToAudioResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let specialText = "Hello! 你好世界 🌍 Café naïve résumé. Testing special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        
        let response = try await client.textToAudio(
            text: specialText,
            user: MockTestConfig.user,
            streaming: true
        )
        
        #expect(response.taskId == "audio-task-123")
    }
    
    @Test("Handle concurrent API requests")
    func testConcurrentAPIRequests() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockDifyClient()
        
        let results = try await TestUtilities.runConcurrentOperations(count: 3) { index in
            // Mix different API calls
            switch index % 3 {
            case 0:
                return try await client.getApplicationInfo()
            case 1:
                return try await client.getApplicationMeta()
            default:
                return try await client.getApplicationSite()
            }
        }
        
        #expect(results.count == 3)
        // Verify each result is of the expected type
        for (index, result) in results.enumerated() {
            switch index % 3 {
            case 0:
                #expect(result is ApplicationInfoResponse)
            case 1:
                #expect(result is ApplicationMetaResponse)
            default:
                #expect(result is ApplicationSiteResponse)
            }
        }
    }
}