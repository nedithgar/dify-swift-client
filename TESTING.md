# Mock-Based Testing Guide

This document describes how to run and maintain the mock-based test suite for the Dify Swift Client.

## Overview

The test suite has been completely refactored to use **mock responses** instead of real server calls. This provides several benefits:

- **Faster execution**: No network requests
- **Reliable results**: Tests don't depend on external services
- **Offline testing**: No internet connection required
- **Consistent behavior**: Mock responses are predictable

## Running the Tests

### Swift Testing (WWDC 2024)

The project uses Swift Testing framework for all tests:

```bash
# Run all tests
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

### No Environment Variables Required

The new test suite **does not require** any environment variables:

- ❌ No `DIFY_API_KEY` needed
- ❌ No `DIFY_BASE_URL` needed
- ❌ No `DIFY_USER_ID` needed
- ✅ All tests use mock responses

## Test Structure

### Core Test Files

1. **`DifySwiftClientTests.swift`** - Main test file with basic client functionality
2. **`AdvancedMockTests.swift`** - Advanced API features and error scenarios
3. **`EnhancedAPITests.swift`** - Model validation and data structure tests
4. **`MockingInfrastructure.swift`** - Mock URLProtocol and response providers
5. **`TestUtilities.swift`** - Helper functions for test setup

### Mocking Infrastructure

#### MockURLProtocol
Custom URLProtocol that intercepts HTTP requests and returns predefined responses:

```swift
// Register a mock for a specific endpoint
MockURLProtocol.registerMock(
    endpoint: "chat-messages",
    response: MockResponse.json(mockChatResponse)
)

// Use custom request handler for complex scenarios
MockURLProtocol.setRequestHandler { request in
    // Custom logic here
    return (httpResponse, data)
}
```

#### MockDataProvider
Provides predefined mock responses for all Dify API endpoints:

```swift
// Predefined responses available
MockDataProvider.chatMessageResponse
MockDataProvider.completionMessageResponse
MockDataProvider.workflowResponse
MockDataProvider.fileUploadResponse
MockDataProvider.applicationInfoResponse
// ... and many more
```

#### TestUtilities
Helper functions for creating mock clients and setting up tests:

```swift
// Create mock clients
let chatClient = try TestUtilities.createMockChatClient()
let completionClient = try TestUtilities.createMockCompletionClient()

// Setup standard mocks for all endpoints
TestUtilities.setupStandardMocks()

