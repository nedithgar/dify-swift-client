import Foundation
import Testing
@testable import DifySwiftClient

// MARK: - Gating Flags (module-level to avoid macro circular refs)

let KB_IT_HAS_LIVE_CONFIG: Bool = {
    let env = ProcessInfo.processInfo.environment
    return (env["DIFY_API_KEY"].map { !$0.isEmpty } ?? false)
}()

let KB_IT_RUN_TAG_TESTS: Bool = {
    ProcessInfo.processInfo.environment["DIFY_RUN_TAG_TESTS"] == "1"
}()

/// Integration tests for KnowledgeBaseClient using a real Dify instance.
///
/// Opt-in via environment variables:
/// - DIFY_API_KEY: required. Server/workspace API key with Knowledge Base permissions.
/// - DIFY_BASE_URL: optional. Defaults to "https://api.dify.ai/v1" (must include /v1).
/// - DIFY_RUN_TAG_TESTS: optional. Set to "1" to run tag binding/update/delete tests.
///
/// IMPORTANT: These tests make live changes (datasets/documents/tags) and clean them up.
/// They are serialized and skipped by default if env is missing.
@Suite(
    "KnowledgeBaseClient Integration",
    .serialized,
    .enabled(if: KB_IT_HAS_LIVE_CONFIG)
)
struct KnowledgeBaseClientIntegrationTests {

    // MARK: - Live Client Bootstrap

    private static func makeClient() throws -> KnowledgeBaseClient {
        let env = ProcessInfo.processInfo.environment
        let apiKey = env["DIFY_API_KEY"] ?? ""
        let baseURL = env["DIFY_BASE_URL"] ?? "https://api.dify.ai/v1"

        // Ensure mocks from unit tests don't intercept live calls
        // (DifyTestCase registers MockURLProtocol globally).
        URLProtocol.unregisterClass(MockURLProtocol.self)

        return try KnowledgeBaseClient(apiKey: apiKey, baseURL: baseURL)
    }

    // MARK: - Helpers

