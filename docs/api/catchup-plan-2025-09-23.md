# Dify Swift Client API Catch-up Plan — Completion App API (2025-09-23)

## Summary
This plan aligns the Swift client with the latest Completion App API documentation. We compared the previously integrated “old” template against the “new” template and assessed impacts on the codebase. No breaking changes were identified; however, there are clear opportunities to expand support and add one new endpoint.

## Source docs compared
- Old: `docs/api/old_template.en.mdx`
- New: `docs/api/new_template.en.mdx`

## Changes at a glance
- Files parameter expanded for Completion:
  - Old: only images described.
  - New: supports file types: `document`, `image`, `audio`, `video`, `custom` with format lists; transfer methods remain `remote_url` and `local_file`; `url` and `upload_file_id` unchanged.
- New endpoint: `GET /files/:file_id/preview` to preview or download a previously uploaded file (supports `as_attachment=true`).
- Parameters endpoint expanded:
  - `file_upload` now documents per-category configs for `document`, `image`, `audio`, `video`, `custom` (each with `enabled`, `number_limits`, `transfer_methods`).
- Other endpoints (completion-messages, stop, feedbacks, text-to-audio, info, site) keep the same request/response shape in ways that affect our client.

## Current client capability check (mapping)
- File support in requests: OK
  - `FileType` enum already includes `document`, `image`, `audio`, `video`, `custom`.
  - `APIFile` matches `type`, `transfer_method`, `url`, `upload_file_id`.
- Upload endpoint: OK (but limited by API)
  - Our `uploadFile` method supports images only, matching docs that still state "currently only images are supported" for the upload endpoint.
- Parameters model: Partial
  - `ApplicationParametersResponse.fileUpload` exposes only `image` via `FileUploadConfig.image` and `ImageUploadConfig`.
  - New docs describe additional categories (`document`, `audio`, `video`, `custom`). We currently drop these on decode (safe), but don’t expose them.
- New `GET /files/:file_id/preview`: Missing
  - We don’t yet provide a method to preview/download uploaded files.

## Required updates (recommended)
- Non-breaking enhancements:
  1) Add a method to retrieve file previews
     - Endpoint: `GET /files/:file_id/preview`
     - Inputs: `fileId: String`, `asAttachment: Bool = false`
     - Output: `Data` (raw file bytes)
  2) Expand `ApplicationParametersResponse` file upload configs
     - Extend `FileUploadConfig` to surface `document`, `image`, `audio`, `video`, `custom` categories.
     - Use a single generic struct type (e.g., `UploadCategoryConfig`) matching `enabled`, `number_limits`, `transfer_methods`.

No immediate changes are required for Completion request/response or streaming parsing.

## Implementation details
- Add file preview support
  - Where: Prefer a small helper in `CompletionClient` for parity with upload; alternatively introduce a `FilesClient` later if more file endpoints appear.
  - Signature:
    - `public func previewFile(fileId: String, asAttachment: Bool = false) async throws -> Data`
  - Behavior:
    - Build `GET /files/{fileId}/preview` with query `as_attachment` when true.
    - Return raw `Data`.
- Expand parameters models
  - Replace `ImageUploadConfig` usage in `FileUploadConfig` with a generic `UploadCategoryConfig` and add optional properties for all five categories.
  - Maintain `CodingKeys` for `number_limits` and `transfer_methods`.
  - Keep existing property (`image`) to avoid breaking binary compatibility, but internally point to the new generic type name. Alternatively, introduce new properties and keep `ImageUploadConfig` as a typealias to `UploadCategoryConfig` to minimize diff.

### Data model sketches (concept)
- `struct UploadCategoryConfig { enabled: Bool; number_limits: Int; transfer_methods: [String] }`
- `struct FileUploadConfig { document?: UploadCategoryConfig; image?: UploadCategoryConfig; audio?: UploadCategoryConfig; video?: UploadCategoryConfig; custom?: UploadCategoryConfig }`

## Tests to add
- File preview
  - Mock `GET /files/{id}/preview` returning arbitrary data; assert returned `Data` matches.
  - Verify query parameter when `asAttachment = true`.
- Parameters decoding
  - Provide a sample JSON containing `file_upload` with all categories and ensure decode surfaces each category as expected.

## Backward compatibility & migration
- Backward compatible
  - Adding a new method doesn’t break API.
  - Extending models with optional properties is backward compatible.
  - Keeping `ImageUploadConfig` (possibly as a typealias to the generic) avoids breaking existing public types. If renaming the type, keep a typealias for source compatibility.

## Validation steps
- Unit tests: green.
- Manual smoke tests using a test API key:
  - Completion with files of different `type` values using `APIFile` (remote_url); verify request is accepted.
  - `GET /files/:file_id/preview` returns bytes; check headers when server includes them.
  - `/parameters` decode shows additional file categories when enabled by the app.

## Risks & mitigations
- Risk: The upload endpoint still documents "images only"; attempting to upload non-image files could fail.
  - Mitigation: Don’t change `uploadFile` behavior or MIME inference beyond images until the upstream explicitly supports more types.
- Risk: Server variations for `file_upload` categories
  - Mitigation: Keep properties optional; decoding remains tolerant.

## Timeline & ownership
- Est. effort: ~0.5–1 day
  - Add preview method: ~1 hour with tests.
  - Expand models + unit tests: ~1–2 hours.
  - Review + release notes: ~0.5 hour.
- Ownership: SDK maintainers.

## Appendix: API diffs (condensed)
- New: `GET /files/:file_id/preview` (+ optional `as_attachment=true`)
- Enhanced: `files[]` types on Completion: now includes `document|image|audio|video|custom` (fields unchanged).
- Enhanced: `/parameters` → `file_upload` contains per-category configs (`document`, `image`, `audio`, `video`, `custom`).

---

If you approve, I can implement the two recommended changes (file preview + expanded parameters models) and add tests in this branch.
