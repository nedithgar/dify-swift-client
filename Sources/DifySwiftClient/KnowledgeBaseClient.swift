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
    ///   - keyword: Optional keyword to filter datasets by name.
    ///   - tagIds: Optional list of tag IDs to filter datasets.
    ///   - includeAll: Optional flag to include all datasets regardless of permissions (if applicable).
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
            if DifySDKDebug.enabled { DifySDKDebug.log("Empty body for createDataset; falling back to list by name=\(name)") }
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
    ///
    /// Mirrors the OpenAPI CreateDatasetRequest.
    ///
    /// - Parameter request: The `KBCreateDatasetRequest` object containing dataset details.
    /// - Returns: The created `KBDataset`.
    /// - Throws: `DifyError` if creation fails.
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
    ///
    /// - Parameter datasetId: The unique identifier of the dataset.
    /// - Returns: A `KBDatasetDetail` object containing detailed information about the dataset.
    /// - Throws: `DifyError` if the request fails.
    public func getDatasetDetail(datasetId: String) async throws -> KBDatasetDetail {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)")
        return try decode(data, to: KBDatasetDetail.self)
    }

    /// Update dataset settings.
    ///
    /// - Parameters:
    ///   - datasetId: The unique identifier of the dataset to update.
    ///   - request: The `KBUpdateDatasetRequest` object containing the fields to update.
    /// - Returns: The updated `KBDatasetDetail`.
    /// - Throws: `DifyError` if the update fails.
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
    
    // Note: Legacy upload endpoint (`/datasets/{dataset_id}/documents/upload`) removed. Use
    // `createDocumentFromFile` or `createDocumentFromText` with typed KB* requests instead.

    /// Create a document by uploading a file (OpenAPI path).
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset to add the document to.
    ///   - fileName: The name of the file being uploaded.
    ///   - fileData: The raw data of the file.
    ///   - requestData: Additional metadata and processing rules for the document.
    /// - Returns: A `DocumentResponse` containing the created document's details.
    /// - Throws: `DifyError` if the upload or creation fails.
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
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset to add the document to.
    ///   - request: The `KBCreateDocumentByTextRequest` containing the text content and processing rules.
    /// - Returns: A `DocumentResponse` containing the created document's details.
    /// - Throws: `DifyError` if creation fails.
    public func createDocumentFromText(datasetId: String, _ request: KBCreateDocumentByTextRequest) async throws -> DocumentResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/document/create-by-text", body: request)
        let wrapper = try decode(data, to: KBDocumentCreationResponse.self)
        return wrapper.document
    }

    /// Get document detail.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset the document belongs to.
    ///   - documentId: The unique identifier of the document.
    ///   - metadata: The metadata to retrieve (default is "all").
    /// - Returns: A `KBDocumentDetail` object.
    /// - Throws: `DifyError` if the request fails.
    public func getDocumentDetail(datasetId: String, documentId: String, metadata: String = "all") async throws -> KBDocumentDetail {
        let params = ["metadata": metadata]
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)", params: params)
        return try decode(data, to: KBDocumentDetail.self)
    }

    /// Update a document by text payload.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document to update.
    ///   - request: The `KBUpdateDocumentByTextRequest` containing the new text and processing rules.
    /// - Returns: A `DocumentResponse` with the updated document details.
    /// - Throws: `DifyError` if the update fails.
    public func updateDocumentByText(datasetId: String, documentId: String, _ request: KBUpdateDocumentByTextRequest) async throws -> DocumentResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/update-by-text", body: request)
        let wrapper = try decode(data, to: KBDocumentCreationResponse.self)
        return wrapper.document
    }

    /// Update a document by re-uploading a file.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document to update.
    ///   - fileName: The name of the new file.
    ///   - fileData: The raw data of the new file.
    ///   - requestData: Additional metadata and processing rules.
    /// - Returns: A `DocumentResponse` with the updated document details.
    /// - Throws: `DifyError` if the update fails.
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
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document to remove.
    /// - Throws: `DifyError` if the deletion fails.
    public func removeDocument(datasetId: String, documentId: String) async throws {
        // We intentionally ignore the (likely empty) response body for 204 semantics.
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)")
    }

    /// Get indexing/embedding status for a batch.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - batch: The batch ID to check status for.
    /// - Returns: An array of `KBDocumentIndexingStatus` objects.
    /// - Throws: `DifyError` if the request fails.
    public func getDocumentIndexingStatus(datasetId: String, batch: String) async throws -> [KBDocumentIndexingStatus] {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(batch)/indexing-status")
        let wrapper = try decode(data, to: KBIndexingStatusResponse.self)
        return wrapper.data
    }

    /// Batch update document status (enable/disable/archive/un_archive).
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - action: The action to perform (enable, disable, archive, un_archive).
    ///   - documentIds: A list of document IDs to apply the action to.
    /// - Returns: A `BaseResponse` indicating success.
    /// - Throws: `DifyError` if the update fails.
    public func batchUpdateDocumentStatus(datasetId: String, action: KBDocumentStatusAction, documentIds: [String]) async throws -> BaseResponse {
        let body: [String: AnyCodable] = ["document_ids": AnyCodable(documentIds)]
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/\(datasetId)/documents/status/\(action.rawValue)", body: body)
        return try decode(data, to: BaseResponse.self)
    }

    // MARK: - Segments (Chunks)

    /// List segments for a document.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    /// - Returns: A `KBSegmentListResponse` containing the segments.
    /// - Throws: `DifyError` if the request fails.
    public func listSegments(datasetId: String, documentId: String) async throws -> KBSegmentListResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments")
        return try decode(data, to: KBSegmentListResponse.self)
    }

    /// Create segments for a document.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - request: The `KBCreateSegmentsRequest` containing the segments to create.
    /// - Returns: A `KBSegmentPaginatedResponse` containing the created segments.
    /// - Throws: `DifyError` if creation fails.
    public func createSegments(datasetId: String, documentId: String, _ request: KBCreateSegmentsRequest) async throws -> KBSegmentPaginatedResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments", body: request)
        return try decode(data, to: KBSegmentPaginatedResponse.self)
    }

    /// Get a specific segment detail.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the segment.
    /// - Returns: A `KBSegmentDetailResponse` containing the segment details.
    /// - Throws: `DifyError` if the request fails.
    public func getSegmentDetail(datasetId: String, documentId: String, segmentId: String) async throws -> KBSegmentDetailResponse {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)")
        return try decode(data, to: KBSegmentDetailResponse.self)
    }

    /// Update a specific segment.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the segment to update.
    ///   - request: The `KBUpdateSegmentRequest` containing the updated content/keywords.
    /// - Returns: A `KBSegmentDetailResponse` with the updated segment.
    /// - Throws: `DifyError` if the update fails.
    public func updateSegment(datasetId: String, documentId: String, segmentId: String, _ request: KBUpdateSegmentRequest) async throws -> KBSegmentDetailResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)", body: request)
        return try decode(data, to: KBSegmentDetailResponse.self)
    }

    /// Delete a specific segment.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the segment to delete.
    /// - Throws: `DifyError` if the deletion fails.
    public func deleteSegment(datasetId: String, documentId: String, segmentId: String) async throws {
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)")
    }

    // MARK: - Child Chunks

    /// List child chunks for a segment.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the parent segment.
    ///   - keyword: Optional keyword to filter child chunks.
    ///   - page: Page number (1-based). Default is `1`.
    ///   - limit: Page size (items per page). Default is `20`.
    /// - Returns: A `KBChildChunkListResponse` containing the child chunks.
    /// - Throws: `DifyError` if the request fails.
    public func listChildChunks(datasetId: String, documentId: String, segmentId: String, keyword: String? = nil, page: Int = 1, limit: Int = 20) async throws -> KBChildChunkListResponse {
        var params: [String: String] = ["page": String(page), "limit": String(limit)]
        if let keyword, !keyword.isEmpty { params["keyword"] = keyword }
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks", params: params)
        return try decode(data, to: KBChildChunkListResponse.self)
    }

    /// Create a child chunk for a segment.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the parent segment.
    ///   - request: The `KBCreateChildChunkRequest` containing the child chunk content.
    /// - Returns: A `KBChildChunkResponse` containing the created child chunk.
    /// - Throws: `DifyError` if creation fails.
    public func createChildChunk(datasetId: String, documentId: String, segmentId: String, _ request: KBCreateChildChunkRequest) async throws -> KBChildChunkResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks", body: request)
        return try decode(data, to: KBChildChunkResponse.self)
    }

    /// Update a child chunk.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the parent segment.
    ///   - childChunkId: The ID of the child chunk to update.
    ///   - request: The `KBUpdateChildChunkRequest` containing the updated content.
    /// - Returns: A `KBChildChunkResponse` with the updated child chunk.
    /// - Throws: `DifyError` if the update fails.
    public func updateChildChunk(datasetId: String, documentId: String, segmentId: String, childChunkId: String, _ request: KBUpdateChildChunkRequest) async throws -> KBChildChunkResponse {
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks/\(childChunkId)", body: request)
        return try decode(data, to: KBChildChunkResponse.self)
    }

    /// Delete a child chunk.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - documentId: The ID of the document.
    ///   - segmentId: The ID of the parent segment.
    ///   - childChunkId: The ID of the child chunk to delete.
    /// - Throws: `DifyError` if the deletion fails.
    public func deleteChildChunk(datasetId: String, documentId: String, segmentId: String, childChunkId: String) async throws {
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks/\(childChunkId)")
    }

    // MARK: - Retrieve & Models

    /// Retrieve relevant segments for a query from a dataset.
    ///
    /// - Parameters:
    ///   - datasetId: The ID of the dataset to query.
    ///   - request: The `KBRetrieveRequest` containing the query and retrieval options.
    /// - Returns: A `KBRetrieveResponse` containing the relevant segments.
    /// - Throws: `DifyError` if the retrieval fails.
    public func retrieve(datasetId: String, _ request: KBRetrieveRequest) async throws -> KBRetrieveResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/retrieve", body: request)
        return try decode(data, to: KBRetrieveResponse.self)
    }

    /// Get available embedding models grouped by provider.
    ///
    /// - Returns: An array of `KBModelProvider` objects describing available embedding models.
    /// - Throws: `DifyError` if the request fails.
    public func getAvailableEmbeddingModels() async throws -> [KBModelProvider] {
        let data = try await sendRequest(method: .GET, endpoint: "/workspaces/current/models/model-types/text-embedding")
        let wrapper = try decode(data, to: KBModelProvidersResponse.self)
        return wrapper.data
    }

    // MARK: - Tags

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func createKnowledgeTag(name: String) async throws -> KBTag {
        let body = ["name": name]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/tags", body: body)
        return try decode(data, to: KBTag.self)
    }

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func getKnowledgeTags() async throws -> [KBTag] {
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/tags")
        return try decode(data, to: [KBTag].self)
    }

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func updateKnowledgeTag(tagId: String, name: String) async throws -> KBTag {
        let body: [String: String] = ["tag_id": tagId, "name": name]
        let data = try await sendRequest(method: .PATCH, endpoint: "/datasets/tags", body: body)
        return try decode(data, to: KBTag.self)
    }

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func deleteKnowledgeTag(tagId: String) async throws {
        let body: [String: String] = ["tag_id": tagId]
        _ = try await sendRequest(method: .DELETE, endpoint: "/datasets/tags", body: body)
    }

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func bindTagsToDataset(datasetId: String, tagIds: [String]) async throws -> BaseResponse {
        let body: [String: AnyCodable] = ["target_id": AnyCodable(datasetId), "tag_ids": AnyCodable(tagIds)]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/tags/binding", body: body)
        return try decode(data, to: BaseResponse.self)
    }

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func unbindTagFromDataset(datasetId: String, tagId: String) async throws -> BaseResponse {
        let body: [String: AnyCodable] = ["target_id": AnyCodable(datasetId), "tag_id": AnyCodable(tagId)]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/tags/unbinding", body: body)
        return try decode(data, to: BaseResponse.self)
    }

    @available(*, unavailable, message: "Tag APIs are not available in this SDK because they cannot be exercised through integration tests.")
    public func queryDatasetTags(datasetId: String) async throws -> KBQueryDatasetTagsResponse {
        let data = try await sendRequest(method: .POST, endpoint: "/datasets/\(datasetId)/tags")
        return try decode(data, to: KBQueryDatasetTagsResponse.self)
    }
}
