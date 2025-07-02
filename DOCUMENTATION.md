# API Documentation

This document provides comprehensive API documentation for the Dify Swift Client with full support for the latest Dify Service API features.

## Table of Contents

- [Core Classes](#core-classes)
- [Enhanced Features](#enhanced-features)  
- [Models](#models)
- [Streaming Events](#streaming-events)
- [Error Handling](#error-handling)
- [Utilities](#utilities)

## Core Classes

### DifyClient

The base client class that provides common functionality for all Dify API interactions, now with comprehensive application management features.

#### Initialization

```swift
init(apiKey: String, baseURL: String = "https://api.dify.ai/v1", session: URLSession = .shared) throws
```

- `apiKey`: Your Dify API key
- `baseURL`: Base URL for the Dify API (defaults to official API)
- `session`: URLSession to use for requests

#### Enhanced Methods

##### Application Information

```swift
func getApplicationInfo() async throws -> ApplicationInfoResponse
```

Get basic application information including name, description, tags, mode, and author.

```swift
func getEnhancedApplicationParameters(user: String? = nil) async throws -> EnhancedApplicationParametersResponse
```

Get comprehensive application parameters including all features like speech-to-text, text-to-speech, file upload settings, and system parameters.

```swift
func getApplicationMeta() async throws -> ApplicationMetaResponse
```

Get application metadata including tool icons and configurations.

```swift
func getApplicationSite() async throws -> ApplicationSiteResponse
```

Get webapp/site settings including theme, icons, and UI configuration.

##### Enhanced Feedback & Content Management

```swift
func sendEnhancedMessageFeedback(messageId: String, rating: String?, user: String, content: String? = nil) async throws -> MessageFeedbackResponse
```

Send enhanced feedback with optional content support.

```swift
func getApplicationFeedbacks(page: Int = 1, limit: Int = 20) async throws -> ApplicationFeedbacksResponse
```

Get application feedback listings with pagination.

##### Annotation Management

```swift
func getAnnotations(page: Int = 1, limit: Int = 20) async throws -> AnnotationListResponse
```

Get annotation list with pagination.

```swift
func createAnnotation(request: AnnotationRequest) async throws -> AnnotationListResponse.Annotation
```

Create a new annotation with question and answer.

```swift
func updateAnnotation(annotationId: String, request: AnnotationRequest) async throws -> AnnotationListResponse.Annotation
```

Update an existing annotation.

```swift
func deleteAnnotation(annotationId: String) async throws -> BaseResponse
```

Delete an annotation.

```swift
func configureAnnotationReplySettings(action: String, request: AnnotationReplySettingsRequest? = nil) async throws -> AnnotationReplySettingsResponse
```

Configure annotation reply settings (enable/disable) with embedding model configuration.

```swift
func getAnnotationReplyJobStatus(action: String, jobId: String) async throws -> AnnotationJobStatusResponse
```

Get the status of annotation configuration jobs.

##### Legacy Methods (Still Supported)

```swift
func messageFeedback(messageId: String, rating: String, user: String) async throws -> MessageFeedbackResponse
```

Send basic message feedback (legacy method).

```swift
func getApplicationParameters(user: String) async throws -> ApplicationParametersResponse
```

Get basic application parameters (legacy method).

```swift
func uploadFile(user: String, fileData: Data, filename: String, mimeType: String) async throws -> FileUploadResponse
```

Upload a file for use with multi-modal models - now supports all file types (documents, images, audio, video, custom).

```swift
func textToAudio(text: String, user: String, streaming: Bool = false) async throws -> TextToAudioResponse
```

Convert text to audio.

```swift
func getMeta(user: String) async throws -> MetaResponse
```

Get meta information (legacy method - use `getApplicationMeta()` instead).

Upload a file to be used with vision models.

##### textToAudio

```swift
func textToAudio(text: String, user: String, streaming: Bool = false) async throws -> TextToAudioResponse
```

Convert text to audio.

##### getMeta

```swift
func getMeta(user: String) async throws -> MetaResponse
```

Get meta information about the application.

### ChatClient

Extends `DifyClient` for chat-based interactions with enhanced features and conversation management.

#### Enhanced Methods

##### createChatMessage

```swift
func createChatMessage(
    inputs: [String: String],
    query: String,
    user: String,
    responseMode: ResponseMode = .blocking,
    conversationId: String? = nil,
    files: [APIFile]? = nil,
    autoGenerateName: Bool = true
) async throws -> ChatMessageResponse
```

Create a chat message with enhanced features:
- Optional conversation continuation and multi-format file attachments
- Auto-generate name control for conversation titles
- Support for all file types (documents, images, audio, video, custom)

##### createStreamingChatMessage

```swift
func createStreamingChatMessage(
    inputs: [String: String],
    query: String,
    user: String,
    conversationId: String? = nil,
    files: [APIFile]? = nil,
    autoGenerateName: Bool = true
) async throws -> StreamingResponse
```

Create a streaming chat message with real-time responses and enhanced event support including workflow events.

##### getConversationVariables

```swift
func getConversationVariables(
    conversationId: String,
    user: String,
    lastId: String? = nil,
    limit: Int = 20
) async throws -> ConversationVariablesResponse
```

**NEW**: Extract and retrieve structured variables from conversations including customer data, preferences, and context.

##### getSuggestedMessages

```swift
func getSuggestedMessages(messageId: String, user: String) async throws -> SuggestedMessagesResponse
```

Get suggested follow-up messages.

##### stopMessage

```swift
func stopMessage(taskId: String, user: String) async throws -> BaseResponse
```

Stop message generation.

##### getConversations

```swift
func getConversations(
    user: String,
    lastId: String? = nil,
    limit: Int? = nil,
    pinned: Bool? = nil
) async throws -> ConversationsResponse
```

Get list of conversations with pagination support.

##### getConversationMessages

```swift
func getConversationMessages(
    user: String,
    conversationId: String? = nil,
    firstId: String? = nil,
    limit: Int? = nil
) async throws -> ConversationMessagesResponse
```

Get messages from a conversation.

##### renameConversation

```swift
func renameConversation(
    conversationId: String,
    name: String,
    autoGenerate: Bool,
    user: String
) async throws -> BaseResponse
```

Rename a conversation.

##### deleteConversation

```swift
func deleteConversation(conversationId: String, user: String) async throws -> BaseResponse
```

Delete a conversation.

##### audioToText

```swift
func audioToText(audioData: Data, filename: String, user: String) async throws -> ChatMessageResponse
```

Convert audio to text.

### CompletionClient

Extends `DifyClient` for completion-based interactions.

#### Methods

##### createCompletionMessage

```swift
func createCompletionMessage(
    inputs: [String: String],
    responseMode: ResponseMode,
    user: String,
    files: [APIFile]? = nil
) async throws -> CompletionMessageResponse
```

Create a completion message.

##### createStreamingCompletionMessage

```swift
func createStreamingCompletionMessage(
    inputs: [String: String],
    user: String,
    files: [APIFile]? = nil
) async throws -> StreamingResponse
```

Create a streaming completion message.

### WorkflowClient

Extends `DifyClient` for workflow management.

#### Methods

##### run

```swift
func run(
    inputs: [String: String],
    responseMode: ResponseMode = .streaming,
    user: String = "abc-123"
) async throws -> WorkflowResponse
```

Run a workflow.

##### runStreaming

```swift
func runStreaming(
    inputs: [String: String],
    user: String = "abc-123"
) async throws -> StreamingResponse
```

Run a workflow with streaming response.

##### stop

```swift
func stop(taskId: String, user: String) async throws -> BaseResponse
```

Stop a running workflow.

##### getResult

```swift
func getResult(workflowRunId: String) async throws -> WorkflowResponse
```

Get workflow run result.

### KnowledgeBaseClient

Extends `DifyClient` for knowledge base management.

#### Initialization

```swift
init(
    apiKey: String,
    baseURL: String = "https://api.dify.ai/v1",
    datasetId: String? = nil,
    session: URLSession = .shared
) throws
```

Additional parameter:
- `datasetId`: Optional dataset ID for operations requiring a specific dataset

#### Dataset Methods

##### createDataset

```swift
func createDataset(name: String) async throws -> DatasetResponse
```

Create a new dataset.

##### listDatasets

```swift
func listDatasets(page: Int = 1, pageSize: Int = 20) async throws -> DatasetsResponse
```

List datasets with pagination.

##### deleteDataset

```swift
func deleteDataset() async throws
```

Delete the current dataset.

#### Document Methods

##### createDocumentByText

```swift
func createDocumentByText(
    name: String,
    text: String,
    extraParams: [String: Any]? = nil
) async throws -> CreateDocumentResponse
```

Create a document from text content.

##### updateDocumentByText

```swift
func updateDocumentByText(
    documentId: String,
    name: String,
    text: String,
    extraParams: [String: Any]? = nil
) async throws -> CreateDocumentResponse
```

Update a document with new text content.

##### createDocumentByFile

```swift
func createDocumentByFile(
    fileData: Data,
    filename: String,
    mimeType: String,
    originalDocumentId: String? = nil,
    extraParams: [String: Any]? = nil
) async throws -> CreateDocumentResponse
```

Create a document from file upload.

##### updateDocumentByFile

```swift
func updateDocumentByFile(
    documentId: String,
    fileData: Data,
    filename: String,
    mimeType: String,
    extraParams: [String: Any]? = nil
) async throws -> CreateDocumentResponse
```

Update a document with a new file.

##### listDocuments

```swift
func listDocuments(
    page: Int? = nil,
    pageSize: Int? = nil,
    keyword: String? = nil
) async throws -> DocumentsResponse
```

List documents in the dataset.

##### deleteDocument

```swift
func deleteDocument(documentId: String) async throws -> BaseResponse
```

Delete a document.

##### batchIndexingStatus

```swift
func batchIndexingStatus(batchId: String) async throws -> BatchIndexingStatusResponse
```

Get batch indexing status.

#### Segment Methods

##### addSegments

```swift
func addSegments(documentId: String, segments: [SegmentData]) async throws -> AddSegmentsResponse
```

Add segments to a document.

##### querySegments

```swift
func querySegments(
    documentId: String,
    keyword: String? = nil,
    status: String? = nil
) async throws -> SegmentsResponse
```

Query segments in a document.

##### updateDocumentSegment

```swift
func updateDocumentSegment(
    documentId: String,
    segmentId: String,
    segmentData: SegmentData
) async throws -> UpdateSegmentResponse
```

Update a document segment.

##### deleteDocumentSegment

```swift
func deleteDocumentSegment(documentId: String, segmentId: String) async throws -> BaseResponse
```

Delete a document segment.

## Enhanced Features

### Multi-Format File Support

The SDK now supports comprehensive file handling across all Dify-supported formats:

#### Enhanced FileType Enum

```swift
enum FileType: String, Codable {
    case document  // TXT, MD, PDF, DOCX, XLSX, CSV, etc.
    case image     // JPG, PNG, GIF, WEBP, SVG
    case audio     // MP3, WAV, M4A, WEBM, AMR
    case video     // MP4, MOV, MPEG
    case custom    // Any other file types
}
```

#### Usage Examples

```swift
// Document file
let document = APIFile(
    type: .document,
    transferMethod: .localFile,
    uploadFileId: "doc_upload_id"
)

// Audio file
let audio = APIFile(
    type: .audio,
    transferMethod: .remoteUrl,
    url: "https://example.com/audio.mp3"
)

// Multiple file types in one request
let files = [document, audio, imageFile]
let response = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Analyze these files",
    user: "user_123",
    files: files
)
```

### Application Management

#### Get Application Information

```swift
// Basic info
let info = try await client.getApplicationInfo()
print("App: \(info.name) (\(info.mode))")

// Enhanced parameters
let params = try await client.getEnhancedApplicationParameters()
if let speechToText = params.speechToText {
    print("Speech-to-text: \(speechToText.enabled)")
}

// Meta information and tool icons
let meta = try await client.getApplicationMeta()
for (toolName, icon) in meta.toolIcons {
    // Handle different icon types
}

// Site/webapp settings
let site = try await client.getApplicationSite()
print("Theme: \(site.chatColorTheme ?? "default")")
```

### Enhanced Feedback System

#### Rich Feedback with Content

```swift
// Send detailed feedback
try await client.sendEnhancedMessageFeedback(
    messageId: "msg_123",
    rating: "like",
    user: "user_123",
    content: "This response was extremely helpful and provided exactly what I needed!"
)

// Get application feedback history
let feedbacks = try await client.getApplicationFeedbacks(page: 1, limit: 20)
for feedback in feedbacks.data {
    print("Rating: \(feedback.rating)")
    if let content = feedback.content {
        print("Content: \(content)")
    }
}
```

### Annotation Management

#### Complete CRUD Operations

```swift
// List annotations
let annotations = try await client.getAnnotations(page: 1, limit: 20)
print("Total: \(annotations.total)")

// Create annotation
let newAnnotation = try await client.createAnnotation(
    request: AnnotationRequest(
        question: "What is machine learning?",
        answer: "Machine learning is a subset of AI that enables systems to learn from data."
    )
)

// Update annotation
let updatedAnnotation = try await client.updateAnnotation(
    annotationId: newAnnotation.id,
    request: AnnotationRequest(
        question: "What is machine learning?",
        answer: "Machine learning is a method of data analysis that automates analytical model building."
    )
)

// Configure annotation reply settings
let settings = try await client.configureAnnotationReplySettings(
    action: "enable",
    request: AnnotationReplySettingsRequest(
        scoreThreshold: 0.8,
        embeddingProviderName: "openai",
        embeddingModelName: "text-embedding-ada-002"
    )
)

// Monitor job status
let status = try await client.getAnnotationReplyJobStatus(
    action: "enable",
    jobId: settings.jobId
)
```

### Conversation Variables

Extract and manage structured data from conversations:

```swift
let variables = try await chatClient.getConversationVariables(
    conversationId: "conv_123",
    user: "user_123"
)

for variable in variables.data {
    print("Variable: \(variable.name)")
    print("Type: \(variable.valueType)")
    print("Value: \(variable.value)")
    print("Description: \(variable.description ?? "N/A")")
}
```

## Streaming Events

### Enhanced Streaming Support

The SDK now supports comprehensive streaming events for advanced chat and workflow applications:

#### Streaming Event Types

```swift
enum StreamingEventType: String, Codable {
    case message              // Basic message chunks
    case messageEnd           // Message completion
    case messageReplace       // Content moderation replacement
    case messageFile          // File attachments
    case agentMessage         // Agent assistant messages
    case agentThought         // Agent reasoning
    case ttsMessage           // Text-to-speech audio
    case ttsMessageEnd        // TTS completion
    case workflowStarted      // Workflow execution start
    case nodeStarted          // Node execution start
    case nodeFinished         // Node execution completion
    case workflowFinished     // Workflow completion
    case textChunk            // Workflow text streaming
    case error               // Error events
    case ping                // Keep-alive events
}
```

#### Processing Streaming Events

```swift
// Create streaming response
let stream = try await chatClient.createStreamingChatMessage(
    inputs: [:],
    query: "Complex workflow request",
    user: "user_123"
)

// Process events
for try await data in stream {
    if let event = try? JSONDecoder().decode(GenericStreamingEvent.self, from: data) {
        switch event.event {
        case .message:
            // Handle message chunks
            print("Message: \(event.data?["answer"] as? String ?? "")")
            
        case .workflowStarted:
            // Handle workflow start
            print("Workflow started: \(event.workflowRunId ?? "")")
            
        case .nodeFinished:
            // Handle node completion
            if let data = event.data {
                print("Node \(data["title"] as? String ?? "") completed")
                print("Status: \(data["status"] as? String ?? "")")
            }
            
        case .messageEnd:
            // Handle completion
            print("Message completed")
            
        case .error:
            // Handle errors
            print("Error occurred")
            
        default:
            break
        }
    }
}
```

#### Workflow Events Example

```swift
// For workflow applications
let workflowStream = try await workflowClient.runStreaming(
    inputs: ["document": "analysis_doc"],
    user: "user_123"
)

for try await data in workflowStream {
    if let event = try? JSONDecoder().decode(GenericStreamingEvent.self, from: data) {
        switch event.event {
        case .textChunk:
            // Handle text streaming from workflow
            if let textData = event.data?["text"] as? String {
                print("Text chunk: \(textData)")
            }
            
        case .nodeStarted:
            // Track node execution
            if let nodeData = event.data {
                print("Starting node: \(nodeData["title"] as? String ?? "")")
            }
            
        case .nodeFinished:
            // Track completion with metrics
            if let nodeData = event.data {
                print("Finished node: \(nodeData["title"] as? String ?? "")")
                if let metadata = nodeData["execution_metadata"] as? [String: Any] {
                    print("Tokens used: \(metadata["total_tokens"] as? Int ?? 0)")
                }
            }
            
        default:
            break
        }
    }
}
```

## Models

### Enums

#### ResponseMode

```swift
enum ResponseMode: String, Codable {
    case blocking
    case streaming
}
```

#### FileTransferMethod

```swift
enum FileTransferMethod: String, Codable {
    case remoteUrl = "remote_url"
    case localFile = "local_file"
}
```

#### FileType

```swift
enum FileType: String, Codable {
    case document  // TXT, MD, PDF, DOCX, XLSX, CSV, EML, MSG, PPTX, PPT, XML, EPUB
    case image     // JPG, JPEG, PNG, GIF, WEBP, SVG
    case audio     // MP3, M4A, WAV, WEBM, AMR
    case video     // MP4, MOV, MPEG, MPGA
    case custom    // Other file types
}
```

#### HTTPMethod

```swift
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}
```

### Request Models

#### APIFile

```swift
struct APIFile: Codable {
    let type: FileType
    let transferMethod: FileTransferMethod
    let url: String?
    let uploadFileId: String?
}
```

#### ProcessRule

```swift
struct ProcessRule: Codable {
    let mode: String
    let rules: ProcessRuleRules?
}
```

#### SegmentData

```swift
struct SegmentData: Codable {
    let content: String
    let answer: String?
    let keywords: [String]?
    let enabled: Bool?
}
```

### Response Models

All response models include appropriate properties with proper snake_case to camelCase conversion.

Key response types:
- `ChatMessageResponse`
- `CompletionMessageResponse`
- `WorkflowResponse`
- `FileUploadResponse`
- `DatasetResponse`
- `DocumentResponse`
- `SegmentResponse`
- `ConversationsResponse`
- `SuggestedMessagesResponse`

## Error Handling

### DifyError

```swift
enum DifyError: Error, LocalizedError {
    case invalidURL(String)
    case noData
    case decodingError(Error)
    case httpError(Int, String?)
    case networkError(Error)
    case invalidResponse
    case fileNotFound(String)
    case invalidAPIKey
    case missingDatasetId
}
```

Each error provides a localized description for user-friendly error messages.

## Utilities

### StreamingResponse

```swift
struct StreamingResponse: AsyncSequence {
    typealias Element = Data
    
    func makeAsyncIterator() -> AsyncIterator
}
```

Provides async iteration over streaming data chunks.

### URL Extensions

```swift
extension URL {
    func appendingQueryItems(_ queryItems: [URLQueryItem]) -> URL
}
```

### URLRequest Extensions

```swift
extension URLRequest {
    mutating func setJSONBody<T: Encodable>(_ object: T) throws
    mutating func setMultipartBody(parameters: [String: String], fileData: [(key: String, filename: String, data: Data, mimeType: String)])
}
```

### JSON Coders

Pre-configured JSON encoders and decoders with proper date handling:

```swift
extension JSONDecoder {
    static let difyDecoder: JSONDecoder
}

extension JSONEncoder {
    static let difyEncoder: JSONEncoder
}
```