# Chat API Catch-up Plan (New Template vs Old)

This document outlines the gaps between the new Chat App API template and our current Swift client, plus the plan to close them: scope, tasks, tests, risks, and rollout.

Last reviewed: 2025-09-23
Branch: chore/upload-new-api-documentation-from-Dify

## Summary of API Changes

Key changes in the new docs (compared to old):

- Chat POST /chat-messages
  - New optional fields: workflow_id, trace_id
  - Files section generalized: document, image, audio, video, custom (with detailed extension lists)
  - Errors: additional workflow-related error codes
- New endpoint: GET /files/:file_id/preview (supports as_attachment)
- Conversation Variables
  - New: PUT /conversations/:conversation_id/variables/:variable_id to update a variable value
  - GET supports optional variable_name filter for narrowing results
- Messages GET response
  - message_files.url clarified as File Preview URL
- Parameters GET response
  - file_upload expanded to multiple categories (document, image, audio, video, custom)
- Streaming events
  - agent_thought still detailed; consumers often need its payload

## Current SDK State vs New Requirements

- Request models
  - APIFile, FileType, FileTransferMethod already support the 5 file categories
  - Chat request does not expose workflowId or traceId yet
- Endpoints
  - File preview is implemented in CompletionClient.previewFile(fileId:asAttachment:) only
  - Conversation variable update endpoint not implemented
  - Get conversation variables does not expose variable_name filter
- Streaming models
  - AgentThoughtStreamEvent is a stub (only event field)
- Parameters model
  - ApplicationParametersResponse supports expanded file_upload categories already
- Error handling
  - Generic; no change required for new error codes

## Decisions

- Add optional workflowId and traceId to ChatClient create methods (body field for trace_id; header support later via options)
- Implement PUT /conversations/:conversation_id/variables/:variable_id in ChatClient
- Flesh out AgentThoughtStreamEvent with documented fields
- Expose file preview helper in ChatClient (keep CompletionClient method; optionally refactor later into a Files helper)
- No changes needed to models for file categories or parameters
 - ConversationVariable value type should support non-string values (number/object) per docs; migrate value: String -> AnyCodable for flexibility
 - Add optional variableName filter to getConversationVariables API

## Deliverables

- Public API Surface (additions only)
  - ChatClient
    - createChatMessage(..., workflowId: String? = nil, traceId: String? = nil)
    - createStreamingChatMessage(..., workflowId: String? = nil, traceId: String? = nil)
    - updateConversationVariable(conversationId: String, variableId: String, value: AnyCodable, user: String)
    - getConversationVariables(conversationId:user:lastId:limit:variableName:) // add optional variableName
    - previewFile(fileId: String, asAttachment: Bool = false)  // convenience
  - Models
    - AgentThoughtStreamEvent with full fields (id, taskId, messageId, position, thought, observation, tool, toolInput, createdAt, messageFiles, conversationId)
    - ConversationVariable.value type changed to AnyCodable

- Documentation & Examples
  - README usage snippets for new parameters (workflowId, traceId)
  - Example for updating a conversation variable
  - Note on File Preview API with chat

- Tests
  - Unit tests for new request encoding (workflow_id, trace_id)
  - Unit tests for conversation variable update (success + type-mismatch error)
  - Streaming test to decode agent_thought payload
  - File preview test via ChatClient

## Task Breakdown

1) Chat request enhancements
- Add workflowId, traceId to ChatClient.ChatRequestBody (CodingKeys: workflow_id, trace_id)
- Add parameters to createChatMessage and createStreamingChatMessage and pass through
- Backward compatibility: defaults nil; no breaking change

2) Conversation variable update
- Add ChatClient.updateConversationVariable(conversationId:variableId:value:user:)
  - PUT /conversations/{conversation_id}/variables/{variable_id}
  - Body: { value, user }
  - Return: ConversationVariable (or the doc’s updated variable shape)

2.1) Conversation variables GET filtering
- Add optional variableName parameter to ChatClient.getConversationVariables and pass as query parameter `variable_name`

