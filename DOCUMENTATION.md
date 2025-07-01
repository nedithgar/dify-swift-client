# API Documentation

This document provides detailed API documentation for the Dify Swift Client.

## Table of Contents

- [Core Classes](#core-classes)
- [Models](#models)
- [Error Handling](#error-handling)
- [Utilities](#utilities)

## Core Classes

### DifyClient

The base client class that provides common functionality for all Dify API interactions.

#### Initialization

```swift
init(apiKey: String, baseURL: String = "https://api.dify.ai/v1", session: URLSession = .shared) throws
```

- `apiKey`: Your Dify API key
- `baseURL`: Base URL for the Dify API (defaults to official API)
- `session`: URLSession to use for requests

#### Methods

##### messageFeedback

```swift
func messageFeedback(messageId: String, rating: String, user: String) async throws -> MessageFeedbackResponse
```

Send feedback for a message.

##### getApplicationParameters

```swift
func getApplicationParameters(user: String) async throws -> ApplicationParametersResponse
```

Get application parameters for the user.

##### uploadFile

```swift
func uploadFile(user: String, fileData: Data, filename: String, mimeType: String) async throws -> FileUploadResponse
```

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

Extends `DifyClient` for chat-based interactions.

#### Methods

##### createChatMessage

```swift
func createChatMessage(
    inputs: [String: String],
    query: String,
    user: String,
    responseMode: ResponseMode = .blocking,
    conversationId: String? = nil,
    files: [APIFile]? = nil
) async throws -> ChatMessageResponse
```

Create a chat message with optional conversation continuation and file attachments.

##### createStreamingChatMessage

```swift
func createStreamingChatMessage(
    inputs: [String: String],
    query: String,
    user: String,
    conversationId: String? = nil,
    files: [APIFile]? = nil
) async throws -> StreamingResponse
```

Create a streaming chat message for real-time responses.

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
    case image
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