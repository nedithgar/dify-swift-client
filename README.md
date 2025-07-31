# DifySwiftClient

[![Test](https://github.com/nedithgar/dify-swift-client/actions/workflows/test.yml/badge.svg)](https://github.com/nedithgar/dify-swift-client/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift Version](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgrey.svg)](https://github.com/nedithgar/dify-swift-client)

A Swift SDK for Dify AI that provides a complete interface to the Dify Service API. This SDK follows Swift best practices and provides native async/await support with comprehensive error handling.

## Features

- **Complete API Coverage**: Supports all Dify API endpoints including chat, completion, workflows, knowledge base management, application info, feedbacks, and annotations
- **Enhanced File Support**: Full support for documents, images, audio, video, and custom file types with both remote URL and local file upload
- **Modern Swift**: Built with Swift 6.1+ using modern concurrency (async/await) and follows Swift best practices  
- **Cross-Platform**: Works on macOS, iOS, tvOS, watchOS, and Linux
- **Advanced Streaming**: Built-in streaming response handling for real-time interactions including workflow events
- **Type Safety**: Comprehensive Swift types for all API request/response models with proper snake_case to camelCase conversion
- **Error Handling**: Detailed error types with localized descriptions
- **Testing**: Full test coverage using the latest Swift Testing framework (WWDC2024) with parallel test execution support
- **Application Management**: Complete application info, parameters, metadata, and configuration support
- **Feedback & Annotations**: Full support for message feedback with content and annotation management
- **Conversation Variables**: Extract and manage structured data from conversations

## Requirements

- Swift 6.1+
- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Linux (with Swift 6.1+) - See [Platform Support](#platform-support) for details

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
    user: "user_123"
)

print("Completion: \(response.answer)")
```

### Working with Files (Enhanced Multi-Format Support)

The SDK now supports comprehensive file handling for all Dify-supported formats:

```swift
// Document files: TXT, MD, PDF, DOCX, XLSX, etc.
let documentFile = APIFile(
    type: .document,
    transferMethod: .localFile,
    uploadFileId: uploadResponse.id
)

// Audio files: MP3, WAV, M4A, etc.
let audioFile = APIFile(
    type: .audio,
    transferMethod: .remoteUrl,
    url: "https://example.com/audio.mp3"
)

// Video files: MP4, MOV, etc.
let videoFile = APIFile(
    type: .video,
    transferMethod: .localFile,
    uploadFileId: videoUploadResponse.id
)

// Custom file types
let customFile = APIFile(
    type: .custom,
    transferMethod: .localFile,
    uploadFileId: customUploadResponse.id
)

// Using remote image URL
let imageFile = APIFile(
    type: .image,
    transferMethod: .remoteUrl,
    url: "https://example.com/image.jpg"
)

let response = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Analyze these files and provide insights",
    user: "user_123",
    files: [documentFile, audioFile, imageFile]
)

// Upload and use local file (only available in CompletionClient)
let completionClient = try CompletionClient(apiKey: "your_api_key")
let fileData = Data() // Your file data
let uploadResponse = try await completionClient.uploadFile(
    fileData: fileData,
    fileName: "document.pdf",
    user: "user_123",
    mimeType: "application/pdf"
)

let localFiles = [APIFile(
    type: .document,
    transferMethod: .localFile,
    uploadFileId: uploadResponse.id
)]

let responseWithLocalFile = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Summarize this document",
    user: "user_123",
    files: localFiles
)
```

### Workflow Client

```swift
let workflowClient = try WorkflowClient(apiKey: "your_api_key")

// Run a workflow
let workflowResponse = try await workflowClient.runWorkflow(
    inputs: ["input_key": "input_value"],
    user: "user_123"
)

print("Workflow status: \(workflowResponse.data.status)")
print("Outputs: \(workflowResponse.data.outputs)")

// Get workflow result
let result = try await workflowClient.getWorkflowRunDetail(
    workflowId: workflowResponse.workflowRunId
)
```

### Knowledge Base Client

```swift
// Create a new knowledge base client
let knowledgeBaseClient = try KnowledgeBaseClient(apiKey: "your_api_key")

