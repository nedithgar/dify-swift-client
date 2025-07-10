# TODO List

## ✅ Recently Completed (2025-01-10)

### Advanced Chat API Final Alignment (2025-01-10)
- [x] **Enhanced StreamingChatMessageResponse** - Added workflow events to chat streaming response
  - Added `workflow_started`, `node_started`, `node_finished`, `workflow_finished` cases
  - Integrated existing WorkflowStartedEvent, NodeStartedEvent, NodeFinishedEvent, WorkflowFinishedEvent models
  - Updated decoder switch statement to handle all workflow events in chat context
- [x] **Fixed MessageReplaceStreamEvent** - Added missing `conversationId` field to align with API specification
- [x] **Complete template_advanced_chat.en.mdx Alignment** - All chat API models now fully match specification

### API Specification Alignment
- [x] Updated Swift SDK to align with latest Dify Service API specification
- [x] Added `event` field to `CompletionMessageResponse` model for blocking mode responses
- [x] Enhanced file upload method with automatic MIME type detection for image formats (png, jpg, jpeg, webp, gif)
- [x] Fixed text-to-audio endpoint to return raw audio data instead of JSON
- [x] Updated mock infrastructure to support raw data responses with proper Content-Type headers
- [x] Fixed Swift 6 concurrency issues in `Utilities.swift` with proper `@Sendable` annotations
- [x] Corrected `JSONEncoder.dateEncodingStrategy` configuration

### Workflow API Updates (template_workflow.en.mdx alignment)
- [x] Updated `FileType` enum to include all supported types: document, image, audio, video, custom
- [x] Enhanced `TextChunkEvent` model to include `workflowRunId` and structured `TextChunkData`
- [x] Updated `NodeExecutionData` to include `nodeType`, `predecessorNodeId`, and `ExecutionMetadata`
- [x] Added `StreamingWorkflowResponse` support for TTS events (`tts_message`, `tts_message_end`)
- [x] Added new workflow response models: `WorkflowRunDetailResponse`, `WorkflowLogsResponse`, `ApplicationWebAppSettingsResponse`
- [x] Extended `WorkflowClient` with new API methods:
  - `getWorkflowRunDetail(workflowId:)` - Get workflow execution details
  - `getWorkflowLogs(...)` - Get paginated workflow logs with filtering
  - `getApplicationInfo()` - Get basic application information
  - `getApplicationParameters()` - Get application parameter configuration
  - `getApplicationWebAppSettings()` - Get WebApp settings
- [x] Updated mock data provider with comprehensive mock responses for all new endpoints
- [x] All new API endpoints properly aligned with Dify Service API specification from template

### Chat API Updates (template_chat.en.mdx alignment)
- [x] **Comprehensive ChatClient API Implementation** - Updated entire ChatClient to align with Dify Chat App API specification
- [x] **Enhanced Chat Message Models** - Added missing fields to `ChatMessageResponse` (event, taskId, id)
- [x] **Extended Streaming Events** - Added support for all Chat streaming events:
  - `message_file` - File upload events during chat
  - `tts_message` and `tts_message_end` - Text-to-speech audio streaming  
  - `message_replace` - Content moderation replacements
- [x] **New Chat API Endpoints** - Added comprehensive Chat API endpoint coverage:
  - `stopChatGeneration(taskId:user:)` - Stop generation in progress
  - `getConversationMessages(...)` - Get chat history with pagination
  - `getSuggestedQuestions(messageId:user:)` - Get next question suggestions
  - `sendMessageFeedback(...)` - Send message ratings and feedback
  - `getApplicationFeedbacks(...)` - Get application feedback history
  - `getConversationVariables(...)` - Extract conversation variables
  - `audioToText(audioFile:user:)` - Speech-to-text conversion
  - `textToAudio(...)` - Text-to-speech conversion
  - Application info endpoints: `getApplicationInfo()`, `getApplicationParameters()`, `getApplicationMeta()`, `getApplicationWebAppSettings()`
