# AGENTS.md

## Project Overview

This is a Swift SDK for Dify AI that provides a complete interface to the Dify Service API. The SDK is built with modern Swift practices, using async/await concurrency and comprehensive error handling.

### SDK Purpose
- Provides a complete Swift interface to all Dify AI Service API endpoints
- Supports chat completions, workflows, knowledge base management, and more
- Built for iOS, macOS, tvOS, watchOS, and Linux platforms
- Designed for both synchronous and streaming API interactions

## Development Rules

### Documentation and Learning Resources

**Context7 MCP Integration:**
When needing Swift documentation or migration guidance, use these Context7 library IDs:
- `/swiftlang/swift` - For Swift language documentation and APIs
- `/swiftlang/swift-testing` - For Swift Testing framework documentation and APIs
- `/swiftlang/swift-migration-guide` - For Swift 6 migration guidance, common errors and best practices

**IMPORTANT: Swift 6 Error Handling Principle**
When creating tests or implementing new features, proactively seek assistance from Context7's Swift migration guide (`/swiftlang/swift-migration-guide`) if you encounter Swift 6 related errors. This ensures compatibility with Swift 6's strict concurrency checking and helps avoid common migration pitfalls.

## Architecture

### Core Client Structure
- **`DifyClient`** - Base client class providing common functionality and base API methods
- **`ChatClient`** - Extends DifyClient for chat-based interactions and conversation management
- **`CompletionClient`** - Extends DifyClient for completion-based interactions
- **`WorkflowClient`** - Extends DifyClient for workflow execution and management
- **`KnowledgeBaseClient`** - Extends DifyClient for knowledge base and document management

### Key Components
- **Models.swift** - Contains all request/response models, enums, and data structures (100% test coverage)
- **Utilities.swift** - Extensions for URL, URLRequest, JSON handling, and streaming responses (comprehensive test coverage)
- **Examples/main.swift** - Usage examples and SDK demonstration

## Development Commands

### Building and Testing
```bash
# Build the project
swift build

# Run all tests (uses Swift Testing framework)
# Tests now support parallel execution with isolated mock sessions
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

### Test Environment
- **All tests use mock responses** - No real API calls or environment variables required
- **No external dependencies** - Tests run offline and are deterministic
- **Swift Testing framework** - Uses the modern Swift Testing framework (WWDC 2024)
- **Parallel test execution** - Tests use isolated mock sessions for thread-safe parallel execution

## Code Architecture Details

### Request/Response Flow
1. All clients inherit from `DifyClient` which provides base HTTP functionality
2. Requests are constructed using `sendRequest()` or `sendRequestWithFiles()` methods
3. JSON encoding/decoding uses custom `JSONEncoder.difyEncoder` and `JSONDecoder.difyDecoder`
4. Error handling through `DifyError` enum with specific error types

### Key Design Patterns
- **Inheritance-based client architecture** - Specialized clients extend base functionality
- **Protocol-oriented file handling** - `APIFile` struct supports multiple file types and transfer methods
- **Async/await throughout** - All API methods use modern Swift concurrency
- **Comprehensive error handling** - Detailed error types with localized descriptions

### Multi-format File Support
The SDK supports comprehensive file handling across document, image, audio, video, and custom file types with both remote URL and local file upload capabilities.

### Streaming Support
- `StreamingResponse` struct provides AsyncSequence for server-sent events
- Supports chat streaming, workflow streaming, and various event types
- Custom URLSession-based streaming implementation

## Test Structure

### Mock-based Testing Infrastructure
- **`MockURLProtocol.swift`** - Custom URLProtocol for intercepting HTTP requests (global state, legacy)
- **`IsolatedMockSession.swift`** - Instance-based mock sessions for parallel test execution
- **`MockDataProvider.swift`** - Predefined mock responses for all API endpoints
- **`TestUtilities.swift`** - Helper functions for creating mock clients with isolated sessions
- **`DifyTestCase.swift`** - Base test class with common test helpers
- **`TestHelpers.swift`** - Extension methods for proper test setup

### Writing Tests
Tests use isolated mock sessions for parallel execution. When writing tests:

```swift
@Test func myTest() async throws {
    // Create a client with an isolated mock session
    let (client, mockSession) = TestUtilities.createTestClientWithMockSession()
    
    // Register your mock responses on the isolated session
    mockSession.register(
        method: "POST",
        urlPattern: "/endpoint",
        response: MockResponse.json(mockData)
    )
    
    // ... rest of your test
}
```

Each test gets its own isolated mock session, eliminating race conditions and enabling safe parallel execution.

### Test Categories
1. **Basic Client Tests** - Client initialization and parameter validation
2. **API Method Tests** - All endpoint functionality with mock responses
3. **Streaming Tests** - Server-sent events simulation and parsing
4. **Error Scenario Tests** - HTTP errors, network failures, malformed responses
5. **Request Validation Tests** - Header verification, body encoding, authorization
6. **Model Tests** - Comprehensive testing of all data models, enums, and AnyCodable
7. **Utilities Tests** - Testing of utility functions, extensions, and helper classes

### Running Individual Tests
```bash
# Run a specific test class
swift test --filter "ChatClientTests"

