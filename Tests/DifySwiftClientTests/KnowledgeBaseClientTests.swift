import Foundation
import Testing
@testable import DifySwiftClient

@Suite("KnowledgeBaseClient Tests", .serialized)
final class KnowledgeBaseClientTests: DifyTestCase {
    
    // MARK: - Dataset Tests
    
    @Test("List Datasets")
    func testListDatasets() async throws {
        // Setup mocks first
        super.setupMocks()
        
        // Register list datasets mock
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets",
            response: MockResponse.json(MockDataProvider.datasetList)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // List datasets
        let response = try await client.listDatasets(page: 1, limit: 20)
        
        // Verify response
        #expect(response.page == 1)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.hasMore == false)
        #expect(response.data.count == 1)
        
        // Verify dataset
        let dataset = response.data[0]
        #expect(dataset.id == "b5829712-b2fb-4e47-bc0b-5f6f29c08162")
        #expect(dataset.name == "Product Documentation")
        #expect(dataset.description == "Company product documentation and guides")
        #expect(dataset.documentCount == 42)
        #expect(dataset.wordCount == 125000)
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            method: "GET",
            urlPattern: "/datasets",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    @Test("List Datasets with Pagination")
    func testListDatasetsWithPagination() async throws {
        // Setup mocks first
        super.setupMocks()
        
        // Register list datasets mock
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets",
            response: MockResponse.json(MockDataProvider.datasetList)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // List datasets with custom pagination
        _ = try await client.listDatasets(page: 2, limit: 50)
        
        // Verify request parameters
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let listRequest = capturedRequests.first { $0.url?.absoluteString.contains("/datasets") ?? false }
        #expect(listRequest != nil)
        
        if let url = listRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            #expect(queryItems.contains { $0.name == "page" && $0.value == "2" })
            #expect(queryItems.contains { $0.name == "limit" && $0.value == "50" })
        }
    }
    
