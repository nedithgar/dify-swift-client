# DifySwiftClient

A Swift SDK for Dify AI that provides a complete interface to the Dify Service API. This SDK follows Swift best practices and provides native async/await support with comprehensive error handling.

## Features

- **Complete API Coverage**: Supports all Dify API endpoints including chat, completion, workflows, and knowledge base management
- **Modern Swift**: Built with Swift 6.1+ using modern concurrency (async/await)
- **Cross-Platform**: Works on macOS, iOS, tvOS, and watchOS
- **Streaming Support**: Built-in streaming response handling for real-time interactions
- **Type Safety**: Comprehensive Swift types for all API request/response models
- **Error Handling**: Detailed error types with localized descriptions
- **Testing**: Full test coverage using the latest Swift Testing framework

## Requirements

- Swift 6.1+
- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/nedithgar/dify-swift-client.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/nedithgar/dify-swift-client.git`

## Quick Start

### Basic Setup

```swift
import DifySwiftClient

// Initialize the client with your API key
let client = try DifyClient(apiKey: "your_api_key_here")
```

### Chat Client

```swift
let chatClient = try ChatClient(apiKey: "your_api_key")

// Send a chat message
let response = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Hello, how can you help me?",
    user: "user_123"
)

print("Response: \(response.answer)")
```

### Streaming Chat

```swift
let streamingResponse = try await chatClient.createStreamingChatMessage(
    inputs: [:],
    query: "Tell me a story",
    user: "user_123"
)

for try await chunk in streamingResponse {
    // Process streaming data chunks
    if let jsonString = String(data: chunk, encoding: .utf8) {
        print("Received: \(jsonString)")
    }
}
```

### Completion Client

```swift
let completionClient = try CompletionClient(apiKey: "your_api_key")

let response = try await completionClient.createCompletionMessage(
    inputs: ["query": "What's the weather like today?"],
    responseMode: .blocking,
    user: "user_123"
)

print("Completion: \(response.answer)")
```

### Working with Files (Vision Models)

```swift
// Using remote image URL
let files = [APIFile(
    type: .image,
    transferMethod: .remoteUrl,
    url: "https://example.com/image.jpg"
)]

let response = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Describe this image",
    user: "user_123",
    files: files
)

// Upload and use local file
let fileData = Data() // Your image data
let uploadResponse = try await client.uploadFile(
    user: "user_123",
    fileData: fileData,
    filename: "image.jpg",
    mimeType: "image/jpeg"
)

let localFiles = [APIFile(
    type: .image,
    transferMethod: .localFile,
    uploadFileId: uploadResponse.id
)]

let responseWithLocalFile = try await chatClient.createChatMessage(
    inputs: [:],
    query: "What do you see in this image?",
    user: "user_123",
    files: localFiles
)
```

### Workflow Client

```swift
let workflowClient = try WorkflowClient(apiKey: "your_api_key")

// Run a workflow
let workflowResponse = try await workflowClient.run(
    inputs: ["input_key": "input_value"],
    responseMode: .blocking,
    user: "user_123"
)

print("Workflow status: \(workflowResponse.data.status)")
print("Outputs: \(workflowResponse.data.outputs)")

// Get workflow result
let result = try await workflowClient.getResult(
    workflowRunId: workflowResponse.workflowRunId
)
```

### Knowledge Base Client

```swift
let knowledgeBaseClient = try KnowledgeBaseClient(
    apiKey: "your_api_key",
    datasetId: "your_dataset_id"
)

// Create a new dataset
let newKBClient = try KnowledgeBaseClient(apiKey: "your_api_key")
let dataset = try await newKBClient.createDataset(name: "My Knowledge Base")

// Create client with the new dataset
let kbClient = try KnowledgeBaseClient(
    apiKey: "your_api_key",
    datasetId: dataset.id
)

// Add document by text
let documentResponse = try await kbClient.createDocumentByText(
    name: "Sample Document",
    text: "This is the content of my document."
)

// Add document by file
let fileData = Data() // Your document data
let fileDocumentResponse = try await kbClient.createDocumentByFile(
    fileData: fileData,
    filename: "document.pdf",
    mimeType: "application/pdf"
)

// List documents
let documents = try await kbClient.listDocuments()
for document in documents.data {
    print("Document: \(document.name)")
}

