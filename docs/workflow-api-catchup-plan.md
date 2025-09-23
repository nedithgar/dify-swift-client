# Dify Swift Client — Workflow API Catch‑Up Plan

Last updated: 2025-09-23
Owner: Dify Swift Client maintainers
Status: Draft

## ✅ Quick repository audit (current vs plan)

This summarizes where the codebase stands today relative to this plan and the attached old/new Workflow API docs.

- Endpoints in WorkflowClient
  - Implemented: POST /workflows/run (blocking + streaming), POST /workflows/tasks/:task_id/stop, GET /workflows/run/:workflow_run_id, GET /workflows/logs, GET /info, GET /parameters, GET /site.
  - Missing per plan: POST /workflows/:workflow_id/run (both blocking and streaming variants).
  - Request body gaps: existing run methods don’t accept files or trace_id yet (plan will add them).
  - Naming: getWorkflowRunDetail(workflowId:) uses parameter name workflowId, but the path variable is workflow_run_id per latest docs; plan’s rename to getWorkflowRunDetail(workflowRunId:) is correct.

- Models
  - Streaming workflow events: WorkflowStartedEvent, WorkflowFinishedEvent, TextChunkEvent already expose workflow_run_id. NodeStartedEvent/NodeFinishedEvent currently do not; plan to add optional workflowRunId is correct and backward compatible.
  - Workflow run detail/log models align with the latest docs’ shapes.

- CompletionClient ergonomics
  - uploadFile MIME fallback currently defaults to image/png when extension is unknown; plan proposes application/octet-stream. Safe and reasonable.

- Tests
  - Present: coverage for /workflows/run (blocking + streaming), stop, run detail, logs, and app info/parameters/site.
  - Missing per plan: tests for POST /workflows/:workflow_id/run (blocking + streaming) and passing files + trace_id through body; also a test confirming the deprecated alias forwards to getWorkflowRunDetail(workflowRunId:).

- Docs in repo (new vs old templates)
  - New template documents POST /workflows/:workflow_id/run and clarifies GET /workflows/run/:workflow_run_id (vs old template’s workflow_id). Plan aligns with this.
  - Streaming examples include workflow_run_id consistently; plan’s exposure of this in node events is appropriate.

Conclusion: The plan matches repo gaps and the API docs. No scope changes needed—proceed with the listed additions and tests.

## 🎯 Goal
Bring the Swift client to full feature parity with the latest Workflow App API, adding:
- Execute a specific workflow version: `POST /workflows/:workflow_id/run`
- Optional `files` and `trace_id` on workflow run requests
- Clarify parameter naming (use `workflow_run_id` terminology consistently)
- Optional niceties for models and file upload ergonomics

## ✅ Scope
In scope:
- New client methods for executing a specific workflow version (blocking + streaming)
- Extend request bodies to accept `files` and `trace_id`
- Keep backward compatibility for existing APIs
- Tests, examples, and docs updates reflecting new features

Out of scope:
- Server-side behavior changes
- Advanced file type detection (keep simple improvements only)

---

## 🔁 API Changes Summary (Old vs New)

- Execute Workflow (existing):
  - `POST /workflows/run`
  - Now documents optional `files` and `trace_id`

- Execute Specific Workflow (new):
  - `POST /workflows/:workflow_id/run`
  - Same body as above; supports `files`, `trace_id`

- Get Workflow Run Detail (clarified):
  - `GET /workflows/run/:workflow_run_id`
  - Path variable explicitly `workflow_run_id` (not `workflow_id`)

- Streaming events: unchanged structurally; examples include `workflow_run_id` on more events. No breaking schema notes.

- File Upload, Parameters, Logs, Info, Site: compatible with current models; documentation expanded.

---

## 📦 Code Changes

### 1) WorkflowClient additions
File: `Sources/DifySwiftClient/WorkflowClient.swift`

Add new methods:
- Blocking: `runWorkflow(workflowId: String, inputs: [String: Any], user: String, files: [APIFile]? = nil, traceId: String? = nil) -> WorkflowResponse`
- Streaming: `runStreamingWorkflow(workflowId: String, inputs: [String: Any], user: String, files: [APIFile]? = nil, traceId: String? = nil) -> AsyncThrowingStream<StreamingWorkflowResponse, Error>`
  - Endpoint: `/workflows/{workflow_id}/run`

Extend existing methods to accept optional `files` and `traceId`:
- `runWorkflow(inputs:user: files: traceId:)`
- `runStreamingWorkflow(inputs:user: files: traceId:)`

Update request body struct:
- `WorkflowRequestBody { inputs, responseMode, user, files?, traceId? }`
  - Coding keys: `files`, `trace_id`
  - Continue encoding inputs via AnyCodable (as done today)

Clarify parameter naming:
- Rename `getWorkflowRunDetail(workflowId: String)` to `getWorkflowRunDetail(workflowRunId: String)`
- Keep a deprecated alias for source compatibility.

### 2) Models (optional niceties)
File: `Sources/DifySwiftClient/Models.swift`

- Add `workflowRunId: String?` to `NodeStartedEvent` and `NodeFinishedEvent` (CodingKey: `workflow_run_id`) to expose if present in streams. Backward compatible.