2.2) ConversationVariable model value type
- Change ConversationVariable.value from String to AnyCodable to support string/number/object values

3) Agent thought streaming model
- Replace AgentThoughtStreamEvent stub with full struct per docs:
  - event, id, task_id, message_id, position, thought, observation, tool, tool_input, created_at, message_files[file_id], conversation_id
- Ensure StreamingChatMessageResponse switch case still routes to .agentThought

4) File preview convenience
- Add ChatClient.previewFile(fileId:asAttachment:) delegating to base request
- Keep existing CompletionClient.previewFile for compatibility

5) Tests
- New tests in DifySwiftClientTests:
  - ChatClientTests
    - testCreateChatMessage_encodesWorkflowAndTraceIds
    - testCreateStreamingChatMessage_encodesWorkflowAndTraceIds
    - testUpdateConversationVariable_success
    - testUpdateConversationVariable_typeMismatchError
    - testGetConversationVariables_withVariableNameFilter
    - testAgentThoughtStreamEvent_decoding
    - testPreviewFile_viaChatClient
  - ModelsTests
    - testConversationVariable_AllValueTypesDecoding (string, number, object)

6) Documentation
- Update README and docs snippets (usage of workflowId/traceId, updating variables, file preview)

## Acceptance Criteria

- Creating chat messages accepts workflowId and traceId and encodes as workflow_id and trace_id
- Streaming and blocking chat requests still function with existing tests green
- Updating conversation variables works for string/number/object values and returns updated variable
- Conversation variables GET supports optional variable_name filter
- AgentThoughtStreamEvent decodes correctly for doc sample payload
- File preview via ChatClient returns mocked bytes; supports as_attachment
- No breaking changes to existing public APIs; semantic version bump is minor (e.g., 0.x minor or 1.x minor)

## Edge Cases & Error Modes

- Invalid workflow_id format: surfaced via existing DifyError(httpError)
- Draft workflow or not found: surfaced via DifyError
- Conversation/variable not found: 404 handled as DifyError
- Type mismatch: API returns 400 message; test we pass it through
- Trace ID precedence: future support for X-Trace-Id header; for now we accept body param only

## Testing Strategy

- Unit tests with MockURLProtocol (existing infra) asserting:
  - Encoded bodies include workflow_id/trace_id when provided
  - PUT variables endpoint path and body correctness
  - Agent thought SSE lines decode into AgentThoughtStreamEvent with expected fields
  - File preview requests hit /files/{id}/preview and optional as_attachment
- Smoke: minimal run in Examples/main.swift to try createStreamingChatMessage with traceId (optional)

## Rollout & Versioning

- Bump version: minor
- Changelog entries:
  - Added: workflowId and traceId in Chat APIs
  - Added: updateConversationVariable API
  - Added: ChatClient.previewFile convenience
  - Added: detailed AgentThoughtStreamEvent
- Release: after tests green

## Risks & Mitigations

- SDK users depending on AgentThoughtStreamEvent type: it was a stub; now concrete. Risk is low as it’s additive (existing decoding already required the event type to be ‘agent_thought’)
- Divergence between Completion vs Chat for parameters endpoint (user param): note to evaluate in a follow-up (non-blocking)

## Implementation Notes

- Consider introducing a lightweight ChatRequestOptions in future to avoid growing parameter lists; defer for now to minimize churn
- For trace ID, consider later supporting X-Trace-Id header; current plan encodes in body

## Requirements Coverage

- Add workflow_id to Chat: Done (planned change)
- Add trace_id to Chat: Done (planned change)
- Add file preview helper in Chat: Done (planned change)
- Implement PUT conversation variable update: Done (planned change)
- Expand agent_thought event model: Done (planned change)
- Maintain backward compatibility: Done (planned change)

## Next Steps

- Implement code changes and unit tests per above
- Open PR with checklist below

## PR Checklist

- [ ] Code changes implemented
- [ ] New unit tests added and passing
- [ ] README updated (usage + examples)
- [ ] CHANGELOG updated
- [ ] API docs cross-checked with examples (fields, endpoints)
- [ ] Version bumped
