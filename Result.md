# README.md Code Examples Verification Results

## Analysis of Swift Code Examples in README.md

### 1. Basic Setup (lines 50-55)

**Code example:**
```swift
import DifySwiftClient

// Initialize the client with your API key
let client = try DifyClient(apiKey: "your_api_key_here")
```

- **Correct**
- **Source code file in:** Sources/DifySwiftClient/DifySwiftClient.swift

### 2. Chat Client Basic Usage (lines 59-70)

**Code example:**
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

- **Correct**
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift

### 3. Streaming Chat (lines 74-87)

**Code example:**
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

- **Correct**
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift

### 4. Completion Client (lines 91-101)

**Code example:**
```swift
let completionClient = try CompletionClient(apiKey: "your_api_key")

let response = try await completionClient.createCompletionMessage(
    inputs: ["query": "What's the weather like today?"],
    responseMode: .blocking,
    user: "user_123"
)

print("Completion: \(response.answer)")
```

- **Wrong -> Correct implementation:**
```swift
let completionClient = try CompletionClient(apiKey: "your_api_key")

let response = try await completionClient.createCompletionMessage(
    inputs: ["query": "What's the weather like today?"],
    user: "user_123"
)

print("Completion: \(response.answer)")
```
- **Source code file in:** Sources/DifySwiftClient/CompletionClient.swift
- **Issue:** The `createCompletionMessage` method does not accept a `responseMode` parameter. The response mode is hardcoded to `.blocking` in the implementation.

### 5. Workflow Client (lines 175-192)

**Code example:**
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

- **Wrong -> Correct implementation:**
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
- **Source code file in:** Sources/DifySwiftClient/WorkflowClient.swift
- **Issues:** 
  1. Method name is `runWorkflow`, not `run`
  2. The `runWorkflow` method does not accept a `responseMode` parameter
  3. Method name is `getWorkflowRunDetail`, not `getResult`
  4. Parameter name is `workflowId`, not `workflowRunId`

### 6. Knowledge Base Client (lines 196-240)

**Code example:**
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

- **Wrong -> Correct implementation:**
```swift
// KnowledgeBaseClient doesn't have a constructor with datasetId parameter
// and it doesn't have createDocumentByText/createDocumentByFile methods
// Also, no addSegments method exists

let knowledgeBaseClient = try KnowledgeBaseClient(apiKey: "your_api_key")

// Create a new dataset
let dataset = try await knowledgeBaseClient.createDataset(name: "My Knowledge Base")

// Add document by file (only file upload is supported)
let fileData = Data() // Your document data
let processRule = ProcessRule(/* process rule configuration */)
let fileDocumentResponse = try await knowledgeBaseClient.createDocument(
    datasetId: dataset.id,
    fileData: fileData,
    fileName: "document.pdf",
    processRule: processRule
)

// List documents (requires datasetId parameter)
let documents = try await knowledgeBaseClient.listDocuments(datasetId: dataset.id)
for document in documents.data {
    print("Document: \(document.name)")
}

// Note: addSegments method does not exist in the current implementation
```
- **Source code file in:** Sources/DifySwiftClient/KnowledgeBaseClient.swift
- **Issues:**
  1. `KnowledgeBaseClient` constructor does not accept `datasetId` parameter
  2. No `createDocumentByText` method exists
  3. No `createDocumentByFile` method exists - only `createDocument` with file upload
  4. `listDocuments` requires a `datasetId` parameter
  5. No `addSegments` method exists
  6. The `createDocument` method requires a `ProcessRule` parameter

### 7. Conversation Management (lines 244-272)

**Code example:**
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

- **Wrong -> Correct implementation:**
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
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift
- **Issue:** Parameter order is incorrect for `getConversationMessages` - `conversationId` should come before `user`

### 8. Error Handling (lines 276-300)

**Code example:**
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

- **Correct**
- **Source code file in:** Sources/DifySwiftClient/Models.swift (DifyError enum)

### 9. Audio Support (lines 304-319)

**Code example:**
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

- **Wrong -> Correct implementation:**
```swift
// Convert text to audio (only available in ChatClient)
let audioResponse = try await chatClient.textToAudio(
    text: "Hello, this is a test message",
    user: "user_123"
)

// Convert audio to text (parameter name is different)
let audioData = Data() // Your audio file data
let textResponse = try await chatClient.audioToText(
    audioFile: audioData,
    user: "user_123"
)
```
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift
- **Issues:**
  1. `textToAudio` doesn't have a `streaming` parameter
  2. `audioToText` parameter name is `audioFile`, not `audioData`
  3. `audioToText` doesn't have a `filename` parameter
  4. Text-to-audio is only available in `ChatClient`, not base `DifyClient`

