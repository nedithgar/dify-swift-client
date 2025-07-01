import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for knowledge base management with Dify
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class KnowledgeBaseClient: DifyClient {
    
    // MARK: - Properties
    
    public let datasetId: String?
    
    // MARK: - Initialization
    
    /// Initialize a new knowledge base client
    /// - Parameters:
    ///   - apiKey: Your Dify API key
    ///   - baseURL: Base URL for the Dify API
    ///   - datasetId: Optional dataset ID for operations requiring a specific dataset
    ///   - session: URLSession to use for requests
    public init(apiKey: String, baseURL: String = "https://api.dify.ai/v1", datasetId: String? = nil, session: URLSession = .shared) throws {
        self.datasetId = datasetId
        try super.init(apiKey: apiKey, baseURL: baseURL, session: session)
    }
    
    /// Get the dataset ID, throwing an error if not set
    /// - Returns: Dataset ID
    /// - Throws: DifyError.missingDatasetId if dataset ID is not set
    private func getDatasetId() throws -> String {
        guard let datasetId = datasetId else {
            throw DifyError.missingDatasetId
        }
        return datasetId
    }
    
    // MARK: - Dataset Management
    
    /// Create a new dataset
    /// - Parameter name: Name of the dataset
    /// - Returns: Dataset response
    public func createDataset(name: String) async throws -> DatasetResponse {
        struct CreateDatasetRequest: Codable {
            let name: String
        }
        
        let request = CreateDatasetRequest(name: name)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/datasets",
            body: request
        )
        
        return try decode(data, to: DatasetResponse.self)
    }
    
    /// List datasets
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - pageSize: Number of items per page (default: 20)
    /// - Returns: Datasets response
    public func listDatasets(page: Int = 1, pageSize: Int = 20) async throws -> DatasetsResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(pageSize))
        ]
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/datasets",
            queryItems: queryItems
        )
        
        return try decode(data, to: DatasetsResponse.self)
    }
    
    /// Delete the current dataset
    /// - Returns: Empty response (204 status code expected)
    public func deleteDataset() async throws {
        let datasetId = try getDatasetId()
        _ = try await sendRequest(
            method: .DELETE,
            endpoint: "/datasets/\(datasetId)"
        )
    }
    
    // MARK: - Document Management
    
    /// Create a document by text
    /// - Parameters:
    ///   - name: Name of the document
    ///   - text: Text content of the document
    ///   - extraParams: Additional parameters for indexing and processing
    /// - Returns: Create document response
    public func createDocumentByText(
        name: String,
        text: String,
        extraParams: [String: Any]? = nil
    ) async throws -> CreateDocumentResponse {
        let datasetId = try getDatasetId()
        
        var requestData: [String: Any] = [
            "indexing_technique": "high_quality",
            "process_rule": ["mode": "automatic"],
            "name": name,
            "text": text
        ]
        
        if let extraParams = extraParams {
            for (key, value) in extraParams {
                requestData[key] = value
            }
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestData)
        let data = try await sendRawJSONRequest(
            method: .POST,
            endpoint: "/datasets/\(datasetId)/document/create_by_text",
            jsonData: jsonData
        )
        
        return try decode(data, to: CreateDocumentResponse.self)
    }
    
    /// Update a document by text
    /// - Parameters:
    ///   - documentId: ID of the document to update
    ///   - name: New name of the document
    ///   - text: New text content of the document
    ///   - extraParams: Additional parameters for indexing and processing
    /// - Returns: Create document response
    public func updateDocumentByText(
        documentId: String,
        name: String,
        text: String,
        extraParams: [String: Any]? = nil
    ) async throws -> CreateDocumentResponse {
        let datasetId = try getDatasetId()
        
        var requestData: [String: Any] = [
            "name": name,
            "text": text
        ]
        
        if let extraParams = extraParams {
            for (key, value) in extraParams {
                requestData[key] = value
            }
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestData)
        let data = try await sendRawJSONRequest(
            method: .POST,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)/update_by_text",
            jsonData: jsonData
        )
        
        return try decode(data, to: CreateDocumentResponse.self)
    }
    
    /// Create a document by file
    /// - Parameters:
    ///   - fileData: File data to upload
    ///   - filename: Name of the file
    ///   - mimeType: MIME type of the file
    ///   - originalDocumentId: Optional ID of document to replace
    ///   - extraParams: Additional parameters for indexing and processing
    /// - Returns: Create document response
    public func createDocumentByFile(
        fileData: Data,
        filename: String,
        mimeType: String,
        originalDocumentId: String? = nil,
        extraParams: [String: Any]? = nil
    ) async throws -> CreateDocumentResponse {
        let datasetId = try getDatasetId()
        
        var requestData: [String: Any] = [
            "process_rule": ["mode": "automatic"],
            "indexing_technique": "high_quality"
        ]
        
        if let extraParams = extraParams {
            for (key, value) in extraParams {
                requestData[key] = value
            }
        }
        
        if let originalDocumentId = originalDocumentId {
            requestData["original_document_id"] = originalDocumentId
        }
        
        let jsonString = String(data: try JSONSerialization.data(withJSONObject: requestData), encoding: .utf8) ?? "{}"
        
        let data = try await sendRequestWithFiles(
            method: .POST,
            endpoint: "/datasets/\(datasetId)/document/create_by_file",
            parameters: ["data": jsonString],
            files: [(key: "file", filename: filename, data: fileData, mimeType: mimeType)]
        )
        
        return try decode(data, to: CreateDocumentResponse.self)
    }
    
    /// Update a document by file
    /// - Parameters:
    ///   - documentId: ID of the document to update
    ///   - fileData: File data to upload
    ///   - filename: Name of the file
    ///   - mimeType: MIME type of the file
    ///   - extraParams: Additional parameters for indexing and processing
    /// - Returns: Create document response
    public func updateDocumentByFile(
        documentId: String,
        fileData: Data,
        filename: String,
        mimeType: String,
        extraParams: [String: Any]? = nil
    ) async throws -> CreateDocumentResponse {
        let datasetId = try getDatasetId()
        
        var requestData: [String: Any] = [:]
        
        if let extraParams = extraParams {
            for (key, value) in extraParams {
                requestData[key] = value
            }
        }
        
        let jsonString = String(data: try JSONSerialization.data(withJSONObject: requestData), encoding: .utf8) ?? "{}"
        
        let data = try await sendRequestWithFiles(
            method: .POST,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)/update_by_file",
            parameters: ["data": jsonString],
            files: [(key: "file", filename: filename, data: fileData, mimeType: mimeType)]
        )
        
        return try decode(data, to: CreateDocumentResponse.self)
    }
    
    /// List documents in the dataset
    /// - Parameters:
    ///   - page: Page number
    ///   - pageSize: Number of items per page
    ///   - keyword: Search keyword
    /// - Returns: Documents response
    public func listDocuments(
        page: Int? = nil,
        pageSize: Int? = nil,
        keyword: String? = nil
    ) async throws -> DocumentsResponse {
        let datasetId = try getDatasetId()
        
        var queryItems: [URLQueryItem] = []
        
        if let page = page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let pageSize = pageSize {
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))
        }
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/datasets/\(datasetId)/documents",
            queryItems: queryItems
        )
        
        return try decode(data, to: DocumentsResponse.self)
    }
    
    /// Delete a document
    /// - Parameter documentId: ID of the document to delete
    /// - Returns: Base response
    public func deleteDocument(documentId: String) async throws -> BaseResponse {
        let datasetId = try getDatasetId()
        let data = try await sendRequest(
            method: .DELETE,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)"
        )
        
        return try decode(data, to: BaseResponse.self)
    }
    
    /// Get batch indexing status
    /// - Parameter batchId: Batch ID to check status for
    /// - Returns: Batch indexing status response
    public func batchIndexingStatus(batchId: String) async throws -> BatchIndexingStatusResponse {
        let datasetId = try getDatasetId()
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/datasets/\(datasetId)/documents/\(batchId)/indexing-status"
        )
        
        return try decode(data, to: BatchIndexingStatusResponse.self)
    }
    
    // MARK: - Segment Management
    
    /// Add segments to a document
    /// - Parameters:
    ///   - documentId: ID of the document
    ///   - segments: Array of segment data
    /// - Returns: Add segments response
    public func addSegments(documentId: String, segments: [SegmentData]) async throws -> AddSegmentsResponse {
        let datasetId = try getDatasetId()
        
        struct AddSegmentsRequest: Codable {
            let segments: [SegmentData]
        }
        
        let request = AddSegmentsRequest(segments: segments)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments",
            body: request
        )
        
        return try decode(data, to: AddSegmentsResponse.self)
    }
    
    /// Query segments in a document
    /// - Parameters:
    ///   - documentId: ID of the document
    ///   - keyword: Search keyword
    ///   - status: Status filter
    /// - Returns: Segments response
    public func querySegments(
        documentId: String,
        keyword: String? = nil,
        status: String? = nil
    ) async throws -> SegmentsResponse {
        let datasetId = try getDatasetId()
        
        var queryItems: [URLQueryItem] = []
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments",
            queryItems: queryItems
        )
        
        return try decode(data, to: SegmentsResponse.self)
    }
    
    /// Update a document segment
    /// - Parameters:
    ///   - documentId: ID of the document
    ///   - segmentId: ID of the segment
    ///   - segmentData: New segment data
    /// - Returns: Update segment response
    public func updateDocumentSegment(
        documentId: String,
        segmentId: String,
        segmentData: SegmentData
    ) async throws -> UpdateSegmentResponse {
        let datasetId = try getDatasetId()
        
        struct UpdateSegmentRequest: Codable {
            let segment: SegmentData
        }
        
        let request = UpdateSegmentRequest(segment: segmentData)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)",
            body: request
        )
        
        return try decode(data, to: UpdateSegmentResponse.self)
    }
    
    /// Delete a document segment
    /// - Parameters:
    ///   - documentId: ID of the document
    ///   - segmentId: ID of the segment to delete
    /// - Returns: Base response
    public func deleteDocumentSegment(documentId: String, segmentId: String) async throws -> BaseResponse {
        let datasetId = try getDatasetId()
        let data = try await sendRequest(
            method: .DELETE,
            endpoint: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)"
        )
        
        return try decode(data, to: BaseResponse.self)
    }
    
    // MARK: - Private Helper Methods
    
    /// Send a raw JSON request (used for complex request bodies)
    /// - Parameters:
    ///   - method: HTTP method
    ///   - endpoint: API endpoint
    ///   - jsonData: Raw JSON data
    /// - Returns: Response data
    private func sendRawJSONRequest(
        method: HTTPMethod,
        endpoint: String,
        jsonData: Data
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw DifyError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        return data
    }
}