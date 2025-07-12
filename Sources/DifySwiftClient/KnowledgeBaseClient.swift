import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for managing knowledge bases (datasets, documents, and segments) in the Dify API.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class KnowledgeBaseClient: DifyClient, @unchecked Sendable {
    
    // MARK: - Datasets
    
    /// Retrieves a list of datasets.
    /// - Parameters:
    ///   - page: The page number for pagination.
    ///   - limit: The number of datasets to return per page.
    /// - Returns: A `DatasetsResponse` object containing the list of datasets.
    public func listDatasets(page: Int = 1, limit: Int = 20) async throws -> DatasetsResponse {
        let params = ["page": String(page), "limit": String(limit)]
        let data = try await sendRequest(method: .GET, endpoint: "/datasets", params: params)
        return try decode(data, to: DatasetsResponse.self)
    }
    
    /// Creates a new dataset.
    /// - Parameter name: The name for the new dataset.
    /// - Returns: A `DatasetResponse` object for the newly created dataset.
    public func createDataset(name: String) async throws -> DatasetResponse {
        let requestBody = ["name": name]
        let data = try await sendRequest(method: .POST, endpoint: "/datasets", body: requestBody)
        return try decode(data, to: DatasetResponse.self)
    }
    
    /// Deletes a dataset.
    /// - Parameter datasetId: The ID of the dataset to delete.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func deleteDataset(datasetId: String) async throws -> BaseResponse {
        let data = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)")
        return try decode(data, to: BaseResponse.self)
    }
    
    // MARK: - Documents
    
    /// Retrieves a list of documents within a specific dataset.
    /// - Parameters:
    ///   - datasetId: The ID of the dataset.
    ///   - page: The page number for pagination.
    ///   - limit: The number of documents to return per page.
    ///   - keyword: An optional keyword to filter documents by name.
    /// - Returns: A `DocumentsResponse` object containing the list of documents.
    public func listDocuments(datasetId: String, page: Int = 1, limit: Int = 20, keyword: String? = nil) async throws -> DocumentsResponse {
        var params = ["page": String(page), "limit": String(limit)]
        if let keyword { params["keyword"] = keyword }
        
        let data = try await sendRequest(method: .GET, endpoint: "/datasets/\(datasetId)/documents", params: params)
        return try decode(data, to: DocumentsResponse.self)
    }
    
    /// Creates a new document by uploading a file.
    /// - Parameters:
    ///   - datasetId: The ID of the dataset to add the document to.
    ///   - fileData: The raw data of the file.
    ///   - fileName: The name of the file.
    ///   - processRule: The processing rule for the document.
    /// - Returns: A `DocumentResponse` for the newly created document.
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
    
    /// Deletes a document.
    /// - Parameters:
    ///   - datasetId: The ID of the dataset containing the document.
    ///   - documentId: The ID of the document to delete.
    /// - Returns: A `BaseResponse` indicating the result of the operation.
    public func deleteDocument(datasetId: String, documentId: String) async throws -> BaseResponse {
        let data = try await sendRequest(method: .DELETE, endpoint: "/datasets/\(datasetId)/documents/\(documentId)")
        return try decode(data, to: BaseResponse.self)
    }
}