    private func sleep(seconds: Double) async {
        let ns = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: ns)
    }

    private func waitForIndexingCompletion(client: KnowledgeBaseClient, datasetId: String, documentId: String, timeoutSeconds: Double = 60, pollInterval: Double = 1.0) async throws -> KBDocumentDetail {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        var lastDetail: KBDocumentDetail?
        while Date() < deadline {
            let detail = try await client.getDocumentDetail(datasetId: datasetId, documentId: documentId)
            lastDetail = detail
            if let status = detail.indexingStatus?.lowercased() {
                if status == "completed" { return detail }
                if status == "error" { break }
            }
            await sleep(seconds: pollInterval)
        }
        if let last = lastDetail { return last }
        // Fallback detail fetch
        return try await client.getDocumentDetail(datasetId: datasetId, documentId: documentId)
    }

    // MARK: - End-to-End Dataset + Document + Segments + Retrieve

    @Test("Dataset and Document lifecycle, segments, and retrieve")
    func testDatasetDocumentSegmentsAndRetrieve() async throws {
        let client = try Self.makeClient()

        // Create Dataset
        let datasetName = "SDK-IT-\(UUID().uuidString.prefix(8))"
        let dataset = try await client.createDataset(name: datasetName)
        let datasetId = dataset.id
        #expect(!datasetId.isEmpty)

        // Ensure dataset appears in list
        let list = try await client.listDatasets(keyword: datasetName, page: 1, limit: 20)
        #expect(list.data.contains { $0.id == datasetId })

        // Update dataset metadata
        let updated = try await client.updateDataset(datasetId: datasetId, KBUpdateDatasetRequest(description: "Integration test dataset"))
        #expect(updated.description == "Integration test dataset")

        // Create a document from text
        let docText = "Dify Swift SDK integration test content about knowledge bases and segments."
        let createTextReq = KBCreateDocumentByTextRequest(name: "it-text", text: docText)
        let textDoc = try await client.createDocumentFromText(datasetId: datasetId, createTextReq)
        let textDocId = textDoc.id
        #expect(!textDocId.isEmpty)

        // Wait for indexing
        let textDocDetail = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocId)
        #expect(textDocDetail.indexingStatus?.lowercased() == "completed")

        // List segments (may be >0 if splitter produced segments)
        let segments = try await client.listSegments(datasetId: datasetId, documentId: textDocId)
        if let first = segments.data.first {
            // Get and update a segment
            let segDetail = try await client.getSegmentDetail(datasetId: datasetId, documentId: textDocId, segmentId: first.id)
            #expect(segDetail.data.id == first.id)

            let updatedSeg = try await client.updateSegment(
                datasetId: datasetId,
                documentId: textDocId,
                segmentId: first.id,
                KBUpdateSegmentRequest(segment: .init(content: first.content + " [updated]", answer: nil, keywords: nil, enabled: nil, regenerateChildChunks: nil))
            )
            #expect(updatedSeg.data.id == first.id)

            // Child chunks lifecycle (best-effort; may be disabled per server settings)
            do {
                let childList = try await client.listChildChunks(datasetId: datasetId, documentId: textDocId, segmentId: first.id)
                _ = childList
                let child = try await client.createChildChunk(datasetId: datasetId, documentId: textDocId, segmentId: first.id, KBCreateChildChunkRequest(content: "child chunk content"))
                let childId = child.data.id
                let childUpdated = try await client.updateChildChunk(datasetId: datasetId, documentId: textDocId, segmentId: first.id, childChunkId: childId, KBUpdateChildChunkRequest(content: "child updated"))
                #expect(childUpdated.data.id == childId)
                try await client.deleteChildChunk(datasetId: datasetId, documentId: textDocId, segmentId: first.id, childChunkId: childId)
            } catch { /* best-effort: some deployments may not enable child chunk ops */ }
        } else {
            // Segments may be empty depending on splitter configuration
        }

        // Update the document by text
        _ = try await client.updateDocumentByText(datasetId: datasetId, documentId: textDocId, KBUpdateDocumentByTextRequest(text: docText + " [v2]"))
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocId)

        // Create a second document via file upload (small text file)
        let fileContent = "A tiny file for KB upload, used in integration tests."
        let fileData = Data(fileContent.utf8)
        let fileDoc = try await client.createDocumentFromFile(
            datasetId: datasetId,
            fileName: "kb-it.txt",
            fileData: fileData,
            data: KBCreateDocumentByFileData()
        )
        let fileDocId = fileDoc.id
        #expect(!fileDocId.isEmpty)
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: fileDocId)

        // Toggle document status (disable -> enable)
        _ = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .disable, documentIds: [textDocId])
        _ = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .enable, documentIds: [textDocId])

        // Retrieve relevant segments
        let retrieveResp = try await client.retrieve(datasetId: datasetId, KBRetrieveRequest(query: "knowledge bases and segments"))
        #expect(!retrieveResp.records.isEmpty)

        // Cleanup documents
        _ = try await client.deleteDocument(datasetId: datasetId, documentId: textDocId)
        _ = try await client.deleteDocument(datasetId: datasetId, documentId: fileDocId)

        // Final: delete dataset
        _ = try await client.deleteDataset(datasetId: datasetId)
    }

    // MARK: - Models listing

    @Test("Embedding models listing")
    func testGetAvailableEmbeddingModels() async throws {
        let client = try Self.makeClient()
        let providers = try await client.getAvailableEmbeddingModels()
        #expect(!providers.isEmpty)
    }

    // MARK: - Tags management (opt-in)

    @Test("Tags CRUD and binding (opt-in)", .enabled(if: KB_IT_RUN_TAG_TESTS))
    func testTagsCRUDAndBinding() async throws {
        let client = try Self.makeClient()

        // Create a dataset for tag binding scope
        let dataset = try await client.createDataset(name: "SDK-IT-TAGS-\(UUID().uuidString.prefix(6))")
        let datasetId = dataset.id
        defer { Task { _ = try? await client.deleteDataset(datasetId: datasetId) } }

        // Create, update, list, bind/unbind, delete tag
        let tag = try await client.createKnowledgeTag(name: "it-tag-\(Int.random(in: 1000...9999))")
        let tagId = tag.id
        let updated = try await client.updateKnowledgeTag(tagId: tagId, name: tag.name + "-u")
        #expect(updated.id == tagId)

        let _ = try await client.bindTagsToDataset(datasetId: datasetId, tagIds: [tagId])
        let bound = try await client.queryDatasetTags(datasetId: datasetId)
        #expect(bound.data.contains { $0.id == tagId })

        let _ = try await client.unbindTagFromDataset(datasetId: datasetId, tagId: tagId)
        let unbound = try await client.queryDatasetTags(datasetId: datasetId)
        #expect(!unbound.data.contains { $0.id == tagId })

        try await client.deleteKnowledgeTag(tagId: tagId)
    }
}