### 3) CompletionClient ergonomics (optional)
File: `Sources/DifySwiftClient/CompletionClient.swift`

- In `uploadFile(...)` default MIME detection: when extension unknown, fallback to `application/octet-stream` instead of an image default.

---

## 🧪 Test Plan

Add/Update tests under `Tests/DifySwiftClientTests/`:

1) New endpoint tests
- Blocking run specific workflow: `POST /workflows/{workflow_id}/run`
  - Happy path with `inputs` only
  - With `files` array
  - With `trace_id` in body
- Streaming run specific workflow
  - Validate parsing of SSE events including text chunks, node events, workflow finished
  - Include event lines where node events may include top-level `workflow_run_id` to validate new optional exposure

2) Existing endpoint tests updates
- `POST /workflows/run` with `files` and `trace_id` accepted and passed correctly

3) Run detail
- Ensure `getWorkflowRunDetail(workflowRunId:)` still decodes correctly; deprecation alias points to it
  - Confirm old signature triggers a deprecation warning but forwards to the new one

4) Model compatibility
- Streaming decode succeeds even if `workflow_run_id` is present on node events (now exposed in model)

5) Upload MIME fallback (optional)
- Unknown file extension → sets `application/octet-stream`
  - Implementation: change only the default branch in CompletionClient.uploadFile’s extension switch

---

## 📚 Docs & Examples

- README and Examples:
  - Add usage examples for:
    - Running a specific workflow version (blocking + streaming)
    - Passing `files` and `traceId`
- API docs references:
  - Ensure `docs/api/*` references match the updated methods and parameter names

---

## 🔒 Backward Compatibility

- Existing methods continue to work with previous signatures (new params default to `nil`)
- Introduce `@available(*, deprecated, message: ...)` alias for `getWorkflowRunDetail(workflowId:)` to guide migration to `workflowRunId:`
- Models add only optional fields; no breaking changes

---

## 🧰 Implementation Notes

- Request building:
  - `trace_id` precedence (docs): header `X-Trace-Id` > query `trace_id` > body `trace_id`
  - For now, support request-body `trace_id`; optionally allow caller to set header via an overload later
- Files payload:
  - Use existing `APIFile` model: `{ type, transfer_method, url?, upload_file_id? }`
- Decoding:
  - Keep existing generic decoding and SSE parsing; extend models minimally

---

## 🔍 Edge Cases

- Empty `inputs` (API requires at least one key)
- Long-running `blocking` requests may time out (Cloudflare ~100s)
- Invalid `workflow_id` (UUID) → server error mapping remains
- `files` with mismatched `transfer_method`/field combinations (validate in server)
- Streaming partial/malformed events → robust SSE parsing already in place

---

## ✅ Acceptance Criteria

- New methods for specific workflow execution exist and are covered by tests
- `files` and `trace_id` are serialised when provided (verified by tests)
- `getWorkflowRunDetail(workflowRunId:)` is the primary API; alias deprecated
- All unit tests pass locally and in CI
- Example snippets in README compile (swift-compile check where applicable)

---

## 🧭 Rollout Plan

1) Implement features in a feature branch
2) Update tests and docs
3) Run quality gates
4) Open PR with checklist below
5) Semver: bump minor version (new features, backward compatible)

PR Checklist:
- [ ] New public APIs documented
- [ ] Unit tests added/updated and passing
- [ ] README/Examples updated
- [ ] Changelog updated
- [ ] Deprecation notes included

---

## 🧪 Quality Gates

- Build: `swift build` (no errors)
- Lint/Format: Swift formatting (if configured)
- Unit Tests: `swift test` all green
- Smoke test: run example to hit `/workflows/:workflow_id/run` happy path (mocked)

---

## 🗂️ Tasks Breakdown

- [ ] Extend `WorkflowRequestBody` with `files`, `trace_id`
- [ ] Add `runWorkflow(workflowId:...)` (blocking + streaming)
- [ ] Add optional params to existing run methods (`files`, `traceId`)
- [ ] Rename + deprecate `getWorkflowRunDetail(workflowId:)`
- [ ] Models: add optional `workflowRunId` to node events
- [ ] Tests for new endpoint and parameters
- [ ] Optional MIME fallback in `CompletionClient.uploadFile`
- [ ] Update README/Examples/Docs

---

## 📌 Open Questions

- Do we want to expose `traceId` header support now (`X-Trace-Id`) or later?
- Should we validate `inputs` non-emptiness client-side?
- Expand MIME detection (e.g., using UTType) vs keep minimal fallback?

---

## 🔄 Migration Notes for Users

- You can continue using existing `runWorkflow(inputs:user:)` and streaming variants unchanged
- To target a specific workflow version, use the new `runWorkflow(workflowId:...)` methods
- To attach files, build `[APIFile]` and pass as the `files` parameter
- If you use `getWorkflowRunDetail`, please switch to `getWorkflowRunDetail(workflowRunId:)` (old alias remains for now)

---

## 📎 References

- `docs/api/new_template_workflow.en.mdx` — latest Workflow API documentation
- `docs/api/old_template_workflow.en.mdx` — previous documentation
