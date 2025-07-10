# TODO List

## ✅ Recently Completed (2025-01-10)

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

## 🚧 Current Priority Items

### Test Infrastructure Improvements (HIGH PRIORITY)
- [ ] Fix outdated test methods that reference non-existent API methods
  - [ ] Review and fix `AdvancedBaseDifyClientTests.swift` test methods (messageFeedback, sendEnhancedMessageFeedback)
  - [ ] Review and fix `AdvancedChatClientTests.swift` test methods (createChatMessage signature, stopMessage, getSuggestedMessages, etc.)
  - [ ] Review and fix `AdvancedCompletionClientTests.swift` test methods (responseMode parameter issues)
  - [ ] Review and fix `AdvancedKnowledgeBaseClientTests.swift` test methods (datasetId parameter)
  - [ ] Fix `TestUtilities.swift` - StreamingResponse type not found, KnowledgeBaseClient constructor
- [ ] Align test expectations with actual API implementation
- [ ] Add tests for new workflow endpoints (getWorkflowRunDetail, getWorkflowLogs, getApplicationInfo, etc.)
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
**Current Status**: Workflow API alignment with template_workflow.en.mdx completed, test infrastructure needs updates