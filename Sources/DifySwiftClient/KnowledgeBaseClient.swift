import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A high-level client for managing Knowledge Base resources (Datasets & their Documents) in the Dify API.
///
/// This client currently offers operations for:
/// - Listing, creating, deleting datasets
/// - Listing, uploading, deleting documents within a dataset
///
/// API Endpoint Mapping:
/// - `GET /datasets` – ``listDatasets(page:limit:)``
/// - `POST /datasets` – ``createDataset(name:)``
/// - `DELETE /datasets/{datasetId}` – ``deleteDataset(datasetId:)``
/// - `GET /datasets/{datasetId}/documents` – ``listDocuments(datasetId:page:limit:keyword:)``
/// - `POST /datasets/{datasetId}/documents/upload` – ``createDocument(datasetId:fileData:fileName:processRule:)``
/// - `DELETE /datasets/{datasetId}/documents/{documentId}` – ``deleteDocument(datasetId:documentId:)``
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
/// - Note: Segment-level and advanced ingestion management operations are not yet implemented.
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
    public func listDatasets(page: Int = 1, limit: Int = 20) async throws -> DatasetsResponse {
        let params = ["page": String(page), "limit": String(limit)]
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
        return try decode(data, to: DatasetResponse.self)
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
        
        let request = try createURLRequest(method: .POST, endpoint: "/datasets/\(datasetId)/documents/upload", multipart: multipart)
        let (data, _) = try await session.data(for: request)
        return try decode(data, to: DocumentResponse.self)
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
}