// Add segments to a document
let segments = [
    SegmentData(content: "This is a segment", keywords: ["keyword1", "keyword2"])
]
let segmentResponse = try await kbClient.addSegments(
    documentId: documentResponse.document.id,
    segments: segments
)
```

### Conversation Management

```swift
let chatClient = try ChatClient(apiKey: "your_api_key")

// Get conversations
let conversations = try await chatClient.getConversations(user: "user_123")
for conversation in conversations.data {
    print("Conversation: \(conversation.name)")
}

// Get messages from a conversation
let messages = try await chatClient.getConversationMessages(
    user: "user_123",
    conversationId: "conversation_id"
)

// Rename a conversation
try await chatClient.renameConversation(
    conversationId: "conversation_id",
    name: "New Conversation Name",
    autoGenerate: false,
    user: "user_123"
)

// Delete a conversation
try await chatClient.deleteConversation(
    conversationId: "conversation_id",
    user: "user_123"
)
```

### Error Handling

```swift
do {
    let response = try await chatClient.createChatMessage(
        inputs: [:],
        query: "Hello",
        user: "user_123"
    )
    print("Success: \(response.answer)")
} catch let error as DifyError {
    switch error {
    case .invalidAPIKey:
        print("Invalid API key provided")
    case .httpError(let code, let message):
        print("HTTP error \(code): \(message ?? "Unknown")")
    case .networkError(let underlyingError):
        print("Network error: \(underlyingError)")
    case .decodingError(let underlyingError):
        print("Failed to decode response: \(underlyingError)")
    default:
        print("Other error: \(error.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Audio Support

```swift
// Convert text to audio
let audioResponse = try await client.textToAudio(
    text: "Hello, this is a test message",
    user: "user_123",
    streaming: false
)

// Convert audio to text
let audioData = Data() // Your audio file data
let textResponse = try await chatClient.audioToText(
    audioData: audioData,
    filename: "audio.mp3",
    user: "user_123"
)
```

## API Reference

### Core Classes

- **`DifyClient`**: Base client with common functionality
- **`ChatClient`**: Chat-based interactions and conversation management
- **`CompletionClient`**: Completion-based interactions
- **`WorkflowClient`**: Workflow execution and management
- **`KnowledgeBaseClient`**: Knowledge base and document management

### Response Models

All API responses are strongly typed with Swift structs:

- `ChatMessageResponse`
- `CompletionMessageResponse`
- `WorkflowResponse`
- `FileUploadResponse`
- `DatasetResponse`
- `DocumentResponse`
- And many more...

### Error Types

- `DifyError.invalidURL(_:)`
- `DifyError.invalidAPIKey`
- `DifyError.httpError(_:_:)`
- `DifyError.networkError(_:)`
- `DifyError.decodingError(_:)`
- `DifyError.missingDatasetId`
- `DifyError.fileNotFound(_:)`

## Advanced Usage

### Custom Base URL

```swift
let client = try DifyClient(
    apiKey: "your_api_key",
    baseURL: "https://your-custom-dify-instance.com/v1"
)
```

### Custom URLSession

```swift
let customSession = URLSession(configuration: .default)
let client = try DifyClient(
    apiKey: "your_api_key",
    session: customSession
)
```

### Process Rules for Knowledge Base

```swift
let processRule = ProcessRule(
    mode: "custom",
    rules: ProcessRuleRules(
        preProcessingRules: [
            PreProcessingRule(id: "remove_extra_spaces", enabled: true),
            PreProcessingRule(id: "remove_urls_emails", enabled: true)
        ],
        segmentation: Segmentation(separator: "\n", maxTokens: 500)
    )
)

let response = try await kbClient.createDocumentByText(
    name: "Custom Document",
    text: "Document content",
    extraParams: [
        "indexing_technique": "high_quality",
        "process_rule": try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(processRule)
        )
    ]
)
```

## Testing

The SDK includes comprehensive tests using Swift Testing framework:

```bash
swift test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the [Dify documentation](https://docs.dify.ai/guides/application-publishing/based-on-backend-apis)

## Acknowledgments

- Built based on the official [Dify Python SDK](https://github.com/langgenius/dify/tree/main/sdks/python-client)
- Follows Swift best practices and modern concurrency patterns