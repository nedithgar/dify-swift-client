import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("KnowledgeBaseClient Tests")
struct KnowledgeBaseClientTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - Datasets Tests
    
    @Test("List datasets with default parameters")
    func testListDatasetsWithDefaultParameters() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDatasets)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDatasets()
        
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "Test Dataset")
        #expect(response.data[0].permission == "only_me")
        #expect(response.data[0].dataSourceType == "upload_file")
        #expect(response.page == 1)
        #expect(response.limit == 20)
    }
    
    @Test("List datasets with custom pagination")
    func testListDatasetsWithCustomPagination() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDatasets)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDatasets(page: 2, limit: 10)
        
        #expect(response.data.count == 1)
        #expect(response.page == 1) // Mock returns page 1
        #expect(response.limit == 20) // Mock returns limit 20
    }
    
    @Test("List datasets with no results")
    func testListDatasetsWithNoResults() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let emptyDatasets = DatasetsResponse(
            data: [],
            hasMore: false,
            limit: 20,
            total: 0,
            page: 1
        )
        
        let mockData = MockDataProvider.jsonData(emptyDatasets)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDatasets()
        
        #expect(response.data.count == 0)
        #expect(response.total == 0)
        #expect(response.hasMore == false)
    }
    
    @Test("List datasets with API error")
    func testListDatasetsWithAPIError() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 403, message: "Forbidden")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.listDatasets()
        }
    }
    
    // MARK: - Create Dataset Tests
    
    @Test("Create dataset with valid name")
    func testCreateDatasetWithValidName() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDataset)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let response = try await client.createDataset(name: "New Dataset")
        
        #expect(response.name == "Test Dataset")
        #expect(response.id == "dataset-123")
    }
    
    @Test("Create dataset with empty name")
    func testCreateDatasetWithEmptyName() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Dataset name cannot be empty")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createDataset(name: "")
        }
    }
    
    @Test("Create dataset with duplicate name")
    func testCreateDatasetWithDuplicateName() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 409, message: "Dataset with this name already exists")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createDataset(name: "Existing Dataset")
        }
    }
    
    @Test("Create dataset with very long name")
    func testCreateDatasetWithVeryLongName() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDataset)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let longName = String(repeating: "A", count: 1000)
        
        let response = try await client.createDataset(name: longName)
        
        #expect(response.id == "dataset-123")
    }
    
    @Test("Create dataset with special characters in name")
    func testCreateDatasetWithSpecialCharactersInName() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDataset)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let response = try await client.createDataset(name: "Dataset with 特殊字符 & symbols! @#$%")
        
        #expect(response.id == "dataset-123")
    }
    
    // MARK: - Delete Dataset Tests
    
    @Test("Delete dataset with valid ID")
    func testDeleteDatasetWithValidID() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.deleteDataset(datasetId: "dataset-123")
        
        #expect(response.result == "success")
    }
    
    @Test("Delete dataset with invalid ID")
    func testDeleteDatasetWithInvalidID() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Dataset not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDataset(datasetId: "invalid-dataset")
        }
    }
    
    @Test("Delete dataset that's in use")
    func testDeleteDatasetThatsInUse() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 409, message: "Dataset is in use by applications")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDataset(datasetId: "dataset-in-use")
        }
    }
    
    @Test("Delete dataset without permission")
    func testDeleteDatasetWithoutPermission() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 403, message: "Insufficient permissions")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDataset(datasetId: "dataset-123")
        }
    }
    
    // MARK: - Documents Tests
    
    @Test("List documents with default parameters")
    func testListDocumentsWithDefaultParameters() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocuments)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDocuments(datasetId: "dataset-123")
        
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "test.pdf")
        #expect(response.data[0].indexingStatus == "completed")
        #expect(response.data[0].tokens == 500)
    }
    
    @Test("List documents with custom pagination")
    func testListDocumentsWithCustomPagination() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocuments)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDocuments(datasetId: "dataset-123", page: 2, limit: 10)
        
        #expect(response.data.count == 1)
        #expect(response.page == 1) // Mock returns page 1
        #expect(response.limit == 20) // Mock returns limit 20
    }
    
    @Test("List documents with keyword filter")
    func testListDocumentsWithKeywordFilter() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocuments)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDocuments(datasetId: "dataset-123", keyword: "test")
        
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "test.pdf")
    }
    
    @Test("List documents with no results")
    func testListDocumentsWithNoResults() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        let emptyDocuments = DocumentsResponse(
            data: [],
            hasMore: false,
            limit: 20,
            total: 0,
            page: 1
        )
        
        let mockData = MockDataProvider.jsonData(emptyDocuments)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDocuments(datasetId: "dataset-123")
        
        #expect(response.data.count == 0)
        #expect(response.total == 0)
    }
    
    @Test("List documents with invalid dataset ID")
    func testListDocumentsWithInvalidDatasetID() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Dataset not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.listDocuments(datasetId: "invalid-dataset")
        }
    }
    
    @Test("List documents with special characters in keyword")
    func testListDocumentsWithSpecialCharactersInKeyword() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocuments)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDocuments(
            datasetId: "dataset-123",
            keyword: "search term with 中文 & symbols! @#$%"
        )
        
        #expect(response.data.count == 1)
    }
    
    // MARK: - Create Document Tests
    
    @Test("Create document with PDF file")
    func testCreateDocumentWithPDFFile() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let pdfData = TestUtilities.createTestFileData(size: 2048)
        let processRule = TestUtilities.createTestProcessRule()
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: pdfData,
            fileName: "document.pdf",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
        #expect(response.name == "test.pdf")
    }
    
    @Test("Create document with text file")
    func testCreateDocumentWithTextFile() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let textData = Data("This is a test document content.".utf8)
        let processRule = TestUtilities.createTestProcessRule(mode: "custom")
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: textData,
            fileName: "document.txt",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    @Test("Create document with Word file")
    func testCreateDocumentWithWordFile() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let wordData = TestUtilities.createTestFileData(size: 4096)
        let processRule = TestUtilities.createTestProcessRule()
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: wordData,
            fileName: "document.docx",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    @Test("Create document with automatic processing rule")
    func testCreateDocumentWithAutomaticProcessingRule() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let fileData = TestUtilities.createTestFileData()
        let processRule = ProcessRule(mode: "automatic")
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: fileData,
            fileName: "auto.pdf",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    @Test("Create document with custom processing rule")
    func testCreateDocumentWithCustomProcessingRule() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let fileData = TestUtilities.createTestFileData()
        let processRule = ProcessRule(
            mode: "custom",
            rules: [
                "pre_processing_rules": "remove_extra_spaces,remove_urls_emails",
                "segmentation": "automatic"
            ]
        )
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: fileData,
            fileName: "custom.pdf",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    @Test("Create document with empty file")
    func testCreateDocumentWithEmptyFile() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "File cannot be empty")
        
        let emptyData = Data()
        let processRule = TestUtilities.createTestProcessRule()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createDocument(
                datasetId: "dataset-123",
                fileData: emptyData,
                fileName: "empty.pdf",
                processRule: processRule
            )
        }
    }
    
    @Test("Create document with unsupported file type")
    func testCreateDocumentWithUnsupportedFileType() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 400, message: "Unsupported file type")
        
        let fileData = TestUtilities.createTestFileData()
        let processRule = TestUtilities.createTestProcessRule()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createDocument(
                datasetId: "dataset-123",
                fileData: fileData,
                fileName: "unsupported.exe",
                processRule: processRule
            )
        }
    }
    
    @Test("Create document with file too large")
    func testCreateDocumentWithFileTooLarge() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 413, message: "File too large")
        
        let largeFile = TestUtilities.createTestFileData(size: 100_000_000) // 100MB
        let processRule = TestUtilities.createTestProcessRule()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createDocument(
                datasetId: "dataset-123",
                fileData: largeFile,
                fileName: "large.pdf",
                processRule: processRule
            )
        }
    }
    
    @Test("Create document with invalid dataset ID")
    func testCreateDocumentWithInvalidDatasetID() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Dataset not found")
        
        let fileData = TestUtilities.createTestFileData()
        let processRule = TestUtilities.createTestProcessRule()
        
        await TestUtilities.assertThrowsAnyError {
            try await client.createDocument(
                datasetId: "invalid-dataset",
                fileData: fileData,
                fileName: "document.pdf",
                processRule: processRule
            )
        }
    }
    
    @Test("Create document with special characters in filename")
    func testCreateDocumentWithSpecialCharactersInFilename() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let fileData = TestUtilities.createTestFileData()
        let processRule = TestUtilities.createTestProcessRule()
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: fileData,
            fileName: "文档 with spaces & symbols!.pdf",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    // MARK: - Delete Document Tests
    
    @Test("Delete document with valid IDs")
    func testDeleteDocumentWithValidIDs() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockBaseResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.deleteDocument(datasetId: "dataset-123", documentId: "doc-123")
        
        #expect(response.result == "success")
    }
    
    @Test("Delete document with invalid dataset ID")
    func testDeleteDocumentWithInvalidDatasetID() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Dataset not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDocument(datasetId: "invalid-dataset", documentId: "doc-123")
        }
    }
    
    @Test("Delete document with invalid document ID")
    func testDeleteDocumentWithInvalidDocumentID() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 404, message: "Document not found")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDocument(datasetId: "dataset-123", documentId: "invalid-doc")
        }
    }
    
    @Test("Delete document that's being processed")
    func testDeleteDocumentThatsBeingProcessed() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 409, message: "Document is being processed")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDocument(datasetId: "dataset-123", documentId: "processing-doc")
        }
    }
    
    @Test("Delete document without permission")
    func testDeleteDocumentWithoutPermission() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 403, message: "Insufficient permissions")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.deleteDocument(datasetId: "dataset-123", documentId: "doc-123")
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle concurrent dataset operations")
    func testHandleConcurrentDatasetOperations() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockListData = MockDataProvider.jsonData(MockDataProvider.mockDatasets)
        let mockCreateData = MockDataProvider.jsonData(MockDataProvider.mockDataset)
        
        await MainActor.run {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                
                if request.httpMethod == "GET" {
                    return (response, mockListData, nil)
                } else if request.httpMethod == "POST" {
                    return (response, mockCreateData, nil)
                } else {
                    return (response, Data(), nil)
                }
            }
        }

        
        async let list = client.listDatasets()
        async let create1 = client.createDataset(name: "Dataset 1")
        async let create2 = client.createDataset(name: "Dataset 2")
        
        let (listResult, createResult1, createResult2) = try await (list, create1, create2)
        
        #expect(listResult.data.count == 1)
        #expect(createResult1.id == "dataset-123")
        #expect(createResult2.id == "dataset-123")
    }
    
    @Test("Handle concurrent document operations")
    func testHandleConcurrentDocumentOperations() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockListData = MockDataProvider.jsonData(MockDataProvider.mockDocuments)
        let mockCreateData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            
            if request.httpMethod == "GET" {
                return (response, mockListData, nil)
            } else if request.httpMethod == "POST" {
                return (response, mockCreateData, nil)
            } else {
                return (response, Data(), nil)
            }
        }
        
        let fileData = TestUtilities.createTestFileData()
        let processRule = TestUtilities.createTestProcessRule()
        
        async let list = client.listDocuments(datasetId: "dataset-123")
        async let create1 = client.createDocument(datasetId: "dataset-123", fileData: fileData, fileName: "doc1.pdf", processRule: processRule)
        async let create2 = client.createDocument(datasetId: "dataset-123", fileData: fileData, fileName: "doc2.pdf", processRule: processRule)
        
        let (listResult, createResult1, createResult2) = try await (list, create1, create2)
        
        #expect(listResult.data.count == 1)
        #expect(createResult1.id == "doc-123")
        #expect(createResult2.id == "doc-123")
    }
    
    @Test("Handle network timeout")
    func testHandleNetworkTimeout() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        
        MockURLProtocol.setMockError(timeoutError)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.listDatasets()
        }
    }
    
    @Test("Handle server error")
    func testHandleServerError() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        MockURLProtocol.setMockHTTPError(statusCode: 500, message: "Internal Server Error")
        
        await TestUtilities.assertThrowsAnyError {
            try await client.listDatasets()
        }
    }
    
    @Test("Handle malformed JSON response")
    func testHandleMalformedJSONResponse() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let malformedJSON = Data("{ invalid json }".utf8)
        
        MockURLProtocol.setMockResponse(data: malformedJSON, statusCode: 200)
        
        await TestUtilities.assertThrowsAnyError {
            try await client.listDatasets()
        }
    }
    
    @Test("Handle very large document uploads")
    func testHandleVeryLargeDocumentUploads() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let largeFile = TestUtilities.createTestFileData(size: 10_000_000) // 10MB
        let processRule = TestUtilities.createTestProcessRule()
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: largeFile,
            fileName: "large.pdf",
            processRule: processRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    @Test("Handle documents with complex processing rules")
    func testHandleDocumentsWithComplexProcessingRules() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        let mockData = MockDataProvider.jsonData(MockDataProvider.mockDocument)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 201)
        
        let fileData = TestUtilities.createTestFileData()
        let complexProcessRule = ProcessRule(
            mode: "custom",
            rules: [
                "pre_processing_rules": "remove_extra_spaces,remove_urls_emails,remove_stopwords",
                "segmentation": "custom",
                "segment_max_tokens": "1000",
                "segment_overlap_tokens": "100",
                "indexing_technique": "high_quality",
                "embedding_model": "text-embedding-ada-002"
            ]
        )
        
        let response = try await client.createDocument(
            datasetId: "dataset-123",
            fileData: fileData,
            fileName: "complex.pdf",
            processRule: complexProcessRule
        )
        
        #expect(response.id == "doc-123")
    }
    
    // MARK: - Performance Tests
    
    @Test("Handle listing many datasets")
    func testHandleListingManyDatasets() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        var manyDatasets: [DatasetResponse] = []
        for i in 0..<100 {
            manyDatasets.append(DatasetResponse(
                id: "dataset-\(i)",
                name: "Dataset \(i)",
                description: "Description for dataset \(i)",
                permission: "only_me",
                dataSourceType: "upload_file",
                indexingTechnique: "high_quality",
                appCount: 1,
                documentCount: 10,
                wordCount: 1000,
                createdBy: "user-123",
                createdAt: 1640995200
            ))
        }
        
        let largeDatasetsResponse = DatasetsResponse(
            data: manyDatasets,
            hasMore: false,
            limit: 100,
            total: 100,
            page: 1
        )
        
        let mockData = MockDataProvider.jsonData(largeDatasetsResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDatasets(page: 1, limit: 100)
        
        #expect(response.data.count == 100)
        #expect(response.total == 100)
    }
    
    @Test("Handle listing many documents")
    func testHandleListingManyDocuments() async throws {
        let client = try TestUtilities.createMockKnowledgeBaseClient()
        
        var manyDocuments: [DocumentResponse] = []
        for i in 0..<100 {
            manyDocuments.append(DocumentResponse(
                id: "doc-\(i)",
                position: i + 1,
                name: "document-\(i).pdf",
                tokens: 500,
                indexingStatus: "completed",
                createdBy: "user-123",
                createdAt: 1640995200
            ))
        }
        
        let largeDocumentsResponse = DocumentsResponse(
            data: manyDocuments,
            hasMore: false,
            limit: 100,
            total: 100,
            page: 1
        )
        
        let mockData = MockDataProvider.jsonData(largeDocumentsResponse)
        
        MockURLProtocol.setMockResponse(data: mockData, statusCode: 200)
        
        let response = try await client.listDocuments(datasetId: "dataset-123", page: 1, limit: 100)
        
        #expect(response.data.count == 100)
        #expect(response.total == 100)
    }
}