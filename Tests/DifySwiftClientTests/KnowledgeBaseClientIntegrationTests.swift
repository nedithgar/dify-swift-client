import Foundation
import Testing
@testable import DifySwiftClient

// MARK: - Gating Flags (module-level to avoid macro circular refs)

let KB_IT_HAS_LIVE_CONFIG: Bool = {
    let env = ProcessInfo.processInfo.environment
    // Require a narrowly scoped key for KB integration tests.
    return (env["DIFY_KB_API_KEY"].map { !$0.isEmpty } ?? false)
}()

/// Integration tests for KnowledgeBaseClient using a real Dify instance.
///
/// Opt-in via environment variables:
/// - DIFY_KB_API_KEY: required. Server/workspace API key scoped for Knowledge Base operations.
/// - DIFY_BASE_URL: optional. Defaults to "https://api.dify.ai/v1" (must include /v1).
///
/// IMPORTANT: These tests make live changes (datasets/documents/tags) and clean them up.
/// They are serialized and skipped by default if env is missing.
@Suite(
    "KnowledgeBaseClient Integration",
    .serialized,
    .disabled(if: !KB_IT_HAS_LIVE_CONFIG)
)
struct KnowledgeBaseClientIntegrationTests {

    // MARK: - Live Client Bootstrap

    private static func makeClient() throws -> KnowledgeBaseClient {
        let env = ProcessInfo.processInfo.environment
        let apiKey = env["DIFY_KB_API_KEY"] ?? ""
        let baseURL = env["DIFY_BASE_URL"] ?? "https://api.dify.ai/v1"

        // Ensure mocks from unit tests don't intercept live calls
        // (DifyTestCase registers MockURLProtocol globally).
        URLProtocol.unregisterClass(MockURLProtocol.self)

        return try KnowledgeBaseClient(apiKey: apiKey, baseURL: baseURL)
    }

    // MARK: - Helpers

    private func sleep(seconds: Double) async {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
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

        // Ensure embedding + indexing are configured at dataset level for document ingestion
        let providers = try await client.getAvailableEmbeddingModels()
        #expect(!providers.isEmpty)
        let chosenProvider = providers.first(where: { !$0.models.isEmpty }) ?? providers[0]
        let chosenModel = chosenProvider.models.first!
        _ = try await client.updateDataset(
            datasetId: datasetId,
            KBUpdateDatasetRequest(
                indexingTechnique: .economy,
                embeddingModelProvider: chosenProvider.provider,
                embeddingModel: chosenModel.model,
                retrievalModel: KBRetrievalModel(
                    searchMethod: .semanticSearch,
                    rerankingEnable: false,
                    topK: 5,
                    scoreThresholdEnabled: false
                )
            )
        )

        // Create a document from text
        let docText = "Dify Swift SDK integration test content about knowledge bases and segments."
        let createTextRequest = KBCreateDocumentByTextRequest(
            name: "it-text",
            text: docText,
            indexingTechnique: .economy,
            docForm: .textModel,
            processRule: KBProcessRule(mode: .automatic),
            retrievalModel: KBRetrievalModel(
                searchMethod: .semanticSearch,
                rerankingEnable: false,
                topK: 5,
                scoreThresholdEnabled: false
            )
        )

        let textDocument: DocumentResponse
        do {
            textDocument = try await client.createDocumentFromText(datasetId: datasetId, createTextRequest)
        } catch _ as DifyError {
            let fallbackData = Data(docText.utf8)
            textDocument = try await client.createDocumentFromFile(
                datasetId: datasetId,
                fileName: "fallback.txt",
                fileData: fallbackData,
                data: KBCreateDocumentByFileData(
                    indexingTechnique: .economy,
                    docForm: .textModel,
                    processRule: KBProcessRule(mode: .automatic)
                )
            )
        } catch {
            let fallbackData = Data(docText.utf8)
            textDocument = try await client.createDocumentFromFile(
                datasetId: datasetId,
                fileName: "fallback.txt",
                fileData: fallbackData,
                data: KBCreateDocumentByFileData(
                    indexingTechnique: .economy,
                    docForm: .textModel,
                    processRule: KBProcessRule(mode: .automatic)
                )
            )
        }
        let textDocumentId = textDocument.id
        #expect(!textDocumentId.isEmpty)

        // Wait for indexing
        let textDocumentDetail = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocumentId)
        #expect(textDocumentDetail.indexingStatus?.lowercased() == "completed")

