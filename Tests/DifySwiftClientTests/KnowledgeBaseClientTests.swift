import Foundation
import Testing
@testable import DifySwiftClient

@Suite("KnowledgeBaseClient Tests")
final class KnowledgeBaseClientTests: DifyTestCase, @unchecked Sendable {
    
    // MARK: - Dataset Tests
    
    @Test("List Datasets")
    func testListDatasets() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        // Register list datasets mock
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets",
            response: MockResponse.json(MockDataProvider.datasetList)
        )
        
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
            in: mockSession,
            method: "GET",
            urlPattern: "/datasets",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    @Test("List Datasets with Pagination")
    func testListDatasetsWithPagination() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        // Register list datasets mock
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets",
            response: MockResponse.json(MockDataProvider.datasetList)
        )
        
        // List datasets with custom pagination
        _ = try await client.listDatasets(page: 2, limit: 50)
        
        // Verify request parameters
        let capturedRequests = mockSession.getCapturedRequests()
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
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
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
        
        mockSession.register(
            method: "POST",
            urlPattern: "/datasets",
            response: MockResponse.json(mockDataset)
        )
        
        // Create dataset
        let response = try await client.createDataset(name: "New Dataset")
        
        // Verify response
        #expect(response.id == "new-dataset-123")
        #expect(response.name == "New Dataset")
        #expect(response.permission == "private")
        #expect(response.dataSourceType == "upload_file")
        #expect(response.indexingTechnique == .economy)
        #expect(response.documentCount == 0)
        
        // Verify request body
        let capturedRequests = mockSession.getCapturedRequests()
        let createRequest = capturedRequests.first { $0.url?.absoluteString.contains("/datasets") ?? false }
        #expect(createRequest != nil)
        
        if let body = createRequest?.httpBody,
           let jsonData = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            #expect(jsonData["name"] as? String == "New Dataset")
        }
    }
    
    @Test("Delete Dataset")
    func testDeleteDataset() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        let datasetId = "dataset-to-delete"
        
        // Register delete dataset mock
        mockSession.register(
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)",
            response: MockResponse.json(["result": "success"])
        )
        
        // Delete dataset
        let response = try await client.deleteDataset(datasetId: datasetId)
        
        // Verify response
        #expect(response.result == "success")
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    // MARK: - Document Tests
    
    @Test("List Documents")
    func testListDocuments() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        let datasetId = "test-dataset-123"
        
        // Register list documents mock
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.json(MockDataProvider.documentList)
        )
        
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
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        let datasetId = "test-dataset-123"
        
        // Register list documents mock
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.json(MockDataProvider.documentList)
        )
        
        // List documents with keyword
        _ = try await client.listDocuments(
            datasetId: datasetId,
            page: 2,
            limit: 30,
            keyword: "guide"
        )
        
        // Verify request parameters
        let capturedRequests = mockSession.getCapturedRequests()
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
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
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
        
        mockSession.register(
            method: "POST",
            urlPattern: "/datasets/\(datasetId)/documents/upload",
            response: MockResponse.json(mockDocument)
        )
        
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
        let capturedRequests = mockSession.getCapturedRequests()
        let uploadRequest = capturedRequests.first { $0.url?.absoluteString.contains("/documents/upload") ?? false }
        #expect(uploadRequest != nil)
        #expect(uploadRequest?.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") == true)
    }
    
    @Test("Delete Document")
    func testDeleteDocument() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        let datasetId = "test-dataset-123"
        let documentId = "doc-to-delete"
        
        // Register delete document mock
        mockSession.register(
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)/documents/\(documentId)",
            response: MockResponse.json(["result": "success"])
        )
        
        // Delete document
        let response = try await client.deleteDocument(datasetId: datasetId, documentId: documentId)
        
        // Verify response
        #expect(response.result == "success")
        
        // Verify request
        TestUtilities.assertRequestCaptured(
            in: mockSession,
            method: "DELETE",
            urlPattern: "/datasets/\(datasetId)/documents/\(documentId)",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
    
    // MARK: - Error Handling Tests
    
    @Test("List Datasets - Network Error")
    func testListDatasetsNetworkError() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        // Register network error mock
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets",
            response: MockResponse.error(
                statusCode: 500,
                code: "internal_server_error",
                message: "Internal server error"
            )
        )
        
        // Attempt to list datasets
        await assertThrowsError({
            _ = try await client.listDatasets()
        }, expectedError: DifyError(message: "HTTP error: Internal server error", code: nil, status: 500))
    }
    
    @Test("Create Dataset - Invalid Input")
    func testCreateDatasetInvalidInput() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        // Register validation error mock
        mockSession.register(
            method: "POST",
            urlPattern: "/datasets",
            response: MockResponse.error(
                statusCode: 400,
                code: "invalid_param",
                message: "Dataset name cannot be empty"
            )
        )
        
        // Attempt to create dataset with empty name
        await assertThrowsError({
            _ = try await client.createDataset(name: "")
        }, expectedError: DifyError(message: "HTTP error: Dataset name cannot be empty", code: nil, status: 400))
    }
    
    @Test("List Documents - Dataset Not Found")
    func testListDocumentsDatasetNotFound() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        let datasetId = "non-existent-dataset"
        
        // Register not found error mock
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.error(
                statusCode: 404,
                code: "dataset_not_found",
                message: "Dataset not found"
            )
        )
        
        // Attempt to list documents
        await assertThrowsError({
            _ = try await client.listDocuments(datasetId: datasetId)
        }, expectedError: DifyError(message: "HTTP error: Dataset not found", code: nil, status: 404))
    }
    
    @Test("List Documents - Empty Results")
    func testListDocumentsEmptyResults() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        
        let datasetId = "empty-dataset"
        
        // Register empty documents mock
        let emptyDocuments: [String: Any] = [
            "data": [],
            "has_more": false,
            "total": 0,
            "page": 1,
            "limit": 20
        ]
        
        mockSession.register(
            method: "GET",
            urlPattern: "/datasets/\(datasetId)/documents",
            response: MockResponse.json(emptyDocuments)
        )
        
        // List documents
        let response = try await client.listDocuments(datasetId: datasetId)
        
        // Verify empty response
        #expect(response.total == 0)
        #expect(response.hasMore == false)
        #expect(response.data.isEmpty)
    }

    // MARK: - Dataset Detail & Update

    @Test("Get and Update Dataset Detail")
    func testDatasetDetailAndUpdate() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()

        let datasetId = "b5829712-b2fb-4e47-bc0b-5f6f29c08162"

        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)", response: MockResponse.json(MockDataProvider.datasetDetail))
        mockSession.register(method: "PATCH", urlPattern: "/datasets/\(datasetId)", response: MockResponse.json(MockDataProvider.datasetDetail))

        let detail = try await client.getDatasetDetail(datasetId: datasetId)
        #expect(detail.name == "Product Documentation")
        #expect(detail.retrievalModelDict?.topK == 5)
        #expect(detail.docForm == .textModel)

        let req = KBUpdateDatasetRequest(name: "New Name", indexingTechnique: .economy)
        let updated = try await client.updateDataset(datasetId: datasetId, req)
        #expect(updated.name == "Product Documentation")
    }

    // MARK: - Create/Update Documents via OpenAPI paths

    @Test("Create Document From Text & Get Detail")
    func testCreateDocumentFromTextAndDetail() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "c8b7e36e-0dca-443e-b5f5-2e865e6cbeb5"

        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/document/create-by-text", response: MockResponse.json(MockDataProvider.documentCreationResponse))
        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)", response: MockResponse.json(MockDataProvider.documentDetail))

        let createReq = KBCreateDocumentByTextRequest(name: "test_document.txt", text: "Hello world", indexingTechnique: .economy, docForm: .textModel, docLanguage: "English", processRule: KBProcessRule(mode: "automatic", rules: nil), retrievalModel: nil, embeddingModel: nil, embeddingModelProvider: nil)
        let created = try await client.createDocumentFromText(datasetId: datasetId, createReq)
        #expect(created.id == "new-doc-123")
        #expect(created.indexingStatus == "indexing")

        let detail = try await client.getDocumentDetail(datasetId: datasetId, documentId: documentId)
        #expect(detail.indexingStatus == "completed")
        #expect(detail.segmentCount == 10)
    }

    @Test("Create/Update Document From File & Indexing Status")
    func testCreateUpdateDocumentFromFileAndIndexingStatus() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "new-doc-123"

        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/document/create-by-file", response: MockResponse.json(MockDataProvider.documentCreationResponse))
        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/update-by-file", response: MockResponse.json(MockDataProvider.documentCreationResponse))
        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)/documents/batch-001/indexing-status", response: MockResponse.json(MockDataProvider.indexingStatus))

        let fileData = Data([0x00, 0x01])
        let reqData = KBCreateDocumentByFileData(originalDocumentId: nil, indexingTechnique: .highQuality, docForm: .textModel, docLanguage: "English", processRule: KBProcessRule(mode: "automatic", rules: nil), retrievalModel: nil, embeddingModel: nil, embeddingModelProvider: nil)
        let created = try await client.createDocumentFromFile(datasetId: datasetId, fileName: "a.txt", fileData: fileData, data: reqData)
        #expect(created.name == "test_document.txt")

        let updData = KBUpdateDocumentByFileData(name: "a2.txt", processRule: KBProcessRule(mode: "automatic", rules: nil))
        let updated = try await client.updateDocumentByFile(datasetId: datasetId, documentId: documentId, fileName: "a2.txt", fileData: fileData, data: updData)
        #expect(updated.indexingStatus == "indexing")

        let statuses = try await client.getDocumentIndexingStatus(datasetId: datasetId, batch: "batch-001")
        #expect(statuses.count == 1)
        #expect(statuses[0].completedSegments == 5)
    }

    @Test("Update Document By Text & Batch Status Action")
    func testUpdateDocumentByTextAndBatchStatus() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-2"
        let documentId = "doc-2"

        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/update-by-text", response: MockResponse.json(MockDataProvider.documentCreationResponse))
        mockSession.register(method: "PATCH", urlPattern: "/datasets/\(datasetId)/documents/status/enable", response: MockResponse.json(MockDataProvider.successResponse()))

        let req = KBUpdateDocumentByTextRequest(name: "New Name", text: "New content", processRule: KBProcessRule(mode: "automatic", rules: nil))
        let updated = try await client.updateDocumentByText(datasetId: datasetId, documentId: documentId, req)
        #expect(updated.id == "new-doc-123")

        let statusResp = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .enable, documentIds: [documentId])
        #expect(statusResp.result == "success")
    }

    // MARK: - Segments and Child Chunks

    @Test("Segments CRUD")
    func testSegmentsCRUD() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "doc-1"

        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments", response: MockResponse.json(MockDataProvider.segmentList))
        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments", response: MockResponse.json(MockDataProvider.segmentCreatedPage))

        let list = try await client.listSegments(datasetId: datasetId, documentId: documentId)
        #expect(list.data.count == 1)

        let created = try await client.createSegments(datasetId: datasetId, documentId: documentId, KBCreateSegmentsRequest(segments: [.init(content: "Second chunk", answer: nil, keywords: ["body"]) ]))
        #expect(created.total == 2)
    }

    @Test("Segments List Only")
    func testSegmentsListOnly() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "doc-1"
        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments", response: MockResponse.json(MockDataProvider.segmentList))
        let list = try await client.listSegments(datasetId: datasetId, documentId: documentId)
        #expect(list.data.count == 1)
    }

    @Test("Segments Create Page")
    func testSegmentsCreatePage() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "doc-1"
        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments", response: MockResponse.json(MockDataProvider.segmentCreatedPage))
        let page = try await client.createSegments(datasetId: datasetId, documentId: documentId, KBCreateSegmentsRequest(segments: [.init(content: "Second chunk", answer: nil, keywords: ["body"]) ]))
        #expect(page.total == 2)
    }

    @Test("Segment Detail & Update & Delete")
    func testSegmentDetailUpdateDelete() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "doc-1"
        let segmentId = "seg-1"

        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)", response: MockResponse.json(MockDataProvider.segmentDetail))
        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)", response: MockResponse.json(MockDataProvider.segmentDetail))
        mockSession.register(method: "DELETE", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)", response: MockResponse.json(MockDataProvider.successResponse()))

        let detail = try await client.getSegmentDetail(datasetId: datasetId, documentId: documentId, segmentId: segmentId)
        #expect(detail.data.id == segmentId)

        let upd = try await client.updateSegment(datasetId: datasetId, documentId: documentId, segmentId: segmentId, KBUpdateSegmentRequest(segment: .init(content: "First chunk - updated", answer: nil, keywords: ["intro"], enabled: true, regenerateChildChunks: false)))
        #expect(upd.data.id == segmentId)

        try await client.deleteSegment(datasetId: datasetId, documentId: documentId, segmentId: segmentId)
    }

    @Test("Child Chunks CRUD")
    func testChildChunksCRUD() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let documentId = "doc-1"
        let segmentId = "seg-1"
        let childChunkId = "child-2"

        mockSession.register(method: "GET", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks", response: MockResponse.json(MockDataProvider.childChunkList))
        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks", response: MockResponse.json(MockDataProvider.childChunkResponse))
        mockSession.register(method: "PATCH", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks/\(childChunkId)", response: MockResponse.json(MockDataProvider.childChunkResponse))
        mockSession.register(method: "DELETE", urlPattern: "/datasets/\(datasetId)/documents/\(documentId)/segments/\(segmentId)/child_chunks/\(childChunkId)", response: MockResponse.json(MockDataProvider.successResponse()))

        let list = try await client.listChildChunks(datasetId: datasetId, documentId: documentId, segmentId: segmentId, keyword: "Child")
        #expect(list.total == 1)

        let created = try await client.createChildChunk(datasetId: datasetId, documentId: documentId, segmentId: segmentId, KBCreateChildChunkRequest(content: "Child B"))
        #expect(created.data.id == childChunkId)

        let updated = try await client.updateChildChunk(datasetId: datasetId, documentId: documentId, segmentId: segmentId, childChunkId: childChunkId, KBUpdateChildChunkRequest(content: "Child B+"))
        #expect(updated.data.content == "Child B")

        try await client.deleteChildChunk(datasetId: datasetId, documentId: documentId, segmentId: segmentId, childChunkId: childChunkId)
    }

    // MARK: - Retrieve & Models & Tags

    @Test("Retrieve & Embedding Models")
    func testRetrieveAndModels() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"

        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/retrieve", response: MockResponse.json(MockDataProvider.retrieveResponse))
        mockSession.register(method: "GET", urlPattern: "/workspaces/current/models/model-types/text-embedding", response: MockResponse.json(MockDataProvider.embeddingModels))

        let resp = try await client.retrieve(datasetId: datasetId, KBRetrieveRequest(query: "What is onboarding?", retrievalModel: nil))
        #expect(resp.records.count == 1)
        #expect(resp.records[0].score > 0.5)

        let models = try await client.getAvailableEmbeddingModels()
        #expect(models.count == 1)
        #expect(models[0].provider == "openai")
    }

    #if false
    @Test("Tags CRUD & Binding", .disabled())
    func testTagsCrudAndBinding() async throws {
        let (client, mockSession) = TestUtilities.createTestKnowledgeBaseClientWithMockSession()
        let datasetId = "ds-1"
        let tagId = "t1"

        mockSession.register(method: "POST", urlPattern: "/datasets/tags", response: MockResponse.json(MockDataProvider.tag))
        mockSession.register(method: "GET", urlPattern: "/datasets/tags", response: MockResponse.json(MockDataProvider.tags))
        mockSession.register(method: "PATCH", urlPattern: "/datasets/tags", response: MockResponse.json(MockDataProvider.tag))
        mockSession.register(method: "DELETE", urlPattern: "/datasets/tags", response: MockResponse.json(MockDataProvider.successResponse()))
        mockSession.register(method: "POST", urlPattern: "/datasets/tags/binding", response: MockResponse.json(MockDataProvider.successResponse()))
        mockSession.register(method: "POST", urlPattern: "/datasets/tags/unbinding", response: MockResponse.json(MockDataProvider.successResponse()))
        mockSession.register(method: "POST", urlPattern: "/datasets/\(datasetId)/tags", response: MockResponse.json(MockDataProvider.datasetTagsQuery))

        let created = try await client.createKnowledgeTag(name: "docs")
        #expect(created.id == tagId)

        let list = try await client.getKnowledgeTags()
        #expect(list.count == 2)

        let updated = try await client.updateKnowledgeTag(tagId: tagId, name: "docs2")
        #expect(updated.name == "docs")

        try await client.deleteKnowledgeTag(tagId: tagId)

        let bindResult = try await client.bindTagsToDataset(datasetId: datasetId, tagIds: [tagId])
        #expect(bindResult.result == "success" || bindResult.result == nil)
        let bindCaptured = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/datasets/tags/binding") ?? false }
        #expect(bindCaptured != nil)

        let unbindResult = try await client.unbindTagFromDataset(datasetId: datasetId, tagId: tagId)
        #expect(unbindResult.result == "success" || unbindResult.result == nil)
        let unbindCaptured = mockSession.getCapturedRequests().first { $0.url?.absoluteString.contains("/datasets/tags/unbinding") ?? false }
        #expect(unbindCaptured != nil)

        let query = try await client.queryDatasetTags(datasetId: datasetId)
        #expect(query.data.count == 1)
        #expect(query.data[0].id == tagId)
    }
    #endif
}
