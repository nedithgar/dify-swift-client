# Knowledge API Coverage Checklist

Source: docs/api/openapi/openapi_knowledge.json

- [x] GET /datasets → listDatasets(keyword:tagIds:includeAll:page:limit:)
- [x] POST /datasets → createDataset(name:) / createDataset(_ request: KBCreateDatasetRequest)
- [x] GET /datasets/{dataset_id} → getDatasetDetail(datasetId:)
- [x] PATCH /datasets/{dataset_id} → updateDataset(datasetId:_ :)
- [x] DELETE /datasets/{dataset_id} → deleteDataset(datasetId:)

- [x] GET /datasets/{dataset_id}/documents → listDocuments(datasetId:page:limit:keyword:)
- [x] GET /datasets/{dataset_id}/documents/{document_id} → getDocumentDetail(datasetId:documentId:metadata:)
- [x] DELETE /datasets/{dataset_id}/documents/{document_id} → deleteDocument(datasetId:documentId:) / removeDocument(datasetId:documentId:)

- [x] POST /datasets/{dataset_id}/document/create-by-text → createDocumentFromText(datasetId:_ :)
- [x] POST /datasets/{dataset_id}/document/create-by-file → createDocumentFromFile(datasetId:fileName:fileData:data:)
- [x] POST /datasets/{dataset_id}/documents/{document_id}/update-by-text → updateDocumentByText(datasetId:documentId:_ :)
- [x] POST /datasets/{dataset_id}/documents/{document_id}/update-by-file → updateDocumentByFile(datasetId:documentId:fileName:fileData:data:)
- [x] GET /datasets/{dataset_id}/documents/{batch}/indexing-status → getDocumentIndexingStatus(datasetId:batch:)
- [x] PATCH /datasets/{dataset_id}/documents/status/{action} → batchUpdateDocumentStatus(datasetId:action:documentIds:)

- [x] GET /datasets/{dataset_id}/documents/{document_id}/segments → listSegments(datasetId:documentId:)
- [x] POST /datasets/{dataset_id}/documents/{document_id}/segments → createSegments(datasetId:documentId:_ :)
- [x] GET /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id} → getSegmentDetail(datasetId:documentId:segmentId:)
- [x] POST /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id} → updateSegment(datasetId:documentId:segmentId:_ :)
- [x] DELETE /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id} → deleteSegment(datasetId:documentId:segmentId:)

- [x] GET /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}/child_chunks → listChildChunks(datasetId:documentId:segmentId:keyword:page:limit:)
- [x] POST /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}/child_chunks → createChildChunk(datasetId:documentId:segmentId:_ :)
- [x] PATCH /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}/child_chunks/{child_chunk_id} → updateChildChunk(datasetId:documentId:segmentId:childChunkId:_ :)
- [x] DELETE /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}/child_chunks/{child_chunk_id} → deleteChildChunk(datasetId:documentId:segmentId:childChunkId:)

- [x] POST /datasets/{dataset_id}/retrieve → retrieve(datasetId:_ :)
- [x] GET /workspaces/current/models/model-types/text-embedding → getAvailableEmbeddingModels()

- [x] POST /datasets/tags → createKnowledgeTag(name:)
- [x] GET /datasets/tags → getKnowledgeTags()
- [x] PATCH /datasets/tags → updateKnowledgeTag(tagId:name:)
- [x] DELETE /datasets/tags → deleteKnowledgeTag(tagId:)
- [x] POST /datasets/tags/binding → bindTagsToDataset(datasetId:tagIds:)
- [x] POST /datasets/tags/unbinding → unbindTagFromDataset(datasetId:tagId:)
- [x] POST /datasets/{dataset_id}/tags → queryDatasetTags(datasetId:)

Notes
- All new request/response models are namespaced with `KB*` to avoid breaking existing types and tests.
- Existing `createDocument(datasetId:fileData:fileName:processRule:)` (legacy `/documents/upload`) remains for backward compatibility.
- Follow-ups: add unit tests and README examples for each new method.