// Create a new dataset
let dataset = try await knowledgeBaseClient.createDataset(name: "My Knowledge Base")

// Create document by uploading a file
let fileData = Data() // Your document data
let processRule = ProcessRule(
    mode: "automatic",
    rules: ProcessRuleRules(
        preProcessingRules: [
            PreProcessingRule(id: "remove_extra_spaces", enabled: true)
        ],
        segmentation: Segmentation(separator: "\n", maxTokens: 500)
    )
)

let documentResponse = try await knowledgeBaseClient.createDocument(
    datasetId: dataset.id,
    fileData: fileData,
    fileName: "document.pdf",
    processRule: processRule
)

// List documents in the dataset
let documents = try await knowledgeBaseClient.listDocuments(datasetId: dataset.id)
for document in documents.data {
    print("Document: \(document.name)")
}
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
    conversationId: "conversation_id",
    user: "user_123"
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
let chatClient = try ChatClient(apiKey: "your_api_key")

// Convert text to audio (only available in ChatClient)
let audioResponse = try await chatClient.textToAudio(
    text: "Hello, this is a test message",
    user: "user_123"
)

// Convert audio to text
let audioData = Data() // Your audio file data
let textResponse = try await chatClient.audioToText(
    audioFile: audioData,
    user: "user_123"
)
```

## Enhanced Features

### Application Information & Configuration

Get comprehensive application details and configuration:

```swift
// Get basic application information (available in multiple clients)
let chatClient = try ChatClient(apiKey: "your_api_key")
let appInfo = try await chatClient.getApplicationInfo()
print("App: \(appInfo.name) - \(appInfo.description)")
print("Mode: \(appInfo.mode), Author: \(appInfo.authorName)")

// Get application meta information (available in ChatClient)
let meta = try await chatClient.getApplicationMeta()
// Note: Check actual response structure for available properties

// Get site/webapp settings (available in CompletionClient)
let completionClient = try CompletionClient(apiKey: "your_api_key")
let site = try await completionClient.getApplicationSiteSettings()
print("Title: \(site.title ?? "N/A")")
// Note: Check actual response structure for available properties
```

### Enhanced Feedback & Annotations

Manage feedback and annotations with rich content support:

```swift
let chatClient = try ChatClient(apiKey: "your_api_key")

// Get application feedbacks (available in ChatClient)
let feedbacks = try await chatClient.getApplicationFeedbacks(page: 1, limit: 20)
for feedback in feedbacks.data {
    print("Feedback: \(feedback.rating) - \(feedback.content ?? "No content")")
}

// Manage annotations (available in ChatClient)
let annotations = try await chatClient.getAnnotations(page: 1, limit: 20)
print("Total annotations: \(annotations.total)")

// Create new annotation
let newAnnotation = try await chatClient.createAnnotation(
    question: "What is artificial intelligence?",
    answer: "AI is a branch of computer science focused on creating systems that can perform tasks typically requiring human intelligence."
)

// Configure annotation reply settings
let settingsResponse = try await chatClient.configureAnnotationReply(
    action: "enable",
    embeddingModelProvider: "openai",
    embeddingModel: "text-embedding-ada-002",
    scoreThreshold: 0.8
)
```

### Conversation Variables

Extract and manage structured data from conversations:

```swift
// Get conversation variables
let variables = try await chatClient.getConversationVariables(
    conversationId: "conv_123",
    user: "user_123",
    limit: 50
)

for variable in variables.data {
    print("Variable: \(variable.name) (\(variable.valueType))")
    print("Value: \(variable.value)")
    print("Description: \(variable.description ?? "No description")")
}
```

### Enhanced Chat Features

Utilize advanced chat capabilities:

```swift
// Create chat message with auto-generation control
let response = try await chatClient.createChatMessage(
    inputs: ["context": "customer support"],
    query: "I need help with my order",
    user: "user_123",
    conversationId: nil,
    files: nil,
    autoGenerateName: false // Disable automatic title generation
)

// Get workflow logs (for workflow-enabled apps)
let workflowLogs = try await workflowClient.getWorkflowLogs(
    keyword: "error",
    status: "failed",
    page: 1,
    limit: 10
)

