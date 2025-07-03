import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

// MARK: - Advanced Knowledge Base Client Mock Tests

@Suite("Advanced Knowledge Base Client Mock Tests")
struct AdvancedKnowledgeBaseClientMockTests {
    
    @Test("Create dataset")
    func testCreateDataset() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.datasetResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.createDataset(name: "Test Dataset")
        
        #expect(response.id == MockDataProvider.testDatasetId)
        #expect(response.name == "Test Dataset")
        #expect(response.description == "A test dataset for mock testing")
        #expect(response.permission == "only_me")
        #expect(response.dataSourceType == "upload_file")
        #expect(response.indexingTechnique == "high_quality")
        
        // Validate request
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "datasets",
            expectedMethod: "POST"
        )
        
        struct ExpectedRequest: Codable, Sendable {
            let name: String
        }
        
        let requestBody = try TestUtilities.validateJSONRequestBody(
            request: request,
            expectedType: ExpectedRequest.self
        )
        
        #expect(requestBody.name == "Test Dataset")
    }
    
    @Test("List datasets with pagination")
    func testListDatasets() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.listDatasets(page: 2, pageSize: 50)
        
        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.page == 1)
        
        let dataset = response.data[0]
        #expect(dataset.id == MockDataProvider.testDatasetId)
        #expect(dataset.name == "Test Dataset")
        
        // Validate request parameters
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "datasets",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("page=2"))
        #expect(query.contains("limit=50"))
    }
    
    @Test("Delete dataset")
    func testDeleteDataset() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)",
            response: MockURLProtocol.MockResponse(statusCode: 204)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        // Should not throw for successful deletion
        try await client.deleteDataset()
    }
    
    @Test("Create document by text")
    func testCreateDocumentByText() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/document/create_by_text",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.createDocumentResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let extraParams = [
            "indexing_technique": "high_quality",
            "process_rule": ["mode": "automatic"] as [String: Any]
        ] as [String: Any]
        
        let response = try await client.createDocumentByText(
            name: "Test Document",
            text: "This is a test document content for knowledge base.",
            extraParams: extraParams
        )
        
        #expect(response.document.id == MockDataProvider.testDocumentId)
        #expect(response.document.name == "test-document.pdf")
        #expect(response.batch == "batch-789")
        
        // Validate that request was made to correct endpoint
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "datasets/\(MockDataProvider.testDatasetId)/document/create_by_text",
            expectedMethod: "POST"
        )
        
        TestAssertions.verifyContentType(request: request, expectedType: "application/json")
    }
    
    @Test("Update document by text")
    func testUpdateDocumentByText() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/update_by_text",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.createDocumentResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let response = try await client.updateDocumentByText(
            documentId: MockDataProvider.testDocumentId,
            name: "Updated Document",
            text: "This is updated document content."
        )
        
        #expect(response.document.id == MockDataProvider.testDocumentId)
        #expect(response.batch == "batch-789")
    }
    
    @Test("Create document by file")
    func testCreateDocumentByFile() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/document/create_by_file",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.createDocumentResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let fileData = TestUtilities.createTestFileData(size: 2048)
        
        let response = try await client.createDocumentByFile(
            fileData: fileData,
            filename: "test-document.pdf",
            mimeType: "application/pdf",
            originalDocumentId: "original-doc-123"
        )
        
        #expect(response.document.id == MockDataProvider.testDocumentId)
        #expect(response.batch == "batch-789")
    }
    
    @Test("Update document by file")
    func testUpdateDocumentByFile() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/update_by_file",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.createDocumentResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let fileData = TestUtilities.createTestFileData(size: 1024)
        
        let response = try await client.updateDocumentByFile(
            documentId: MockDataProvider.testDocumentId,
            fileData: fileData,
            filename: "updated-document.pdf",
            mimeType: "application/pdf"
        )
        
        #expect(response.document.id == MockDataProvider.testDocumentId)
    }
    
    @Test("List documents with filters")
    func testListDocuments() async throws {
        TestUtilities.setupStandardMocks()
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.listDocuments(
            page: 3,
            pageSize: 25,
            keyword: "test"
        )
        
        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
        #expect(response.total == 1)
        #expect(response.page == 1)
        
        let document = response.data[0]
        #expect(document.id == MockDataProvider.testDocumentId)
        #expect(document.name == "test-document.pdf")
        #expect(document.indexingStatus == "completed")
        #expect(document.enabled == true)
        #expect(document.archived == false)
        
        // Validate request parameters
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "datasets/\(MockDataProvider.testDatasetId)/documents",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("page=3"))
        #expect(query.contains("limit=25"))
        #expect(query.contains("keyword=test"))
    }
    
    @Test("Delete document")
    func testDeleteDocument() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let response = try await client.deleteDocument(documentId: MockDataProvider.testDocumentId)
        #expect(response.result == "success")
    }
    
    @Test("Get batch indexing status")
    func testBatchIndexingStatus() async throws {
        let batchStatusResponse: [String: Any] = [
            "id": "batch-789",
            "indexing_status": "completed",
            "processing_started_at": 1726139600,
            "parsing_completed_at": 1726139620,
            "cleaning_completed_at": 1726139630,
            "splitting_completed_at": 1726139640,
            "completed_at": 1726139644,
            "paused_by": NSNull(),
            "paused_at": NSNull(),
            "canceled_by": NSNull(),
            "canceled_at": NSNull(),
            "error": NSNull()
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/batch-789/indexing-status",
            response: MockURLProtocol.MockResponse.json(batchStatusResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let response = try await client.batchIndexingStatus(batchId: "batch-789")
        
        #expect(response.id == "batch-789")
        #expect(response.indexingStatus == "completed")
        #expect(response.processingStartedAt == 1726139600)
        #expect(response.completedAt == 1726139644)
        #expect(response.error == nil)
    }
    
    @Test("Add segments to document")
    func testAddSegments() async throws {
        let addSegmentsResponse: [String: Any] = [
            "data": [
                [
                    "id": "segment-123",
                    "position": 1,
                    "document_id": MockDataProvider.testDocumentId,
                    "content": "This is a test segment.",
                    "answer": "This segment provides test information.",
                    "word_count": 5,
                    "tokens": 8,
                    "keywords": ["test", "segment"],
                    "index_node_id": "node-456",
                    "index_node_hash": "hash-789",
                    "hit_count": 0,
                    "enabled": true,
                    "disabled_at": NSNull(),
                    "disabled_by": NSNull(),
                    "status": "completed",
                    "created_by": MockTestConfig.user,
                    "created_at": 1726139644,
                    "indexing_at": 1726139644,
                    "completed_at": 1726139644,
                    "error": NSNull(),
                    "stopped_at": NSNull()
                ]
            ]
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/segments",
            response: MockURLProtocol.MockResponse.json(addSegmentsResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let segments = [
            SegmentData(
                content: "This is a test segment.",
                answer: "This segment provides test information.",
                keywords: ["test", "segment"],
                enabled: true
            )
        ]
        
        let response = try await client.addSegments(
            documentId: MockDataProvider.testDocumentId,
            segments: segments
        )
        
        #expect(response.data.count == 1)
        let segment = response.data[0]
        #expect(segment.id == "segment-123")
        #expect(segment.content == "This is a test segment.")
        #expect(segment.keywords == ["test", "segment"])
        #expect(segment.enabled == true)
    }
    
    @Test("Query segments in document")
    func testQuerySegments() async throws {
        let segmentsResponse: [String: Any] = [
            "data": [
                [
                    "id": "segment-123",
                    "position": 1,
                    "document_id": MockDataProvider.testDocumentId,
                    "content": "This is a test segment.",
                    "answer": "Test answer",
                    "word_count": 5,
                    "tokens": 8,
                    "keywords": ["test"],
                    "index_node_id": "node-456",
                    "index_node_hash": "hash-789",
                    "hit_count": 0,
                    "enabled": true,
                    "disabled_at": NSNull(),
                    "disabled_by": NSNull(),
                    "status": "completed",
                    "created_by": MockTestConfig.user,
                    "created_at": 1726139644,
                    "indexing_at": 1726139644,
                    "completed_at": 1726139644,
                    "error": NSNull(),
                    "stopped_at": NSNull()
                ]
            ],
            "has_more": false,
            "limit": 20
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/segments",
            response: MockURLProtocol.MockResponse.json(segmentsResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockRequestCapture.startCapturing()
        defer { MockRequestCapture.stopCapturing() }
        
        let response = try await client.querySegments(
            documentId: MockDataProvider.testDocumentId,
            keyword: "test",
            status: "completed"
        )
        
        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.limit == 20)
        
        // Validate request parameters
        let requests = MockRequestCapture.getCapturedRequests()
        let request = try TestUtilities.validateRequest(
            requests: requests,
            expectedEndpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/segments",
            expectedMethod: "GET"
        )
        
        let url = request.url!
        let query = url.query ?? ""
        #expect(query.contains("keyword=test"))
        #expect(query.contains("status=completed"))
    }
    
    @Test("Update document segment")
    func testUpdateDocumentSegment() async throws {
        let updateSegmentResponse: [String: Any] = [
            "data": [
                "id": "segment-123",
                "position": 1,
                "document_id": MockDataProvider.testDocumentId,
                "content": "Updated segment content.",
                "answer": "Updated answer",
                "word_count": 3,
                "tokens": 5,
                "keywords": ["updated"],
                "index_node_id": "node-456",
                "index_node_hash": "hash-789",
                "hit_count": 0,
                "enabled": true,
                "disabled_at": NSNull(),
                "disabled_by": NSNull(),
                "status": "completed",
                "created_by": MockTestConfig.user,
                "created_at": 1726139644,
                "indexing_at": 1726139644,
                "completed_at": 1726139644,
                "error": NSNull(),
                "stopped_at": NSNull()
            ]
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/segments/segment-123",
            response: MockURLProtocol.MockResponse.json(updateSegmentResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let segmentData = SegmentData(
            content: "Updated segment content.",
            answer: "Updated answer",
            keywords: ["updated"],
            enabled: true
        )
        
        let response = try await client.updateDocumentSegment(
            documentId: MockDataProvider.testDocumentId,
            segmentId: "segment-123",
            segmentData: segmentData
        )
        
        #expect(response.data.id == "segment-123")
        #expect(response.data.content == "Updated segment content.")
        #expect(response.data.keywords == ["updated"])
    }
    
    @Test("Delete document segment")
    func testDeleteDocumentSegment() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/\(MockDataProvider.testDocumentId)/segments/segment-123",
            response: MockURLProtocol.MockResponse.json(MockDataProvider.baseSuccessResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let response = try await client.deleteDocumentSegment(
            documentId: MockDataProvider.testDocumentId,
            segmentId: "segment-123"
        )
        
        #expect(response.result == "success")
    }
}

// MARK: - Knowledge Base Client Error Handling Tests

@Suite("Knowledge Base Client Error Handling Tests")
struct KnowledgeBaseClientErrorHandlingTests {
    
    @Test("Handle missing dataset ID error")
    func testMissingDatasetIdError() async throws {
        // Create client without dataset ID
        let client = try TestUtilities.createMockKnowledgeBaseClient(datasetId: nil)
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.listDocuments()
        }
    }
    
    @Test("Handle dataset not found error")
    func testDatasetNotFoundError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/nonexistent-dataset",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 404, message: "Dataset not found")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient(datasetId: "nonexistent-dataset")
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.deleteDataset()
        }
    }
    
    @Test("Handle file upload size limit error")
    func testFileUploadSizeLimitError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/document/create_by_file",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 413, message: "File too large")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let largeFileData = TestUtilities.createTestFileData(size: 50 * 1024 * 1024) // 50MB
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createDocumentByFile(
                fileData: largeFileData,
                filename: "large-file.pdf",
                mimeType: "application/pdf"
            )
        }
    }
    
    @Test("Handle invalid document format error")
    func testInvalidDocumentFormatError() async throws {
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/document/create_by_file",
            response: MockURLProtocol.MockResponse.httpError(statusCode: 400, message: "Unsupported file format")
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let invalidFileData = Data("Invalid file content".utf8)
        
        await TestUtilities.expectError(DifyError.self) {
            try await client.createDocumentByFile(
                fileData: invalidFileData,
                filename: "invalid.xyz",
                mimeType: "application/unknown"
            )
        }
    }
    
    @Test("Handle indexing failure error")
    func testIndexingFailureError() async throws {
        let failedBatchResponse: [String: Any] = [
            "id": "batch-failed",
            "indexing_status": "error",
            "processing_started_at": 1726139600,
            "parsing_completed_at": NSNull(),
            "cleaning_completed_at": NSNull(),
            "splitting_completed_at": NSNull(),
            "completed_at": NSNull(),
            "paused_by": NSNull(),
            "paused_at": NSNull(),
            "canceled_by": NSNull(),
            "canceled_at": NSNull(),
            "error": "Failed to parse document content"
        ]
        
        MockURLProtocol.registerMock(
            endpoint: "datasets/\(MockDataProvider.testDatasetId)/documents/batch-failed/indexing-status",
            response: MockURLProtocol.MockResponse.json(failedBatchResponse)
        )
        defer { TestUtilities.cleanup() }
        
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let response = try await client.batchIndexingStatus(batchId: "batch-failed")
        
        #expect(response.indexingStatus == "error")
        #expect(response.error == "Failed to parse document content")
        #expect(response.completedAt == 0) // Should be 0 for failed indexing
    }
}