# Run a specific test method
swift test --filter "ChatClientTests/testStreamingChatMessage"

# Run tests matching a pattern
swift test --filter "test.*Streaming"
```

## Key Implementation Notes

### Error Handling
- All API errors are wrapped in `DifyError` enum
- HTTP errors include status codes and response messages
- Network errors preserve underlying error information
- Decoding errors provide detailed failure context

### Concurrency
- All clients are marked as `@unchecked Sendable` for Swift 6 compatibility
- Async/await used throughout for network operations
- Streaming responses implement `AsyncSequence` for iteration

### JSON Handling
- Custom JSON coders handle snake_case to camelCase conversion
- Proper date formatting for API compatibility
- Comprehensive model coverage for all Dify API endpoints

## Adding New Features

### New API Endpoints
1. Add request/response models to `Models.swift`
2. Implement method in appropriate client class
3. Add comprehensive test coverage using isolated mock sessions
4. Update documentation and examples as needed

### New Client Types
1. Extend `DifyClient` for specialized functionality
2. Follow existing patterns for initialization and error handling
3. Add test factory methods in `TestUtilities.swift` for the new client
4. Update examples in `Examples/main.swift`

## Platform Support

- **Swift 6.1+** required
- **Platforms**: macOS 13.0+, iOS 16.0+, tvOS 16.0+, watchOS 9.0+
- **Dependencies**: Foundation, FoundationNetworking (Linux)
- **Package Manager**: Swift Package Manager

## Code Style Guidelines

### Swift Best Practices
- Use descriptive variable and function names following Swift naming conventions
- Prefer value types (structs) over reference types (classes) where appropriate
- Use `guard` statements for early returns and validation
- Leverage Swift's type system with proper error handling
- Document all public APIs with clear doc comments

### Async/Await Patterns
- All network operations use async/await
- Proper error propagation through throws
- No completion handlers or callbacks
- Structured concurrency where applicable

### Testing Philosophy
- Every public API method must have corresponding tests
- Tests should be independent and not rely on external services
- Mock all network interactions for predictable test results
- Test both success and failure scenarios
- Include edge cases and error conditions

## Common Tasks

### Adding a New API Method
1. Define request/response models in `Models.swift`
2. Add the method to the appropriate client class
3. Use `sendRequest()` for standard requests or `sendRequestWithFiles()` for file uploads
4. Add comprehensive test coverage using isolated mock sessions
5. Update `MockDataProvider.swift` with appropriate mock responses if using shared mocks
6. Add usage example to `Examples/main.swift` if significant
7. Document the new functionality appropriately

### Debugging Tips
- Check `DifyError` cases for specific error handling
- Use `print(request.debugDescription)` to inspect outgoing requests
- Verify JSON encoding/decoding with custom coders
- Test streaming responses with mock SSE data
- Validate authorization headers in request construction

### Performance Considerations
- Streaming responses use minimal memory through AsyncSequence
- File uploads support both memory and disk-based approaches
- JSON parsing is optimized with custom decoders
- URLSession configuration is shared across client instances

## API Coverage Status

The SDK currently implements:
- ✅ Chat completions (streaming and non-streaming)
- ✅ Workflow execution and streaming
- ✅ Knowledge base management (datasets, documents, segments)
- ✅ Completion API
- ✅ Message feedback and annotations
- ✅ File upload support
- ✅ Conversation management
- ✅ Application information retrieval
- ✅ Error handling and retry logic

## Important Reminders

- **Always run tests** before committing changes: `swift test`
- **Follow existing patterns** - consistency is key
- **Document breaking changes** in commit messages
- **Test on multiple platforms** if making platform-specific changes
- **Use isolated mock sessions** when writing tests to ensure thread safety