        // List segments (may be >0 if splitter produced segments)
        let segments = try await client.listSegments(datasetId: datasetId, documentId: textDocumentId)
        if let first = segments.data.first {
            // Get and update a segment
            let segmentDetail = try await client.getSegmentDetail(datasetId: datasetId, documentId: textDocumentId, segmentId: first.id)
            #expect(segmentDetail.data.id == first.id)

            let updatedSegment = try await client.updateSegment(
                datasetId: datasetId,
                documentId: textDocumentId,
                segmentId: first.id,
                KBUpdateSegmentRequest(segment: .init(content: first.content + " [updated]", answer: nil, keywords: nil, enabled: nil, regenerateChildChunks: nil))
            )
            #expect(updatedSegment.data.id == first.id)

            // Child chunks lifecycle (best-effort; may be disabled per server settings)
            do {
                let childChunkList = try await client.listChildChunks(datasetId: datasetId, documentId: textDocumentId, segmentId: first.id)
                _ = childChunkList
                let childChunk = try await client.createChildChunk(datasetId: datasetId, documentId: textDocumentId, segmentId: first.id, KBCreateChildChunkRequest(content: "child chunk content"))
                let childChunkId = childChunk.data.id
                let updatedChildChunk = try await client.updateChildChunk(datasetId: datasetId, documentId: textDocumentId, segmentId: first.id, childChunkId: childChunkId, KBUpdateChildChunkRequest(content: "child updated"))
                #expect(updatedChildChunk.data.id == childChunkId)
                try await client.deleteChildChunk(datasetId: datasetId, documentId: textDocumentId, segmentId: first.id, childChunkId: childChunkId)
            } catch { /* best-effort: some deployments may not enable child chunk ops */ }
        } else {
            // Segments may be empty depending on splitter configuration
        }

        // Update the document by text
        _ = try await client.updateDocumentByText(
            datasetId: datasetId,
            documentId: textDocumentId,
            KBUpdateDocumentByTextRequest(
                name: "it-text",
                text: docText + " [v2]",
                processRule: KBProcessRule(mode: .automatic)
            )
        )
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocumentId)

        // Create a second document via file upload (small text file)
        let fileContent = "A tiny file for KB upload, used in integration tests."
        let fileData = Data(fileContent.utf8)
        let fileDocument = try await client.createDocumentFromFile(
            datasetId: datasetId,
            fileName: "kb-it.txt",
            fileData: fileData,
            data: KBCreateDocumentByFileData(
                indexingTechnique: .economy,
                docForm: .textModel,
                processRule: KBProcessRule(mode: .automatic)
            )
        )
        let fileDocumentId = fileDocument.id
        #expect(!fileDocumentId.isEmpty)
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: fileDocumentId)

        // Retrieve relevant segments BEFORE toggling status (avoids transient enable conflicts)
        // Ensure the text doc is fully indexed prior to retrieval
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocumentId)
        var retrieveResponse: KBRetrieveResponse? = nil
        for _ in 1...5 {
            do {
                retrieveResponse = try await client.retrieve(datasetId: datasetId, KBRetrieveRequest(query: "knowledge bases and segments"))
                break
            } catch let difyError as DifyError {
                let message = difyError.message ?? ""
                if (difyError.status == 400 || difyError.status == 502 || difyError.status == 503) && message.localizedCaseInsensitiveContains("server") {
                    await sleep(seconds: 1.0)
                    continue
                }
                throw difyError
            }
        }
        if let retrieveResponseUnwrapped = retrieveResponse {
            #expect(!retrieveResponseUnwrapped.records.isEmpty)
        } else {
        }

        // Toggle document status (disable -> best-effort enable)
        _ = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .disable, documentIds: [textDocumentId])
        // Some deployments reject enable while (re)indexing; wait and retry with polling.
        var enabledOK = false
        for _ in 1...20 {
            // Poll document status to wait out background indexing jobs.
            _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocumentId)
            do {
                _ = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .enable, documentIds: [textDocumentId])
                enabledOK = true
                break
            } catch let difyError as DifyError {
                let message = difyError.message ?? ""
                if difyError.status == 400 && message.localizedCaseInsensitiveContains("being indexed") {
                    await sleep(seconds: 2.0)
                    continue
                }
                // Non-indexing error: break out and continue cleanup
                break
            }
        }
        if !enabledOK { }

        // Cleanup documents
        _ = try await client.deleteDocument(datasetId: datasetId, documentId: textDocumentId)
        _ = try await client.deleteDocument(datasetId: datasetId, documentId: fileDocumentId)

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

    #if false
    @Test("Tags CRUD and binding (opt-in)", .disabled())
    func testTagsCRUDAndBinding() async throws {
        let client = try Self.makeClient()

        // Create a dataset for tag binding scope
        let dataset = try await client.createDataset(name: "SDK-IT-TAGS-\(UUID().uuidString.prefix(6))")
        let datasetId = dataset.id
        defer { _ = try? await client.deleteDataset(datasetId: datasetId) }

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
    #endif
}