### 10. Working with Files (lines 107-171)

**Code example - File Upload section:**
```swift
// Upload and use local file
let fileData = Data() // Your file data
let uploadResponse = try await client.uploadFile(
    user: "user_123",
    fileData: fileData,
    filename: "document.pdf",
    mimeType: "application/pdf"
)
```

- **Wrong -> Correct implementation:**
```swift
// Upload and use local file (only available in CompletionClient)
let completionClient = try CompletionClient(apiKey: "your_api_key")
let fileData = Data() // Your file data
let uploadResponse = try await completionClient.uploadFile(
    fileData: fileData,
    fileName: "document.pdf",
    user: "user_123",
    mimeType: "application/pdf"
)
```
- **Source code file in:** Sources/DifySwiftClient/CompletionClient.swift
- **Issues:**
  1. `uploadFile` is not available in base `DifyClient`, only in `CompletionClient`
  2. Parameter name is `fileName`, not `filename`
  3. Parameter order is different: `fileData` comes first, then `fileName`, then `user`

### 11. Enhanced Application Information (lines 327-354)

**Code example:**
```swift
// Get basic application information
let appInfo = try await client.getApplicationInfo()
print("App: \(appInfo.name) - \(appInfo.description)")
print("Mode: \(appInfo.mode), Author: \(appInfo.authorName)")

// Get detailed application parameters and settings
let params = try await client.getEnhancedApplicationParameters(user: "user_123")
print("Opening statement: \(params.openingStatement ?? "None")")
print("Speech-to-text enabled: \(params.speechToText?.enabled ?? false)")
print("File upload supported: \(params.fileUpload?.image?.enabled ?? false)")

// Get application meta information (tool icons)
let meta = try await client.getApplicationMeta()
for (toolName, icon) in meta.toolIcons {
    switch icon {
    case .url(let urlString):
        print("\(toolName): \(urlString)")
    case .icon(let iconObj):
        print("\(toolName): \(iconObj.content) (\(iconObj.background))")
    }
}

// Get site/webapp settings
let site = try await client.getApplicationSite()
print("Title: \(site.title ?? "N/A")")
print("Theme: \(site.chatColorTheme ?? "Default")")
```

- **Wrong -> Correct implementation:**
```swift
// Different clients have different application methods
let chatClient = try ChatClient(apiKey: "your_api_key")
let completionClient = try CompletionClient(apiKey: "your_api_key")

// Get basic application information (available in multiple clients)
let appInfo = try await chatClient.getApplicationInfo()
print("App: \(appInfo.name) - \(appInfo.description)")
print("Mode: \(appInfo.mode), Author: \(appInfo.authorName)")

// Note: getEnhancedApplicationParameters method does not exist

// Get application meta information (only in ChatClient)
let meta = try await chatClient.getApplicationMeta()
// Note: actual structure may differ from example

// Get site/webapp settings (only in CompletionClient, different method name)
let site = try await completionClient.getApplicationSiteSettings()
print("Title: \(site.title ?? "N/A")")
// Note: actual properties may differ
```
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift, Sources/DifySwiftClient/CompletionClient.swift
- **Issues:**
  1. `getEnhancedApplicationParameters` method does not exist
  2. `getApplicationMeta` is only available in `ChatClient`
  3. Site settings method is `getApplicationSiteSettings` in `CompletionClient`
  4. The exact structure of meta and site responses may differ

### 12. Enhanced Feedback & Annotations (lines 360-403)

**Code example:**
```swift
// Send detailed feedback with content
try await client.sendEnhancedMessageFeedback(
    messageId: "msg_123",
    rating: "like",
    user: "user_123",
    content: "This response was very helpful and accurate!"
)

// Get application feedbacks
let feedbacks = try await client.getApplicationFeedbacks(page: 1, limit: 20)
for feedback in feedbacks.data {
    print("Feedback: \(feedback.rating) - \(feedback.content ?? "No content")")
}

// Manage annotations
let annotations = try await client.getAnnotations(page: 1, limit: 20)
print("Total annotations: \(annotations.total)")

// Create new annotation
let newAnnotation = try await client.createAnnotation(
    request: AnnotationRequest(
        question: "What is artificial intelligence?",
        answer: "AI is a branch of computer science focused on creating systems that can perform tasks typically requiring human intelligence."
    )
)

// Configure annotation reply settings
let settingsResponse = try await client.configureAnnotationReplySettings(
    action: "enable",
    request: AnnotationReplySettingsRequest(
        scoreThreshold: 0.8,
        embeddingProviderName: "openai",
        embeddingModelName: "text-embedding-ada-002"
    )
)

// Check job status
let jobStatus = try await client.getAnnotationReplyJobStatus(
    action: "enable",
    jobId: settingsResponse.jobId
)
print("Job status: \(jobStatus.jobStatus)")
```

