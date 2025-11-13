import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A high-level client for managing Knowledge Base resources (Datasets & their Documents) in the Dify API.
///
/// This client currently offers operations for:
/// - Listing, creating, updating and deleting datasets
/// - Fetching dataset details
/// - Listing, uploading, updating and deleting documents within a dataset
/// - Fetching document details and indexing status
/// - Managing document segments (chunks) and child chunks
/// - Retrieving records from a dataset (RAG)
/// - Managing dataset tags and listing available embedding models
///
/// API Endpoint Mapping:
/// - `GET /datasets` – ``listDatasets(keyword:tagIds:includeAll:page:limit:)``
/// - `POST /datasets` – ``createDataset(name:)`` / ``createDataset(_:)``
/// - `GET /datasets/{dataset_id}` – ``getDatasetDetail(datasetId:)``
/// - `PATCH /datasets/{dataset_id}` – ``updateDataset(datasetId:_:)``
/// - `DELETE /datasets/{dataset_id}` – ``deleteDataset(datasetId:)``
/// - `GET /datasets/{dataset_id}/documents` – ``listDocuments(datasetId:page:limit:keyword:)``
/// - `POST /datasets/{dataset_id}/document/create-by-file` – ``createDocumentFromFile(datasetId:fileName:fileData:data:)``
/// - `POST /datasets/{dataset_id}/document/create-by-text` – ``createDocumentFromText(datasetId:_:)``
/// - `GET /datasets/{dataset_id}/documents/{document_id}` – ``getDocumentDetail(datasetId:documentId:metadata:)``
/// - `POST /datasets/{dataset_id}/documents/{document_id}/update-by-text` – ``updateDocumentByText(datasetId:documentId:_:)``
/// - `POST /datasets/{dataset_id}/documents/{document_id}/update-by-file` – ``updateDocumentByFile(datasetId:documentId:fileName:fileData:data:)``
/// - `GET /datasets/{dataset_id}/documents/{batch}/indexing-status` – ``getDocumentIndexingStatus(datasetId:batch:)``
/// - `PATCH /datasets/{dataset_id}/documents/status/{action}` – ``batchUpdateDocumentStatus(datasetId:action:documentIds:)``
/// - `GET/POST/DELETE /datasets/{dataset_id}/documents/{document_id}/segments` – ``listSegments``, ``createSegments``, ``deleteSegment``
/// - `GET/POST /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}` – ``getSegmentDetail``, ``updateSegment``
/// - `GET/POST/PATCH/DELETE /datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}/child_chunks` – child chunk management
/// - `POST /datasets/{dataset_id}/retrieve` – ``retrieve(datasetId:_:)``
/// - `GET /workspaces/current/models/model-types/text-embedding` – ``getAvailableEmbeddingModels()``
/// - `GET/POST/PATCH/DELETE /datasets/tags` and related – tag management helpers
///
/// Error Handling:
/// Each async method throws on network transport issues, non-success HTTP status codes translated into `DifyError`,
/// and JSON decoding failures. Callers should handle these with `do/try/catch`.
///
/// Concurrency & Thread Safety:
/// The class is marked `@unchecked Sendable` and assumes the underlying `URLSession` is safe for concurrent access.
/// No internal mutable state is modified after initialization, so instances can be shared across tasks.
///
/// Example:
/// ```swift
/// let kbClient = KnowledgeBaseClient(apiKey: "<API_KEY>")
/// let datasets = try await kbClient.listDatasets()
/// let created = try await kbClient.createDataset(name: "Support Articles")
/// let document = try await kbClient.createDocument(
///     datasetId: created.data.id,
///     fileData: Data(pdfBytes),
///     fileName: "getting-started.pdf",
///     processRule: .default
/// )
/// _ = try await kbClient.deleteDocument(datasetId: created.data.id, documentId: document.data.id)
/// ```
///
/// - Note: Segment-level and advanced ingestion management operations are implemented as typed helpers below.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class KnowledgeBaseClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Datasets
    
    /// Retrieves a paginated list of datasets.
    ///
    /// - Parameters:
    ///   - page: Page number (1-based). Default is `1`.
    ///   - limit: Page size (items per page). Default is `20`.
    /// - Returns: A decoded `DatasetsResponse`.
    /// - Throws: `DifyError` for API errors or underlying networking/decoding errors.
    public func listDatasets(keyword: String? = nil, tagIds: [String]? = nil, includeAll: Bool? = nil, page: Int = 1, limit: Int = 20) async throws -> DatasetsResponse {
        var params: [String: String] = ["page": String(page), "limit": String(limit)]
        if let keyword, !keyword.isEmpty { params["keyword"] = keyword }
        if let tagIds, !tagIds.isEmpty { params["tag_ids"] = tagIds.joined(separator: ",") }
        if let includeAll { params["include_all"] = includeAll ? "true" : "false" }
        let data = try await sendRequest(method: .GET, endpoint: "/datasets", params: params)
        return try decode(data, to: DatasetsResponse.self)
    }
    
    /// Creates a new dataset.
    ///
    /// - Parameter name: The display name of the dataset.
    /// - Returns: A `DatasetResponse` containing the created dataset.
    /// - Throws: `DifyError` if creation fails.
    public func createDataset(name: String) async throws -> DatasetResponse {
        let requestBody = ["name": name]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets", body: requestBody)
        if data.isEmpty {
            // Some deployments may return 201/204 with no body for create.
            // Fallback: query by exact name and return the most recently created match.
            if DifyDebug.enabled { DifyDebug.log("Empty body for createDataset; falling back to list by name=\(name)") }
            let list = try await listDatasets(keyword: name, page: 1, limit: 50)
            let exactMatches = list.data.filter { $0.name == name }
            if let newest = exactMatches.max(by: { $0.createdAt < $1.createdAt }) {
                return newest
            }
            // If no exact match, return first item containing keyword as last resort
            if let first = list.data.first { return first }
            // Nothing found; surface a meaningful error
            throw DifyError.noData()
        }
        return try decode(data, to: DatasetResponse.self)
    }

    /// Creates a dataset with advanced options.
    /// Mirrors the OpenAPI CreateDatasetRequest.
    public func createDataset(_ request: KBCreateDatasetRequest) async throws -> KBDataset {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets", body: request)
        return try decode(data, to: KBDataset.self)
    }
    
    /// Permanently deletes a dataset.
    ///
    /// - Parameter datasetId: Unique identifier of the dataset.
    /// - Returns: A `BaseResponse` indicating success.
    /// - Throws: `DifyError` if the deletion fails.
    /// - Important: Deletion may also remove associated documents; confirm intent before calling.
    public func deleteDataset(datasetId: String) async throws -> BaseResponse {
        let data = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)")
        return try decode(data, to: BaseResponse.self)
    }

    /// Fetch dataset detail.
    public func getDatasetDetail(datasetId: String) async throws -> KBDatasetDetail {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)")
        return try decode(data, to: KBDatasetDetail.self)
    }

    /// Update dataset settings.
    public func updateDataset(datasetId: String, _ request: KBUpdateDatasetRequest) async throws -> KBDatasetDetail {
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/\(datasetId)", body: request)
        return try decode(data, to: KBDatasetDetail.self)
    }
    
    // MARK: - Documents
    
    /// Lists documents within the specified dataset.
    ///
    /// - Parameters:
    ///   - datasetId: Identifier of the dataset whose documents to list.
    ///   - page: Page number (1-based). Default `1`.
    ///   - limit: Items per page. Default `20`.
    ///   - keyword: Optional name filter (server-side search semantics).
    /// - Returns: A `DocumentsResponse` containing documents and pagination metadata.
    /// - Throws: `DifyError` if the request fails.
    public func listDocuments(datasetId: String, page: Int = 1, limit: Int = 20, keyword: String? = nil) async throws -> DocumentsResponse {
        var params = ["page": String(page), "limit": String(limit)]
        if let keyword { params["keyword"] = keyword }
        
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents", params: params)
        return try decode(data, to: DocumentsResponse.self)
    }
    
    /// Uploads and creates a new document in a dataset using multipart/form-data.
    ///
    /// - Parameters:
    ///   - datasetId: Dataset identifier receiving the document.
    ///   - fileData: Raw file bytes to ingest.
    ///   - fileName: Original filename; also used as the logical document name.
    ///   - processRule: Processing / ingestion rule serialized to JSON in the `process_rule` field.
    /// - Returns: A `DocumentResponse` representing the newly created document.
    /// - Throws: `DifyError` on upload or processing failure.
    /// - Note: MIME type is currently fixed as `application/octet-stream` – adjust if the API introduces behavior
    ///   dependent on specific content types.
    public func createDocument(datasetId: String, fileData: Data, fileName: String, processRule: ProcessRule) async throws -> DocumentResponse {
        let multipart = MultipartFormData()
        multipart.addTextField(named: "name", value: fileName)
        
        if let processRuleData = try? JSONEncoder.difyEncoder.encode(processRule),
           let processRuleString = String(data: processRuleData, encoding: .utf8) {
            multipart.addTextField(named: "process_rule", value: processRuleString)
        }
        
        multipart.addFileField(named: "file", fileName: fileName, data: fileData, mimeType: "application/octet-stream")
        
        let data = try await sendMultipartRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/upload", multipart: multipart)
        return try decode(data, to: DocumentResponse.self)
    }

    /// Create a document by uploading a file (OpenAPI path).
    public func createDocumentFromFile(datasetId: String, fileName: String, fileData: Data, data requestData: KBCreateDocumentByFileData) async throws -> DocumentResponse {
        let multipart = MultipartFormData()
        // The OpenAPI expects a JSON string in a `data` field
        if let json = try? JSONEncoder.difyEncoder.encode(requestData), let jsonStr = String(data: json, encoding: .utf8) {
            multipart.addTextField(named: "data", value: jsonStr)
        }
        multipart.addFileField(named: "file", fileName: fileName, data: fileData, mimeType: "application/octet-stream")
        let data = try await sendMultipartRequest(method: .POST, endpoint: "/datasets/\(datasetId)/document/create-by-file", multipart: multipart)
        let wrapper = try decode(data, to: KBDocumentCreationResponse.self)
        return wrapper.document
    }

    /// Create a document from raw text.
    public func createDocumentFromText(datasetId: String, _ request: KBCreateDocumentByTextRequest) async throws -> DocumentResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/document/create-by-text", body: request)
        let wrapper = try decode(data, to: KBDocumentCreationResponse.self)
        return wrapper.document
    }

    /// Get document detail.
    public func getDocumentDetail(datasetId: String, documentId: String, metadata: String = "all") async throws -> KBDocumentDetail {
        let params = ["metadata": metadata]
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)", params: params)
        return try decode(data, to: KBDocumentDetail.self)
    }

    /// Update a document by text payload.
    public func updateDocumentByText(datasetId: String, documentId: String, _ request: KBUpdateDocumentByTextRequest) async throws -> DocumentResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/update-by-text", body: request)
        let wrapper = try decode(data, to: KBDocumentCreationResponse.self)
        return wrapper.document
    }

    /// Update a document by re-uploading a file.
    public func updateDocumentByFile(datasetId: String, documentId: String, fileName: String, fileData: Data, data requestData: KBUpdateDocumentByFileData) async throws -> DocumentResponse {
        let multipart = MultipartFormData()
        if let json = try? JSONEncoder.difyEncoder.encode(requestData), let jsonStr = String(data: json, encoding: .utf8) {
            multipart.addTextField(named: "data", value: jsonStr)
        }
        multipart.addFileField(named: "file", fileName: fileName, data: fileData, mimeType: "application/octet-stream")
        let data = try await sendMultipartRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/update-by-file", multipart: multipart)
        let wrapper = try decode(data, to: KBDocumentCreationResponse.self)
        return wrapper.document
    }
    
    /// Deletes a single document from a dataset.
    ///
    /// - Parameters:
    ///   - datasetId: Parent dataset identifier.
    ///   - documentId: Identifier of the document to remove.
    /// - Returns: A `BaseResponse` indicating success.
    /// - Throws: `DifyError` if deletion fails.
    public func deleteDocument(datasetId: String, documentId: String) async throws -> BaseResponse {
        let data = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)")
        return try decode(data, to: BaseResponse.self)
    }

    /// Delete a document (204 variant as per OpenAPI). Returns when deletion succeeds.
    public func removeDocument(datasetId: String, documentId: String) async throws {
        // We intentionally ignore the (likely empty) response body for 204 semantics.
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)")
    }

    /// Get indexing/embedding status for a batch.
    public func getDocumentIndexingStatus(datasetId: String, batch: String) async throws -> [KBDocumentIndexingStatus] {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(batch)/indexing-status")
        let wrapper = try decode(data, to: KBIndexingStatusResponse.self)
        return wrapper.data
    }

    /// Batch update document status (enable/disable/archive/un_archive).
    public func batchUpdateDocumentStatus(datasetId: String, action: KBDocumentStatusAction, documentIds: [String]) async throws -> BaseResponse {
        let body: [String: AnyCodable] = ["document_ids": AnyCodable(documentIds)]
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/\(datasetId)/documents/status/\(action.rawValue)", body: body)
        return try decode(data, to: BaseResponse.self)
    }

    // MARK: - Segments (Chunks)

    /// List segments for a document.
    public func listSegments(datasetId: String, documentId: String) async throws -> KBSegmentListResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments")
        return try decode(data, to: KBSegmentListResponse.self)
    }

    /// Create segments for a document.
    public func createSegments(datasetId: String, documentId: String, _ request: KBCreateSegmentsRequest) async throws -> KBSegmentPaginatedResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments", body: request)
        return try decode(data, to: KBSegmentPaginatedResponse.self)
    }

    /// Get a specific segment detail.
    public func getSegmentDetail(datasetId: String, documentId: String, segmentId: String) async throws -> KBSegmentDetailResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)")
        return try decode(data, to: KBSegmentDetailResponse.self)
    }

    /// Update a specific segment.
    public func updateSegment(datasetId: String, documentId: String, segmentId: String, _ request: KBUpdateSegmentRequest) async throws -> KBSegmentDetailResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)", body: request)
        return try decode(data, to: KBSegmentDetailResponse.self)
    }

    /// Delete a specific segment.
    public func deleteSegment(datasetId: String, documentId: String, segmentId: String) async throws {
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)")
    }

    // MARK: - Child Chunks

    public func listChildChunks(datasetId: String, documentId: String, segmentId: String, keyword: String? = nil, page: Int = 1, limit: Int = 20) async throws -> KBChildChunkListResponse {
        var params: [String: String] = ["page": String(page), "limit": String(limit)]
        if let keyword, !keyword.isEmpty { params["keyword"] = keyword }
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks", params: params)
        return try decode(data, to: KBChildChunkListResponse.self)
    }

    public func createChildChunk(datasetId: String, documentId: String, segmentId: String, _ request: KBCreateChildChunkRequest) async throws -> KBChildChunkResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks", body: request)
        return try decode(data, to: KBChildChunkResponse.self)
    }

    public func updateChildChunk(datasetId: String, documentId: String, segmentId: String, childChunkId: String, _ request: KBUpdateChildChunkRequest) async throws -> KBChildChunkResponse {
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks/\(childChunkId)", body: request)
        return try decode(data, to: KBChildChunkResponse.self)
    }

    public func deleteChildChunk(datasetId: String, documentId: String, segmentId: String, childChunkId: String) async throws {
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks/\(childChunkId)")
    }

    // MARK: - Retrieve & Models

    /// Retrieve relevant segments for a query from a dataset.
    public func retrieve(datasetId: String, _ request: KBRetrieveRequest) async throws -> KBRetrieveResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/retrieve", body: request)
        return try decode(data, to: KBRetrieveResponse.self)
    }

    /// Get available embedding models grouped by provider.
    public func getAvailableEmbeddingModels() async throws -> [KBModelProvider] {
        let data = try await sendRequest(method: .GET, endpoint: "/workspaces/current/models/model-types/text-embedding")
        let wrapper = try decode(data, to: KBModelProvidersResponse.self)
        return wrapper.data
    }

    // MARK: - Tags

    public func createKnowledgeTag(name: String) async throws -> KBTag {
        let body = ["name": name]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/tags", body: body)
        return try decode(data, to: KBTag.self)
    }

    public func getKnowledgeTags() async throws -> [KBTag] {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/tags")
        return try decode(data, to: [KBTag].self)
    }

    public func updateKnowledgeTag(tagId: String, name: String) async throws -> KBTag {
        let body: [String: String] = ["tag_id": tagId, "name": name]
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/tags", body: body)
        return try decode(data, to: KBTag.self)
    }

    public func deleteKnowledgeTag(tagId: String) async throws {
        let body: [String: String] = ["tag_id": tagId]
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/tags", body: body)
    }

    public func bindTagsToDataset(datasetId: String, tagIds: [String]) async throws -> BaseResponse {
        let body: [String: AnyCodable] = ["target_id": AnyCodable(datasetId), "tag_ids": AnyCodable(tagIds)]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/tags/binding", body: body)
        return try decode(data, to: BaseResponse.self)
    }

    public func unbindTagFromDataset(datasetId: String, tagId: String) async throws -> BaseResponse {
        let body: [String: AnyCodable] = ["target_id": AnyCodable(datasetId), "tag_id": AnyCodable(tagId)]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/tags/unbinding", body: body)
        return try decode(data, to: BaseResponse.self)
    }

    public func queryDatasetTags(datasetId: String) async throws -> KBQueryDatasetTagsResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/tags")
        return try decode(data, to: KBQueryDatasetTagsResponse.self)
    }
}