for log in workflowLogs.data {
    print("Workflow: \(log.workflowRun.id)")
    print("Status: \(log.workflowRun.status)")
    print("Duration: \(log.workflowRun.elapsedTime)s")
    if let error = log.workflowRun.error {
        print("Error: \(error)")
    }
}
```

## API Reference

### Core Classes

- **`DifyClient`**: Base client with common functionality
- **`ChatClient`**: Chat-based interactions and conversation management
- **`CompletionClient`**: Completion-based interactions
- **`WorkflowClient`**: Workflow execution and management
- **`KnowledgeBaseClient`**: Knowledge base and document management

### Response Models

All API responses are strongly typed with Swift structs and include comprehensive support for the latest Dify API features. The SDK uses custom `AnyCodable` for flexible JSON handling and proper snake_case to camelCase conversion:

#### Core Response Models
- `ChatMessageResponse`
- `CompletionMessageResponse` 
- `WorkflowResponse`
- `FileUploadResponse`
- `DatasetResponse`
- `DocumentResponse`

#### Application Information Models
- `ApplicationInfoResponse` - Basic app information
- `EnhancedApplicationParametersResponse` - Detailed app parameters and configuration
- `ApplicationMetaResponse` - Application metadata and tool icons
- `ApplicationSiteResponse` - Site/webapp settings

#### Enhanced Feedback & Annotation Models
- `EnhancedMessageFeedbackRequest` - Feedback with content support
- `ApplicationFeedbacksResponse` - Application feedback listings
- `AnnotationListResponse` - Annotation management
- `AnnotationReplySettingsResponse` - Annotation configuration
- `AnnotationJobStatusResponse` - Annotation job tracking

#### Conversation & Workflow Models
- `ConversationVariablesResponse` - Structured conversation data
- `WorkflowLogsResponse` - Workflow execution logs and history

#### Enhanced File Support
- `FileType` enum supporting: `.document`, `.image`, `.audio`, `.video`, `.custom`
- `APIFile` with comprehensive file handling for all supported formats

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

// Use createDocument method with file data
let fileData = Data("Document content".utf8)
let response = try await knowledgeBaseClient.createDocument(
    datasetId: "dataset_id",
    fileData: fileData,
    fileName: "Custom Document.txt",
    processRule: processRule
)
```

## Testing

The SDK includes comprehensive tests using Swift Testing framework with enhanced parallel execution support:

```bash
# Run all tests (parallel execution by default)
swift test

# Run specific test suites
swift test --filter "DifyClientTests"
swift test --filter "ChatClientTests"
swift test --filter "CompletionClientTests"
swift test --filter "WorkflowClientTests"
swift test --filter "KnowledgeBaseClientTests"
swift test --filter "ModelsTests"
swift test --filter "UtilitiesTests"

# Run tests with verbose output
swift test --verbose

# Run tests sequentially if needed (not recommended)
swift test --no-parallel
```

### Test Features

- **100% Mock-based Testing**: All tests use mock responses with no real API calls required
- **Parallel Test Execution**: Tests use isolated mock sessions for thread-safe parallel execution
- **No External Dependencies**: Tests run offline and are completely deterministic
- **Comprehensive Coverage**: Includes unit tests for all API endpoints, streaming responses, error scenarios, and edge cases
- **Swift Testing Framework**: Built with the modern Swift Testing framework introduced at WWDC 2024

## Platform Support

### Darwin Platforms (Full Support)
- macOS 13.0+
- iOS 16.0+
- tvOS 16.0+
- watchOS 9.0+

### Linux Support
The SDK compiles and runs on Linux with Swift 6.1+. However, please note:

⚠️ **Linux Testing Limitations**: Due to differences in URLSession implementations between Darwin and Linux platforms, our comprehensive test suite currently runs only on Darwin platforms. Linux support is validated through:
- Successful compilation on Linux
- API compatibility analysis
- Community feedback and issue reports

Linux users are encouraged to report any compatibility issues they encounter. While we cannot guarantee the same level of testing coverage as Darwin platforms, we are committed to addressing Linux-specific issues as they arise.

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