# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift SDK for Dify AI that provides a complete interface to the Dify Service API. The SDK is built with modern Swift practices, using async/await concurrency and comprehensive error handling.

### SDK Purpose
- Provides a complete Swift interface to all Dify AI Service API endpoints
- Supports chat completions, workflows, knowledge base management, and more
- Built for iOS, macOS, tvOS, watchOS, and Linux platforms
- Designed for both synchronous and streaming API interactions

## Development Rules

### **TODO Management**
**MOST IMPORTANT**: Always update the [TODO.md](./TODO.md) file when:
- Starting work on a new feature
- Completing a feature or subtask
- Discovering new requirements or edge cases
- Changing feature priorities
- Finding bugs that need to be tracked

**The TODO.md file is the single source of truth for all pending work.**

### Documentation and Learning Resources

**Context7 MCP Integration:**
When needing Swift documentation or migration guidance, use these Context7 library IDs:
- `/swiftlang/swift` - For Swift language documentation and APIs
- `/swiftlang/swift-migration-guide` - For Swift 6 migration guidance, common errors and best practices

## Architecture

### Core Client Structure
- **`DifyClient`** - Base client class providing common functionality and base API methods
- **`ChatClient`** - Extends DifyClient for chat-based interactions and conversation management
- **`CompletionClient`** - Extends DifyClient for completion-based interactions
- **`WorkflowClient`** - Extends DifyClient for workflow execution and management
- **`KnowledgeBaseClient`** - Extends DifyClient for knowledge base and document management

### Key Components
- **Models.swift** - Contains all request/response models, enums, and data structures
- **Utilities.swift** - Extensions for URL, URLRequest, JSON handling, and streaming responses
- **Examples/main.swift** - Usage examples and SDK demonstration

## Development Commands

### Building and Testing
```bash
# Build the project
swift build

# Run all tests (uses Swift Testing framework)
swift test

# Run specific test suites
swift test --filter "DifyClientTests"
swift test --filter "ChatClientTests"
swift test --filter "CompletionClientTests"
swift test --filter "WorkflowClientTests"
swift test --filter "KnowledgeBaseClientTests"

# Run advanced mock tests
swift test --filter "AdvancedMockAPITests"
swift test --filter "ErrorHandlingMockTests"
```

### Test Environment
- **All tests use mock responses** - No real API calls or environment variables required
- **No external dependencies** - Tests run offline and are deterministic
- **Swift Testing framework** - Uses the modern Swift Testing framework (WWDC 2024)

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
- **`MockingInfrastructure.swift`** - Custom URLProtocol for intercepting HTTP requests
- **`MockDataProvider.swift`** - Predefined mock responses for all API endpoints
- **`TestUtilities.swift`** - Helper functions for creating mock clients and test setup

### Test Categories
1. **Basic Client Tests** - Client initialization and parameter validation
2. **API Method Tests** - All endpoint functionality with mock responses
3. **Streaming Tests** - Server-sent events simulation and parsing
4. **Error Scenario Tests** - HTTP errors, network failures, malformed responses
5. **Request Validation Tests** - Header verification, body encoding, authorization

### Running Individual Tests
```bash
# Run a specific test class
swift test --filter "AdvancedChatClientTests"

# Run tests with parallel execution
swift test --parallel
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
3. Add comprehensive test coverage with mocks
4. Update documentation in `DOCUMENTATION.md`

### New Client Types
1. Extend `DifyClient` for specialized functionality
2. Follow existing patterns for initialization and error handling
3. Add mock test infrastructure for new client
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
4. Add comprehensive test coverage with mocks in the corresponding test file
5. Update `MockDataProvider.swift` with appropriate mock responses
6. Add usage example to `Examples/main.swift` if significant
7. Update `DOCUMENTATION.md` with the new functionality

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
- **Update TODO.md** when discovering new tasks or completing existing ones
- **Follow existing patterns** - consistency is key
- **Document breaking changes** in commit messages
- **Test on multiple platforms** if making platform-specific changes