- [x] **Annotation Management API** - Complete annotation system support:
  - `getAnnotations(...)` - List annotations with pagination
  - `createAnnotation(question:answer:)` - Create new annotations
  - `updateAnnotation(...)` - Update existing annotations
  - `deleteAnnotation(annotationId:)` - Delete annotations
  - `configureAnnotationReply(...)` - Configure annotation reply settings
  - `getAnnotationReplyJobStatus(...)` - Monitor configuration job status
- [x] **Enhanced Request Parameters** - Added missing API parameters:
  - `autoGenerateName` parameter for chat message requests
  - `sortBy` parameter for conversations listing
  - `autoGenerate` parameter for conversation renaming
- [x] **Improved File Upload Support** - Added `sendMultipartRequest` method to base client for audio file uploads
- [x] **Comprehensive Mock Data** - Updated MockDataProvider with responses for all new Chat API endpoints
- [x] **Type Safety Improvements** - Replaced `[String: Any]` request bodies with proper Codable structs

## 🚧 Current Priority Items

### Test Infrastructure Improvements (HIGH PRIORITY)
- [x] **Core Infrastructure Fixed** - Fixed MockDataProvider duplicate declarations and TestUtilities.swift  
- [x] **AdvancedChatClientTests.swift** - Fixed method name mismatches:
  - Fixed `getSuggestedMessages` → `getSuggestedQuestions`
  - Fixed `stopMessage` → `stopChatGeneration`
  - Fixed parameter order in `getConversationMessages`
  - Fixed `audioToText` parameter names
  - Fixed conversation rename response expectations
  - Removed invalid `responseMode` and `pinned` parameters
- [ ] **Remaining Test Fixes** - Additional test files still need updates:
  - [ ] Fix `AdvancedBaseDifyClientTests.swift` - non-existent methods (configureAnnotationReplySettings, getAnnotationReplyJobStatus, uploadFile, getApplicationInfo)
  - [ ] Fix `AdvancedCompletionClientTests.swift` - responseMode parameter issues  
  - [ ] Fix `AdvancedWorkflowClientTests.swift` - method name mismatches (run, runStreaming, stop)
  - [ ] Fix `AdvancedKnowledgeBaseClientTests.swift` - datasetId parameter
  - [ ] Fix `SimpleMockTests.swift` and `CleanDifyClientTests.swift` - DifyError constructor issues
- [ ] Focus on completion client tests first, then expand to other clients

### Documentation Updates (MEDIUM PRIORITY)
- [ ] Update `DOCUMENTATION.md` to reflect latest API specification changes
- [ ] Add examples for new file upload MIME type detection  
- [ ] Document text-to-audio raw data response handling
- [ ] Document new workflow API endpoints and their usage
- [ ] Add examples for workflow logs filtering and pagination
- [ ] Document TTS streaming events in workflow responses

## 🔄 Ongoing Maintenance

### Code Quality (LOW PRIORITY)
- [ ] Remove any remaining Swift 6 concurrency warnings
- [ ] Optimize test performance with better mock data management
- [ ] Review and standardize error handling patterns across all clients

### Future Enhancements
- [ ] Consider adding support for additional file types beyond images
- [ ] Implement request retry logic for network failures
- [ ] Add comprehensive logging and debugging capabilities

## 📋 Implementation Guidelines

When working on any of these items:
1. **Always** update this TODO.md file when starting and completing work
2. **Follow** the client architecture patterns established in `DifyClient` base class
3. **Add** comprehensive test coverage using the mock infrastructure
4. **Update** relevant documentation in `DOCUMENTATION.md`
5. **Ensure** Swift 6 compatibility with proper concurrency annotations

## 🎯 Next Steps

The immediate focus should be on:
1. Fixing test infrastructure to match current implementation
2. Running comprehensive test suite to ensure all functionality works
3. Updating documentation to reflect recent API changes

---

**Last Updated**: 2025-01-10
**Current Status**: **Advanced Chat API alignment with template_advanced_chat.en.mdx completed** - All chat streaming events including workflow events now supported, comprehensive Chat API implementation finished, test infrastructure needs updates