    @Test("Create Dataset")
    func testCreateDataset() async throws {
        // Setup mocks first
        super.setupMocks()
        
        // Register create dataset mock
        let mockDataset: [String: Any] = [
            "id": "new-dataset-123",
            "name": "New Dataset",
            "description": NSNull(),
            "permission": "private",
            "data_source_type": "upload_file",
            "indexing_technique": "economy",
            "app_count": 0,
            "document_count": 0,
            "word_count": 0,
            "created_by": "user-123",
            "created_at": 1695065710,
            "updated_at": 1695065710
        ]
        
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/datasets",
            response: MockResponse.json(mockDataset)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Create dataset
        let response = try await client.createDataset(name: "New Dataset")
        
        // Verify response
        #expect(response.id == "new-dataset-123")
        #expect(response.name == "New Dataset")
        #expect(response.permission == "private")
        #expect(response.dataSourceType == "upload_file")
        #expect(response.indexingTechnique == "economy")
        #expect(response.documentCount == 0)
        
        // Verify request body
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let createRequest = capturedRequests.first { $0.url?.absoluteString.contains("/datasets") ?? false }
        #expect(createRequest != nil)
        
        if let body = createRequest?.httpBody,
           let jsonData = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            #expect(jsonData["name"] as? String == "New Dataset")
        }
    }
    
    @Test("Delete Dataset")
    func testDeleteDataset() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "dataset-to-delete"
        
        // Register delete dataset mock
        MockURLProtocol.register(
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)",
            response: MockResponse.json(["result": "success"])
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Delete dataset
        let response = try await client.deleteDataset(datasetId: datasetId)
        
        // Verify response
        #expect(response.result == "success")
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    // MARK: - Document Tests
    
    @Test("List Documents")
    func testListDocuments() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "test-dataset-123"
        
        // Register list documents mock
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.json(MockDataProvider.documentList)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // List documents
        let response = try await client.listDocuments(datasetId: datasetId)
        
        // Verify response
        #expect(response.page == 1)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.hasMore == false)
        #expect(response.data.count == 1)
        
        // Verify document
        let document = response.data[0]
        #expect(document.id == "c8b7e36e-0dca-443e-b5f5-2e865e6cbeb5")
        #expect(document.name == "user_guide.pdf")
        #expect(document.position == 1)
        #expect(document.tokens == 1234)
        #expect(document.indexingStatus == "completed")
    }
    
    @Test("List Documents with Keyword")
    func testListDocumentsWithKeyword() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "test-dataset-123"
        
        // Register list documents mock
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.json(MockDataProvider.documentList)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // List documents with keyword
        _ = try await client.listDocuments(
            datasetId: datasetId,
            page: 2,
            limit: 30,
            keyword: "guide"
        )
        
        // Verify request parameters
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let listRequest = capturedRequests.first { $0.url?.absoluteString.contains("/documents") ?? false }
        #expect(listRequest != nil)
        
        if let url = listRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            #expect(queryItems.contains { $0.name == "page" && $0.value == "2" })
            #expect(queryItems.contains { $0.name == "limit" && $0.value == "30" })
            #expect(queryItems.contains { $0.name == "keyword" && $0.value == "guide" })
        }
    }
    
    @Test("Create Document")
    func testCreateDocument() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "test-dataset-123"
        
        // Register create document mock
        let mockDocument: [String: Any] = [
            "id": "new-doc-123",
            "position": 2,
            "name": "test_document.txt",
            "tokens": 500,
            "indexing_status": "indexing",
            "created_by": "user-123",
            "created_at": 1695065710
        ]
        
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/datasets/\(datasetId)/documents/upload",
            response: MockResponse.json(mockDocument)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Create document
        let fileData = "This is test document content".data(using: .utf8)!
        let processRule = ProcessRule(mode: "automatic", rules: ["chunk_size": "500"])
        
        let response = try await client.createDocument(
            datasetId: datasetId,
            fileData: fileData,
            fileName: "test_document.txt",
            processRule: processRule
        )
        
        // Verify response
        #expect(response.id == "new-doc-123")
        #expect(response.name == "test_document.txt")
        #expect(response.position == 2)
        #expect(response.tokens == 500)
        #expect(response.indexingStatus == "indexing")
        
        // Verify request was multipart
        let capturedRequests = MockURLProtocol.getCapturedRequests()
        let uploadRequest = capturedRequests.first { $0.url?.absoluteString.contains("/documents/upload") ?? false }
        #expect(uploadRequest != nil)
        #expect(uploadRequest?.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") == true)
    }
    
    @Test("Delete Document")
    func testDeleteDocument() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "test-dataset-123"
        let documentId = "doc-to-delete"
        
        // Register delete document mock
        MockURLProtocol.register(
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)/documents/\(documentId)",
            response: MockResponse.json(["result": "success"])
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Delete document
        let response = try await client.deleteDocument(datasetId: datasetId, documentId: documentId)
        
        // Verify response
        #expect(response.result == "success")
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)/documents/\(documentId)",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    // MARK: - Error Handling Tests
    
    @Test("List Datasets - Network Error")
    func testListDatasetsNetworkError() async throws {
        // Setup mocks first
        super.setupMocks()
        
        // Register network error mock
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets",
            response: MockResponse.error(
                statusCode: 500,
                code: "internal_server_error",
                message: "Internal server error"
            )
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Attempt to list datasets
        await assertThrowsError({
            _ = try await client.listDatasets()
        }, expectedError: DifyError(message: "HTTP error: Internal server error", code: nil, status: 500))
    }
    
    @Test("Create Dataset - Invalid Input")
    func testCreateDatasetInvalidInput() async throws {
        // Setup mocks first
        super.setupMocks()
        
        // Register validation error mock
        MockURLProtocol.register(
            method: "POST",
            urlPattern: "/datasets",
            response: MockResponse.error(
                statusCode: 400,
                code: "invalid_param",
                message: "Dataset name cannot be empty"
            )
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Attempt to create dataset with empty name
        await assertThrowsError({
            _ = try await client.createDataset(name: "")
        }, expectedError: DifyError(message: "HTTP error: Dataset name cannot be empty", code: nil, status: 400))
    }
    
    @Test("List Documents - Dataset Not Found")
    func testListDocumentsDatasetNotFound() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "non-existent-dataset"
        
        // Register not found error mock
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.error(
                statusCode: 404,
                code: "dataset_not_found",
                message: "Dataset not found"
            )
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // Attempt to list documents
        await assertThrowsError({
            _ = try await client.listDocuments(datasetId: datasetId)
        }, expectedError: DifyError(message: "HTTP error: Dataset not found", code: nil, status: 404))
    }
    
    @Test("List Documents - Empty Results")
    func testListDocumentsEmptyResults() async throws {
        // Setup mocks first
        super.setupMocks()
        
        let datasetId = "empty-dataset"
        
        // Register empty documents mock
        let emptyDocuments: [String: Any] = [
            "data": [],
            "has_more": false,
            "total": 0,
            "page": 1,
            "limit": 20
        ]
        
        MockURLProtocol.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.json(emptyDocuments)
        )
        
        let client = TestUtilities.createTestKnowledgeBaseClient()
        
        // List documents
        let response = try await client.listDocuments(datasetId: datasetId)
        
        // Verify empty response
        #expect(response.total == 0)
        #expect(response.hasMore == false)
        #expect(response.data.isEmpty)
    }
}