import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("Models Tests")
struct ModelsTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - Enum Tests
    
    @Test("ResponseMode enum values")
    func testResponseModeEnumValues() {
        #expect(ResponseMode.blocking.rawValue == "blocking")
        #expect(ResponseMode.streaming.rawValue == "streaming")
    }
    
    @Test("ResponseMode enum encoding")
    func testResponseModeEnumEncoding() throws {
        let blocking = ResponseMode.blocking
        let streaming = ResponseMode.streaming
        
        let blockingData = try JSONEncoder.difyEncoder.encode(blocking)
        let streamingData = try JSONEncoder.difyEncoder.encode(streaming)
        
        let blockingString = String(data: blockingData, encoding: .utf8)!
        let streamingString = String(data: streamingData, encoding: .utf8)!
        
        #expect(blockingString.contains("blocking"))
        #expect(streamingString.contains("streaming"))
    }
    
    @Test("ResponseMode enum decoding")
    func testResponseModeEnumDecoding() throws {
        let blockingJSON = "\"blocking\"".data(using: .utf8)!
        let streamingJSON = "\"streaming\"".data(using: .utf8)!
        
        let blocking = try JSONDecoder.difyDecoder.decode(ResponseMode.self, from: blockingJSON)
        let streaming = try JSONDecoder.difyDecoder.decode(ResponseMode.self, from: streamingJSON)
        
        #expect(blocking == .blocking)
        #expect(streaming == .streaming)
    }
    
    @Test("FileTransferMethod enum values")
    func testFileTransferMethodEnumValues() {
        #expect(FileTransferMethod.remoteUrl.rawValue == "remote_url")
        #expect(FileTransferMethod.localFile.rawValue == "local_file")
    }
    
    @Test("FileType enum values")
    func testFileTypeEnumValues() {
        #expect(FileType.document.rawValue == "document")
        #expect(FileType.image.rawValue == "image")
        #expect(FileType.audio.rawValue == "audio")
        #expect(FileType.video.rawValue == "video")
        #expect(FileType.custom.rawValue == "custom")
    }
    
    // MARK: - APIFile Tests
    
    @Test("APIFile initialization with remote URL")
    func testAPIFileInitializationWithRemoteURL() {
        let file = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/image.jpg",
            uploadFileId: nil
        )
        
        #expect(file.type == .image)
        #expect(file.transferMethod == .remoteUrl)
        #expect(file.url == "https://example.com/image.jpg")
        #expect(file.uploadFileId == nil)
    }
    
    @Test("APIFile initialization with local file")
    func testAPIFileInitializationWithLocalFile() {
        let file = APIFile(
            type: .document,
            transferMethod: .localFile,
            url: nil,
            uploadFileId: "upload-123"
        )
        
        #expect(file.type == .document)
        #expect(file.transferMethod == .localFile)
        #expect(file.url == nil)
        #expect(file.uploadFileId == "upload-123")
    }
    
    @Test("APIFile encoding")
    func testAPIFileEncoding() throws {
        let file = APIFile(
            type: .image,
            transferMethod: .remoteUrl,
            url: "https://example.com/image.jpg",
            uploadFileId: nil
        )
        
        let data = try JSONEncoder.difyEncoder.encode(file)
        let jsonString = String(data: data, encoding: .utf8)!
        
        #expect(jsonString.contains("image"))
        #expect(jsonString.contains("remote_url"))
        #expect(jsonString.contains("https://example.com/image.jpg"))
    }
    
    @Test("APIFile decoding")
    func testAPIFileDecoding() throws {
        let jsonData = """
        {
            "type": "document",
            "transfer_method": "local_file",
            "upload_file_id": "upload-123"
        }
        """.data(using: .utf8)!
        
        let file = try JSONDecoder.difyDecoder.decode(APIFile.self, from: jsonData)
        
        #expect(file.type == .document)
        #expect(file.transferMethod == .localFile)
        #expect(file.url == nil)
        #expect(file.uploadFileId == "upload-123")
    }
    
    // MARK: - Basic Response Models Tests
    
    @Test("BaseResponse encoding and decoding")
    func testBaseResponseEncodingAndDecoding() throws {
        let response = BaseResponse(result: "success")
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(BaseResponse.self, from: data)
        
        #expect(decoded.result == "success")
    }
    
    @Test("MessageFeedbackResponse encoding and decoding")
    func testMessageFeedbackResponseEncodingAndDecoding() throws {
        let response = MessageFeedbackResponse(result: "success")
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(MessageFeedbackResponse.self, from: data)
        
        #expect(decoded.result == "success")
    }
    
    @Test("StopCompletionResponse encoding and decoding")
    func testStopCompletionResponseEncodingAndDecoding() throws {
        let response = StopCompletionResponse(result: "stopped")
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(StopCompletionResponse.self, from: data)
        
        #expect(decoded.result == "stopped")
    }
    
    // MARK: - Application Info Models Tests
    
    @Test("ApplicationInfoResponse encoding and decoding")
    func testApplicationInfoResponseEncodingAndDecoding() throws {
        let response = ApplicationInfoResponse(
            name: "Test App",
            description: "A test application",
            tags: ["test", "demo"],
            mode: "chat",
            authorName: "Test Author"
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: data)
        
        #expect(decoded.name == "Test App")
        #expect(decoded.description == "A test application")
        #expect(decoded.tags == ["test", "demo"])
        #expect(decoded.mode == "chat")
        #expect(decoded.authorName == "Test Author")
    }
    
    @Test("ApplicationParametersResponse with all fields")
    func testApplicationParametersResponseWithAllFields() throws {
        let response = ApplicationParametersResponse(
            openingStatement: "Hello!",
            suggestedQuestions: ["What is AI?", "How does it work?"],
            suggestedQuestionsAfterAnswer: SuggestedQuestionsConfig(enabled: true),
            speechToText: SpeechToTextConfig(enabled: true),
            retrieverResource: RetrieverResourceConfig(enabled: true),
            annotationReply: AnnotationReplyConfig(enabled: false),
            userInputForm: [
                UserInputFormItem(
                    paragraph: FormInput(label: "Query", variable: "query", required: true, defaultValue: ""),
                    textInput: nil,
                    select: nil
                )
            ],
            fileUpload: FileUploadConfig(
                image: ImageUploadConfig(enabled: true, numberLimits: 3, transferMethods: ["local_file"])
            ),
            systemParameters: SystemParameters(
                fileSizeLimit: 15,
                imageFileSizeLimit: 10,
                audioFileSizeLimit: 50,
                videoFileSizeLimit: 100
            )
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(ApplicationParametersResponse.self, from: data)
        
        #expect(decoded.openingStatement == "Hello!")
        #expect(decoded.suggestedQuestions?.count == 2)
        #expect(decoded.suggestedQuestionsAfterAnswer?.enabled == true)
        #expect(decoded.speechToText?.enabled == true)
        #expect(decoded.retrieverResource?.enabled == true)
        #expect(decoded.annotationReply?.enabled == false)
        #expect(decoded.userInputForm?.count == 1)
        #expect(decoded.fileUpload?.image?.enabled == true)
        #expect(decoded.systemParameters?.fileSizeLimit == 15)
    }
    
    @Test("ApplicationParametersResponse with minimal fields")
    func testApplicationParametersResponseWithMinimalFields() throws {
        let response = ApplicationParametersResponse(
            openingStatement: nil,
            suggestedQuestions: nil,
            suggestedQuestionsAfterAnswer: nil,
            speechToText: nil,
            retrieverResource: nil,
            annotationReply: nil,
            userInputForm: nil,
            fileUpload: nil,
            systemParameters: nil
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(ApplicationParametersResponse.self, from: data)
        
        #expect(decoded.openingStatement == nil)
        #expect(decoded.suggestedQuestions == nil)
        #expect(decoded.suggestedQuestionsAfterAnswer == nil)
        #expect(decoded.speechToText == nil)
        #expect(decoded.retrieverResource == nil)
        #expect(decoded.annotationReply == nil)
        #expect(decoded.userInputForm == nil)
        #expect(decoded.fileUpload == nil)
        #expect(decoded.systemParameters == nil)
    }
    
    @Test("UserInputFormItem with different input types")
    func testUserInputFormItemWithDifferentInputTypes() throws {
        let paragraphItem = UserInputFormItem(
            paragraph: FormInput(label: "Description", variable: "desc", required: false, defaultValue: "Default"),
            textInput: nil,
            select: nil
        )
        
        let textInputItem = UserInputFormItem(
            paragraph: nil,
            textInput: FormInput(label: "Name", variable: "name", required: true, defaultValue: ""),
            select: nil
        )
        
        let selectItem = UserInputFormItem(
            paragraph: nil,
            textInput: nil,
            select: Select(
                label: "Category",
                variable: "category",
                required: true,
                defaultValue: "option1",
                options: ["option1", "option2", "option3"]
            )
        )
        
        let items = [paragraphItem, textInputItem, selectItem]
        let data = try JSONEncoder.difyEncoder.encode(items)
        let decoded = try JSONDecoder.difyDecoder.decode([UserInputFormItem].self, from: data)
        
        #expect(decoded.count == 3)
        #expect(decoded[0].paragraph?.label == "Description")
        #expect(decoded[1].textInput?.label == "Name")
        #expect(decoded[2].select?.label == "Category")
        #expect(decoded[2].select?.options == ["option1", "option2", "option3"])
    }
    
    // MARK: - Chat Models Tests
    
    @Test("ChatMessageResponse encoding and decoding")
    func testChatMessageResponseEncodingAndDecoding() throws {
        let response = ChatMessageResponse(
            event: "message",
            taskId: "task-123",
            id: "msg-123",
            messageId: "msg-123",
            conversationId: "conv-123",
            mode: "chat",
            answer: "Hello world",
            metadata: nil,
            createdAt: 1640995200
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(ChatMessageResponse.self, from: data)
        
        #expect(decoded.event == "message")
        #expect(decoded.taskId == "task-123")
        #expect(decoded.id == "msg-123")
        #expect(decoded.messageId == "msg-123")
        #expect(decoded.conversationId == "conv-123")
        #expect(decoded.mode == "chat")
        #expect(decoded.answer == "Hello world")
        #expect(decoded.createdAt == 1640995200)
    }
    
    @Test("Conversation encoding and decoding")
    func testConversationEncodingAndDecoding() throws {
        let conversation = Conversation(
            id: "conv-123",
            name: "Test Conversation",
            inputs: ["query": "Hello", "context": "test"],
            status: "normal",
            introduction: "This is a test",
            createdAt: 1640995200
        )
        
        let data = try JSONEncoder.difyEncoder.encode(conversation)
        let decoded = try JSONDecoder.difyDecoder.decode(Conversation.self, from: data)
        
        #expect(decoded.id == "conv-123")
        #expect(decoded.name == "Test Conversation")
        #expect(decoded.inputs?["query"] == "Hello")
        #expect(decoded.inputs?["context"] == "test")
        #expect(decoded.status == "normal")
        #expect(decoded.introduction == "This is a test")
        #expect(decoded.createdAt == 1640995200)
    }
    
    @Test("ChatMessage with complex structure")
    func testChatMessageWithComplexStructure() throws {
        let message = ChatMessage(
            id: "msg-123",
            conversationId: "conv-123",
            inputs: [
                "query": AnyCodable("Hello"),
                "context": AnyCodable(["type": "text", "content": "test"])
            ],
            query: "Hello world",
            messageFiles: [
                MessageFile(id: "file-123", type: "image", url: "https://example.com/image.jpg", belongsTo: "user")
            ],
            agentThoughts: [
                AgentThought(
                    id: "thought-123",
                    messageId: "msg-123",
                    position: 1,
                    thought: "I need to analyze this",
                    observation: "The user is asking about AI",
                    tool: "search",
                    toolInput: "AI definition",
                    createdAt: 1640995200,
                    messageFiles: ["file-123"]
                )
            ],
            answer: "AI stands for Artificial Intelligence",
            createdAt: 1640995200,
            feedback: MessageFeedback(rating: "like"),
            retrieverResources: [
                RetrieverResource(
                    position: 1,
                    datasetId: "dataset-123",
                    datasetName: "Knowledge Base",
                    documentId: "doc-123",
                    documentName: "AI Guide",
                    segmentId: "segment-123",
                    score: 0.95,
                    content: "AI is a field of computer science"
                )
            ]
        )
        
        let data = try JSONEncoder.difyEncoder.encode(message)
        let decoded = try JSONDecoder.difyDecoder.decode(ChatMessage.self, from: data)
        
        #expect(decoded.id == "msg-123")
        #expect(decoded.query == "Hello world")
        #expect(decoded.messageFiles.count == 1)
        #expect(decoded.agentThoughts.count == 1)
        #expect(decoded.answer == "AI stands for Artificial Intelligence")
        #expect(decoded.feedback?.rating == "like")
        #expect(decoded.retrieverResources?.count == 1)
    }
    
    // MARK: - Streaming Response Models Tests
    
    @Test("StreamingCompletionResponse decoding message event")
    func testStreamingCompletionResponseDecodingMessageEvent() throws {
        let jsonData = """
        {
            "event": "message",
            "task_id": "task-123",
            "message_id": "msg-123",
            "answer": "Hello",
            "created_at": 1640995200
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: jsonData)
        
        switch response {
        case .message(let event):
            #expect(event.event == "message")
            #expect(event.taskId == "task-123")
            #expect(event.messageId == "msg-123")
            #expect(event.answer == "Hello")
            #expect(event.createdAt == 1640995200)
        default:
            #expect(Bool(false), "Expected message event")
        }
    }
    
    @Test("StreamingCompletionResponse decoding message_end event")
    func testStreamingCompletionResponseDecodingMessageEndEvent() throws {
        let jsonData = """
        {
            "event": "message_end",
            "task_id": "task-123",
            "message_id": "msg-123",
            "metadata": {
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 20,
                    "total_tokens": 30
                }
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: jsonData)
        
        switch response {
        case .messageEnd(let event):
            #expect(event.event == "message_end")
            #expect(event.taskId == "task-123")
            #expect(event.messageId == "msg-123")
            #expect(event.metadata.usage?.totalTokens == 30)
        default:
            #expect(Bool(false), "Expected message_end event")
        }
    }
    
    @Test("StreamingCompletionResponse decoding error event")
    func testStreamingCompletionResponseDecodingErrorEvent() throws {
        let jsonData = """
        {
            "event": "error",
            "task_id": "task-123",
            "message_id": "msg-123",
            "status": 400,
            "code": "invalid_request",
            "message": "Invalid input"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: jsonData)
        
        switch response {
        case .error(let event):
            #expect(event.event == "error")
            #expect(event.taskId == "task-123")
            #expect(event.messageId == "msg-123")
            #expect(event.status == 400)
            #expect(event.code == "invalid_request")
            #expect(event.message == "Invalid input")
        default:
            #expect(Bool(false), "Expected error event")
        }
    }
    
    @Test("StreamingCompletionResponse decoding ping event")
    func testStreamingCompletionResponseDecodingPingEvent() throws {
        let jsonData = """
        {
            "event": "ping"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: jsonData)
        
        switch response {
        case .ping:
            // Expected
            break
        default:
            #expect(Bool(false), "Expected ping event")
        }
    }
    
    @Test("StreamingCompletionResponse decoding unknown event")
    func testStreamingCompletionResponseDecodingUnknownEvent() throws {
        let jsonData = """
        {
            "event": "unknown_event",
            "data": "some data"
        }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder.difyDecoder.decode(StreamingCompletionResponse.self, from: jsonData)
        }
    }
    
    // MARK: - Workflow Models Tests
    
    @Test("WorkflowResponse encoding and decoding")
    func testWorkflowResponseEncodingAndDecoding() throws {
        let response = WorkflowResponse(
            workflowRunId: "workflow-run-123",
            taskId: "task-123",
            data: WorkflowData(
                id: "workflow-123",
                workflowId: "workflow-def-123",
                status: "succeeded",
                outputs: ["result": AnyCodable("Success")],
                error: nil,
                elapsedTime: 1.5,
                totalTokens: 100,
                totalSteps: 3,
                createdAt: 1640995200,
                finishedAt: 1640995201
            )
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(WorkflowResponse.self, from: data)
        
        #expect(decoded.workflowRunId == "workflow-run-123")
        #expect(decoded.taskId == "task-123")
        #expect(decoded.data.status == "succeeded")
        #expect(decoded.data.elapsedTime == 1.5)
        #expect(decoded.data.totalTokens == 100)
        #expect(decoded.data.totalSteps == 3)
    }
    
    @Test("StreamingWorkflowResponse decoding workflow_started event")
    func testStreamingWorkflowResponseDecodingWorkflowStartedEvent() throws {
        let jsonData = """
        {
            "event": "workflow_started",
            "task_id": "task-123",
            "workflow_run_id": "workflow-run-123",
            "data": {
                "id": "workflow-123",
                "workflow_id": "workflow-def-123",
                "status": "running",
                "elapsed_time": 0.0,
                "total_tokens": 0,
                "total_steps": 3,
                "created_at": 1640995200
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(StreamingWorkflowResponse.self, from: jsonData)
        
        switch response {
        case .workflowStarted(let event):
            #expect(event.event == "workflow_started")
            #expect(event.taskId == "task-123")
            #expect(event.workflowRunId == "workflow-run-123")
            #expect(event.data.status == "running")
        default:
            #expect(Bool(false), "Expected workflow_started event")
        }
    }
    
    @Test("NodeExecutionData with complex structure")
    func testNodeExecutionDataWithComplexStructure() throws {
        let nodeData = NodeExecutionData(
            id: "node-123",
            nodeId: "node-def-123",
            nodeType: "llm",
            index: 1,
            title: "Language Model Node",
            predecessorNodeId: "node-0",
            inputs: [
                "prompt": AnyCodable("What is AI?"),
                "temperature": AnyCodable(0.7),
                "max_tokens": AnyCodable(1000)
            ],
            processData: [
                "tokens_used": AnyCodable(150),
                "processing_time": AnyCodable(2.5)
            ],
            outputs: [
                "answer": AnyCodable("AI stands for Artificial Intelligence"),
                "confidence": AnyCodable(0.95)
            ],
            status: "succeeded",
            error: nil,
            elapsedTime: 2.5,
            executionMetadata: ExecutionMetadata(
                totalTokens: 150,
                totalPrice: 0.003,
                currency: "USD"
            ),
            createdAt: 1640995200
        )
        
        let data = try JSONEncoder.difyEncoder.encode(nodeData)
        let decoded = try JSONDecoder.difyDecoder.decode(NodeExecutionData.self, from: data)
        
        #expect(decoded.id == "node-123")
        #expect(decoded.nodeType == "llm")
        #expect(decoded.title == "Language Model Node")
        #expect(decoded.status == "succeeded")
        #expect(decoded.elapsedTime == 2.5)
        #expect(decoded.executionMetadata?.totalTokens == 150)
        #expect(decoded.executionMetadata?.totalPrice == 0.003)
        #expect(decoded.executionMetadata?.currency == "USD")
    }
    
    // MARK: - Knowledge Base Models Tests
    
    @Test("DatasetResponse encoding and decoding")
    func testDatasetResponseEncodingAndDecoding() throws {
        let response = DatasetResponse(
            id: "dataset-123",
            name: "Test Dataset",
            description: "A test dataset",
            permission: "only_me",
            dataSourceType: "upload_file",
            indexingTechnique: "high_quality",
            appCount: 2,
            documentCount: 10,
            wordCount: 5000,
            createdBy: "user-123",
            createdAt: 1640995200
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(DatasetResponse.self, from: data)
        
        #expect(decoded.id == "dataset-123")
        #expect(decoded.name == "Test Dataset")
        #expect(decoded.description == "A test dataset")
        #expect(decoded.permission == "only_me")
        #expect(decoded.dataSourceType == "upload_file")
        #expect(decoded.indexingTechnique == "high_quality")
        #expect(decoded.appCount == 2)
        #expect(decoded.documentCount == 10)
        #expect(decoded.wordCount == 5000)
        #expect(decoded.createdBy == "user-123")
        #expect(decoded.createdAt == 1640995200)
    }
    
    @Test("ProcessRule encoding and decoding")
    func testProcessRuleEncodingAndDecoding() throws {
        let automaticRule = ProcessRule(mode: "automatic")
        let customRule = ProcessRule(
            mode: "custom",
            rules: [
                "pre_processing_rules": "remove_extra_spaces,remove_urls_emails",
                "segmentation": "automatic",
                "segment_max_tokens": "1000"
            ]
        )
        
        let automaticData = try JSONEncoder.difyEncoder.encode(automaticRule)
        let customData = try JSONEncoder.difyEncoder.encode(customRule)
        
        let decodedAutomatic = try JSONDecoder.difyDecoder.decode(ProcessRule.self, from: automaticData)
        let decodedCustom = try JSONDecoder.difyDecoder.decode(ProcessRule.self, from: customData)
        
        #expect(decodedAutomatic.mode == "automatic")
        #expect(decodedAutomatic.rules == nil)
        
        #expect(decodedCustom.mode == "custom")
        #expect(decodedCustom.rules?["pre_processing_rules"] == "remove_extra_spaces,remove_urls_emails")
        #expect(decodedCustom.rules?["segmentation"] == "automatic")
        #expect(decodedCustom.rules?["segment_max_tokens"] == "1000")
    }
    
    // MARK: - AnyCodable Tests
    
    @Test("AnyCodable with various types")
    func testAnyCodableWithVariousTypes() throws {
        let intValue = AnyCodable(42)
        let doubleValue = AnyCodable(3.14)
        let boolValue = AnyCodable(true)
        let stringValue = AnyCodable("hello")
        let arrayValue = AnyCodable([1, 2, 3])
        let dictValue = AnyCodable(["key": "value"])
        
        let values = [
            "int": intValue,
            "double": doubleValue,
            "bool": boolValue,
            "string": stringValue,
            "array": arrayValue,
            "dict": dictValue
        ]
        
        let data = try JSONEncoder.difyEncoder.encode(values)
        let decoded = try JSONDecoder.difyDecoder.decode([String: AnyCodable].self, from: data)
        
        #expect(decoded["int"]?.value as? Int == 42)
        #expect(decoded["double"]?.value as? Double == 3.14)
        #expect(decoded["bool"]?.value as? Bool == true)
        #expect(decoded["string"]?.value as? String == "hello")
        #expect((decoded["array"]?.value as? [Any])?.count == 3)
        #expect((decoded["dict"]?.value as? [String: Any])?["key"] as? String == "value")
    }
    
    @Test("AnyCodable with nested structures")
    func testAnyCodableWithNestedStructures() throws {
        let nestedData: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": "deep value",
                    "array": [1, 2, 3],
                    "bool": true
                ]
            ],
            "simple": "value"
        ]
        
        let anyCodable = AnyCodable(nestedData)
        
        let data = try JSONEncoder.difyEncoder.encode(anyCodable)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: data)
        
        let decodedDict = decoded.value as? [String: Any]
        #expect(decodedDict?["simple"] as? String == "value")
        
        let level1 = decodedDict?["level1"] as? [String: Any]
        let level2 = level1?["level2"] as? [String: Any]
        #expect(level2?["level3"] as? String == "deep value")
        #expect(level2?["bool"] as? Bool == true)
        
        let array = level2?["array"] as? [Any]
        #expect(array?.count == 3)
    }
    
    @Test("AnyCodable encoding error with unsupported type")
    func testAnyCodableEncodingErrorWithUnsupportedType() throws {
        struct UnsupportedType {}
        let anyCodable = AnyCodable(UnsupportedType())
        
        #expect(throws: EncodingError.self) {
            try JSONEncoder.difyEncoder.encode(anyCodable)
        }
    }
    
    @Test("AnyCodable decoding error with invalid JSON")
    func testAnyCodableDecodingErrorWithInvalidJSON() throws {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: invalidJSON)
        }
    }
    
    // MARK: - ToolIcon Tests
    
    @Test("ToolIcon with URL")
    func testToolIconWithURL() throws {
        let icon = ToolIcon.url("https://example.com/icon.png")
        
        let data = try JSONEncoder.difyEncoder.encode(icon)
        let decoded = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: data)
        
        switch decoded {
        case .url(let url):
            #expect(url == "https://example.com/icon.png")
        default:
            #expect(Bool(false), "Expected URL icon")
        }
    }
    
    @Test("ToolIcon with emoji")
    func testToolIconWithEmoji() throws {
        let emoji = ToolIconEmoji(background: "#FF6B6B", content: "🧮")
        let icon = ToolIcon.emoji(emoji)
        
        let data = try JSONEncoder.difyEncoder.encode(icon)
        let decoded = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: data)
        
        switch decoded {
        case .emoji(let decodedEmoji):
            #expect(decodedEmoji.background == "#FF6B6B")
            #expect(decodedEmoji.content == "🧮")
        default:
            #expect(Bool(false), "Expected emoji icon")
        }
    }
    
    @Test("ToolIcon decoding from JSON string")
    func testToolIconDecodingFromJSONString() throws {
        let jsonData = "\"https://example.com/icon.png\"".data(using: .utf8)!
        
        let icon = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: jsonData)
        
        switch icon {
        case .url(let url):
            #expect(url == "https://example.com/icon.png")
        default:
            #expect(Bool(false), "Expected URL icon")
        }
    }
    
    @Test("ToolIcon decoding from JSON object")
    func testToolIconDecodingFromJSONObject() throws {
        let jsonData = """
        {
            "background": "#1C64F2",
            "content": "🔧"
        }
        """.data(using: .utf8)!
        
        let icon = try JSONDecoder.difyDecoder.decode(ToolIcon.self, from: jsonData)
        
        switch icon {
        case .emoji(let emoji):
            #expect(emoji.background == "#1C64F2")
            #expect(emoji.content == "🔧")
        default:
            #expect(Bool(false), "Expected emoji icon")
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle malformed JSON in model decoding")
    func testHandleMalformedJSONInModelDecoding() throws {
        let malformedJSON = "{ \"name\": \"Test\", \"invalid\": }".data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: malformedJSON)
        }
    }
    
    @Test("Handle missing required fields in model decoding")
    func testHandleMissingRequiredFieldsInModelDecoding() throws {
        let incompleteJSON = "{ \"description\": \"Test\" }".data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: incompleteJSON)
        }
    }
    
    @Test("Handle extra fields in model decoding")
    func testHandleExtraFieldsInModelDecoding() throws {
        let jsonWithExtraFields = """
        {
            "result": "success",
            "extra_field": "extra_value",
            "another_extra": 123
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(BaseResponse.self, from: jsonWithExtraFields)
        
        #expect(response.result == "success")
    }
    
    @Test("Handle null values in optional fields")
    func testHandleNullValuesInOptionalFields() throws {
        let jsonWithNulls = """
        {
            "name": "Test App",
            "description": null,
            "tags": ["test"],
            "mode": "chat",
            "author_name": "Test Author"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: jsonWithNulls)
        
        #expect(response.name == "Test App")
        #expect(response.description == nil)
        #expect(response.tags == ["test"])
        #expect(response.mode == "chat")
        #expect(response.authorName == "Test Author")
    }
    
    @Test("Handle very large numbers in models")
    func testHandleVeryLargeNumbersInModels() throws {
        let jsonWithLargeNumbers = """
        {
            "id": "file-123",
            "name": "test.txt",
            "size": 9223372036854775807,
            "extension": "txt",
            "mime_type": "text/plain",
            "created_by": "user-123",
            "created_at": 2147483647
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(FileUploadResponse.self, from: jsonWithLargeNumbers)
        
        #expect(response.size == 9223372036854775807)
        #expect(response.createdAt == 2147483647)
    }
    
    @Test("Handle Unicode characters in string fields")
    func testHandleUnicodeCharactersInStringFields() throws {
        let jsonWithUnicode = """
        {
            "name": "测试应用 🚀",
            "description": "这是一个测试应用，包含各种Unicode字符：😀🎉✨",
            "tags": ["测试", "演示", "🏷️"],
            "mode": "chat",
            "author_name": "开发者 👨‍💻"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: jsonWithUnicode)
        
        #expect(response.name == "测试应用 🚀")
        #expect(response.description == "这是一个测试应用，包含各种Unicode字符：😀🎉✨")
        #expect(response.tags == ["测试", "演示", "🏷️"])
        #expect(response.authorName == "开发者 👨‍💻")
    }
    
    // MARK: - Performance Tests
    
    @Test("Handle large arrays in models")
    func testHandleLargeArraysInModels() throws {
        var largeTags: [String] = []
        for i in 0..<10000 {
            largeTags.append("tag\(i)")
        }
        
        let response = ApplicationInfoResponse(
            name: "Test App",
            description: "Test with large tags array",
            tags: largeTags,
            mode: "chat",
            authorName: "Test Author"
        )
        
        let data = try JSONEncoder.difyEncoder.encode(response)
        let decoded = try JSONDecoder.difyDecoder.decode(ApplicationInfoResponse.self, from: data)
        
        #expect(decoded.tags.count == 10000)
        #expect(decoded.tags[0] == "tag0")
        #expect(decoded.tags[9999] == "tag9999")
    }
    
    @Test("Handle deeply nested AnyCodable structures")
    func testHandleDeeplyNestedAnyCodableStructures() throws {
        var deeplyNested: [String: Any] = [:]
        var current = deeplyNested
        
        for i in 0..<100 {
            let next: [String: Any] = ["value": "level\(i)"]
            current["level\(i)"] = next
            current = next
        }
        
        let anyCodable = AnyCodable(deeplyNested)
        
        let data = try JSONEncoder.difyEncoder.encode(anyCodable)
        let decoded = try JSONDecoder.difyDecoder.decode(AnyCodable.self, from: data)
        
        // Verify the structure was preserved
        #expect(decoded.value is [String: Any])
    }
}