// Cleanup after tests
TestUtilities.cleanup()
```

### Test Categories

#### 1. Basic Client Tests
- Client initialization
- Parameter validation
- Error handling for invalid inputs

#### 2. API Method Tests  
- Chat message creation
- Completion requests
- Workflow execution
- File uploads
- Knowledge base operations

#### 3. Streaming Tests
- Server-sent events simulation
- Multiple streaming events
- Stream data parsing

#### 4. Error Scenario Tests
- HTTP error codes (401, 429, 500, etc.)
- Network failures
- Malformed responses
- Invalid JSON parsing

#### 5. Request Validation Tests
- Correct HTTP headers
- Request body encoding
- Authorization header verification
- Content-Type validation

## Adding New Tests

### Basic Test Pattern

```swift
@Test("Description of what is being tested")
func testSomething() async throws {
    // 1. Setup mock responses
    TestUtilities.setupStandardMocks()
    // or register specific mocks:
    // MockURLProtocol.registerMock(endpoint: "...", response: ...)
    
    // 2. Create mock client
    let client = try TestUtilities.createMockChatClient()
    
    // 3. Execute the API call
    let response = try await client.someMethod(...)
    
    // 4. Verify the response
    #expect(response.someField == "expected value")
    
    // 5. Cleanup
    TestUtilities.cleanup()
}
```

### Error Testing Pattern

```swift
@Test("Handle specific error scenario")
func testErrorScenario() async throws {
    // Setup error mock
    MockURLProtocol.registerMock(
        endpoint: "api-endpoint",
        response: MockResponse.httpError(statusCode: 401, message: "Unauthorized")
    )
    
    let client = try TestUtilities.createMockClient()
    
    // Verify error is thrown and handled correctly
    do {
        _ = try await client.someMethod(...)
        Issue.record("Expected error was not thrown")
    } catch let error as DifyError {
        if case .httpError(let code, let message) = error {
            #expect(code == 401)
            #expect(message?.contains("Unauthorized") == true)
        } else {
            Issue.record("Wrong error type: \(error)")
        }
    }
    
    TestUtilities.cleanup()
}
```

### Request Validation Pattern

```swift
@Test("Verify request construction")
func testRequestValidation() async throws {
    // Use request capture to inspect requests
    MockRequestCapture.startCapturing()
    
    let client = try TestUtilities.createMockClient()
    _ = try await client.someMethod(...)
    
    // Verify the request was constructed correctly
    let requests = MockRequestCapture.getCapturedRequests()
    #expect(requests.count == 1)
    
    let request = requests[0]
    TestAssertions.verifyAuthHeader(request: request, expectedApiKey: "test-api-key")
    TestAssertions.verifyContentType(request: request, expectedType: "application/json")
    
    MockRequestCapture.stopCapturing()
}
```

## Best Practices

### 1. Always Clean Up
```swift
// Always call cleanup to reset mock state
TestUtilities.cleanup()
```

### 2. Use Descriptive Test Names
```swift
@Test("Chat client creates message with files successfully")
@Test("Workflow execution handles timeout error correctly")
@Test("File upload validates MIME type parameter")
```

### 3. Test Both Success and Failure Cases
- Happy path with valid responses
- Error scenarios with HTTP errors
- Edge cases with malformed data

### 4. Verify Request Construction
- Check that correct headers are sent
- Validate request body encoding
- Ensure proper URL construction

### 5. Use Realistic Mock Data
- Use data structures that match real API responses
- Include all required fields
- Test with various data types and edge values

## Migration from Real Server Tests

Old pattern (❌):
```swift
let client = try ChatClient(apiKey: TestConfig.requiredAPIKey)
let response = try await client.createChatMessage(...)
```

New pattern (✅):
```swift
TestUtilities.setupStandardMocks()
let client = try TestUtilities.createMockChatClient()
let response = try await client.createChatMessage(...)
TestUtilities.cleanup()
```

## Troubleshooting

### Common Issues

1. **Test fails with "No mock registered"**
   - Solution: Call `TestUtilities.setupStandardMocks()` or register specific mock

2. **Concurrency warnings in Swift 6**
   - Mock infrastructure handles this with `@MainActor` and `nonisolated(unsafe)`

3. **Mock response doesn't match expected data**
   - Check `MockDataProvider` for the correct response structure
   - Verify the endpoint name in `registerMock()`

4. **Tests hang or timeout**
   - Ensure `TestUtilities.cleanup()` is called
   - Check that streaming mocks complete properly

### Debug Tips

1. **Print captured requests**:
   ```swift
   let requests = MockRequestCapture.getCapturedRequests()
   print("Captured requests: \(requests)")
   ```

2. **Verify mock registration**:
   ```swift
   MockURLProtocol.registerMock(endpoint: "test", response: response)
   // Add print to verify endpoint matching
   ```

3. **Check response data**:
   ```swift
   let jsonString = String(data: responseData, encoding: .utf8)
   print("Response JSON: \(jsonString)")
   ```

## Continuous Integration

The mock-based tests are designed to run reliably in CI environments:

- No external dependencies
- No environment variables required
- Fast execution (no network delays)
- Deterministic results
- Support for parallel execution

Configure your CI to run:
```bash
swift test --parallel
```

## Future Enhancements

Planned improvements to the test suite:

1. **More comprehensive streaming tests**
2. **Performance benchmarking against real API**
3. **Integration with official Dify API documentation**
4. **Automated test generation from OpenAPI specs**
5. **Visual test coverage reporting**