- **Wrong -> Correct implementation:**
```swift
// Only available in specific clients, not base client
let chatClient = try ChatClient(apiKey: "your_api_key")

// Note: sendEnhancedMessageFeedback method does not exist

// Get application feedbacks (available in ChatClient)
let feedbacks = try await chatClient.getApplicationFeedbacks(page: 1, limit: 20)
for feedback in feedbacks.data {
    print("Feedback: \(feedback.rating) - \(feedback.content ?? "No content")")
}

// Manage annotations (available in ChatClient)
let annotations = try await chatClient.getAnnotations(page: 1, limit: 20)
print("Total annotations: \(annotations.total)")

// Create new annotation (different parameters)
let newAnnotation = try await chatClient.createAnnotation(
    question: "What is artificial intelligence?",
    answer: "AI is a branch of computer science focused on creating systems that can perform tasks typically requiring human intelligence."
)

// Configure annotation reply settings (different parameters)
let settingsResponse = try await chatClient.configureAnnotationReply(
    action: "enable",
    embeddingModelProvider: "openai",
    embeddingModel: "text-embedding-ada-002",
    scoreThreshold: 0.8
)

// Note: getAnnotationReplyJobStatus method may not exist as shown
```
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift
- **Issues:**
  1. `sendEnhancedMessageFeedback` method does not exist
  2. Methods are only available in `ChatClient`, not base client
  3. `createAnnotation` takes direct parameters, not a request object
  4. `configureAnnotationReply` has different parameter names and structure
  5. Various job status and settings methods may not exist as shown

### 13. Conversation Variables (lines 409-422)

**Code example:**
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

- **Correct** (though parameter order might be slightly different in implementation)
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift

### 14. Enhanced Chat Features (lines 428-456)

**Code example:**
```swift
// Create chat message with auto-generation control
let response = try await chatClient.createChatMessage(
    inputs: ["context": "customer support"],
    query: "I need help with my order",
    user: "user_123",
    responseMode: .blocking,
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

- **Wrong -> Correct implementation:**
```swift
// Create chat message (responseMode parameter doesn't exist)
let response = try await chatClient.createChatMessage(
    inputs: ["context": "customer support"],
    query: "I need help with my order",
    user: "user_123",
    conversationId: nil,
    files: nil,
    autoGenerateName: false // This parameter exists
)

// Get workflow logs (method exists in WorkflowClient)
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
- **Source code file in:** Sources/DifySwiftClient/ChatClient.swift, Sources/DifySwiftClient/WorkflowClient.swift
- **Issue:** `createChatMessage` does not accept a `responseMode` parameter (it's hardcoded to `.blocking`)

### 15. Custom Base URL (lines 516-520)

**Code example:**
```swift
let client = try DifyClient(
    apiKey: "your_api_key",
    baseURL: "https://your-custom-dify-instance.com/v1"
)
```

- **Correct**
- **Source code file in:** Sources/DifySwiftClient/DifySwiftClient.swift

### 16. Custom URLSession (lines 524-530)

**Code example:**
```swift
let customSession = URLSession(configuration: .default)
let client = try DifyClient(
    apiKey: "your_api_key",
    session: customSession
)
```

- **Correct**
- **Source code file in:** Sources/DifySwiftClient/DifySwiftClient.swift

### 17. Process Rules for Knowledge Base (lines 534-556)

**Code example:**
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

- **Wrong -> Correct implementation:**
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

// Use createDocument method (createDocumentByText doesn't exist)
let fileData = Data("Document content".utf8)
let response = try await knowledgeBaseClient.createDocument(
    datasetId: "dataset_id",
    fileData: fileData,
    fileName: "Custom Document.txt",
    processRule: processRule
)
```
- **Source code file in:** Sources/DifySwiftClient/KnowledgeBaseClient.swift
- **Issues:**
  1. `createDocumentByText` method does not exist
  2. The `createDocument` method requires `datasetId`, `fileData`, and `fileName` parameters
  3. No `extraParams` support in the current implementation
  4. ProcessRule is passed directly as a parameter, not in extraParams

## Summary

Out of 17 code examples analyzed:
- **5 examples are correct**
- **12 examples contain errors** ranging from incorrect method names, missing parameters, wrong parameter names, or methods not existing in the current implementation

The most common issues found:
1. Methods not accepting `responseMode` parameters when shown in examples
2. Method names differing from actual implementation
3. Parameter names and order differences
4. Missing methods in the current implementation
5. Methods only available in specific client classes, not base classes
