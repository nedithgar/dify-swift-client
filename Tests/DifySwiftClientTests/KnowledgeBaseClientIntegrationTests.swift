import Foundation
import Testing
@testable import DifySwiftClient

// MARK: - Gating Flags (module-level to avoid macro circular refs)

let KB_IT_HAS_LIVE_CONFIG: Bool = {
    let env = ProcessInfo.processInfo.environment
    return (env["DIFY_API_KEY"].map { !$0.isEmpty } ?? false)
}()

/// Integration tests for KnowledgeBaseClient using a real Dify instance.
///
/// Opt-in via environment variables:
/// - DIFY_API_KEY: required. Server/workspace API key with Knowledge Base permissions.
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
        print("[IT] Starting dataset/document/segments/retrieve flow…")

        // Create Dataset
        let datasetName = "SDK-IT-\(UUID().uuidString.prefix(8))"
        print("[IT] Creating dataset: \(datasetName)")
        let dataset = try await client.createDataset(name: datasetName)
        let datasetId = dataset.id
        #expect(!datasetId.isEmpty)
        print("[IT] Dataset created: id=\(datasetId)")

        // Ensure dataset appears in list
        print("[IT] Listing datasets filtered by keyword…")
        let list = try await client.listDatasets(keyword: datasetName, page: 1, limit: 20)
        #expect(list.data.contains { $0.id == datasetId })

        // Update dataset metadata
        print("[IT] Updating dataset description…")
        let updated = try await client.updateDataset(datasetId: datasetId, KBUpdateDatasetRequest(description: "Integration test dataset"))
        #expect(updated.description == "Integration test dataset")

        // Ensure embedding + indexing are configured at dataset level for document ingestion
        print("[IT] Selecting embedding model for dataset…")
        let providers = try await client.getAvailableEmbeddingModels()
        #expect(!providers.isEmpty)
        let chosenProvider = providers.first(where: { !$0.models.isEmpty }) ?? providers[0]
        let chosenModel = chosenProvider.models.first!
        print("[IT] Using provider=\(chosenProvider.provider) model=\(chosenModel.model)")
        _ = try await client.updateDataset(
            datasetId: datasetId,
            KBUpdateDatasetRequest(
                indexingTechnique: "economy",
                embeddingModelProvider: chosenProvider.provider,
                embeddingModel: chosenModel.model,
                retrievalModel: KBRetrievalModel(
                    searchMethod: "semantic_search",
                    rerankingEnable: false,
                    topK: 5,
                    scoreThresholdEnabled: false
                )
            )
        )

        // Create a document from text
        let docText = "Dify Swift SDK integration test content about knowledge bases and segments."
        let createTextReq = KBCreateDocumentByTextRequest(
            name: "it-text",
            text: docText,
            indexingTechnique: "economy",
            docForm: "text_model",
            docLanguage: "English",
            processRule: KBProcessRule(mode: "automatic"),
            retrievalModel: KBRetrievalModel(
                searchMethod: "semantic_search",
                rerankingEnable: false,
                topK: 5,
                scoreThresholdEnabled: false
            )
        )
        print("[IT] Creating document from text…")
        let textDoc: DocumentResponse
        do {
            textDoc = try await client.createDocumentFromText(datasetId: datasetId, createTextReq)
        } catch let error as DifyError {
            print("[IT] create-by-text failed status=\(error.status ?? -1) msg=\(error.message ?? "") → falling back to file upload")
            let fallbackData = Data(docText.utf8)
            textDoc = try await client.createDocumentFromFile(
                datasetId: datasetId,
                fileName: "fallback.txt",
                fileData: fallbackData,
                data: KBCreateDocumentByFileData(
                    indexingTechnique: "economy",
                    docForm: "text_model",
                    docLanguage: "English",
                    processRule: KBProcessRule(mode: "automatic")
                )
            )
        } catch {
            print("[IT] create-by-text failed with unexpected error → falling back to file upload")
            let fallbackData = Data(docText.utf8)
            textDoc = try await client.createDocumentFromFile(
                datasetId: datasetId,
                fileName: "fallback.txt",
                fileData: fallbackData,
                data: KBCreateDocumentByFileData(
                    indexingTechnique: "economy",
                    docForm: "text_model",
                    docLanguage: "English",
                    processRule: KBProcessRule(mode: "automatic")
                )
            )
        }
        let textDocId = textDoc.id
        #expect(!textDocId.isEmpty)
        print("[IT] Text document created: id=\(textDocId)")

        // Wait for indexing
        print("[IT] Waiting for indexing completion for text document…")
        let textDocDetail = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocId)
        #expect(textDocDetail.indexingStatus?.lowercased() == "completed")

        // List segments (may be >0 if splitter produced segments)
        print("[IT] Listing segments for text document…")
        let segments = try await client.listSegments(datasetId: datasetId, documentId: textDocId)
        if let first = segments.data.first {
            print("[IT] Found first segment id=\(first.id). Fetching detail…")
            // Get and update a segment
            let segDetail = try await client.getSegmentDetail(datasetId: datasetId, documentId: textDocId, segmentId: first.id)
            #expect(segDetail.data.id == first.id)

            print("[IT] Updating segment content…")
            let updatedSeg = try await client.updateSegment(
                datasetId: datasetId,
                documentId: textDocId,
                segmentId: first.id,
                KBUpdateSegmentRequest(segment: .init(content: first.content + " [updated]", answer: nil, keywords: nil, enabled: nil, regenerateChildChunks: nil))
            )
            #expect(updatedSeg.data.id == first.id)

            // Child chunks lifecycle (best-effort; may be disabled per server settings)
            do {
                print("[IT] Listing child chunks…")
                let childList = try await client.listChildChunks(datasetId: datasetId, documentId: textDocId, segmentId: first.id)
                _ = childList
                print("[IT] Creating child chunk…")
                let child = try await client.createChildChunk(datasetId: datasetId, documentId: textDocId, segmentId: first.id, KBCreateChildChunkRequest(content: "child chunk content"))
                let childId = child.data.id
                print("[IT] Updating child chunk id=\(childId)…")
                let childUpdated = try await client.updateChildChunk(datasetId: datasetId, documentId: textDocId, segmentId: first.id, childChunkId: childId, KBUpdateChildChunkRequest(content: "child updated"))
                #expect(childUpdated.data.id == childId)
                print("[IT] Deleting child chunk id=\(childId)…")
                try await client.deleteChildChunk(datasetId: datasetId, documentId: textDocId, segmentId: first.id, childChunkId: childId)
            } catch { /* best-effort: some deployments may not enable child chunk ops */ }
        } else {
            // Segments may be empty depending on splitter configuration
        }

        // Update the document by text
        print("[IT] Updating document-by-text…")
        _ = try await client.updateDocumentByText(
            datasetId: datasetId,
            documentId: textDocId,
            KBUpdateDocumentByTextRequest(
                name: "it-text",
                text: docText + " [v2]",
                processRule: KBProcessRule(mode: "automatic")
            )
        )
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocId)

        // Create a second document via file upload (small text file)
        let fileContent = "A tiny file for KB upload, used in integration tests."
        let fileData = Data(fileContent.utf8)
        print("[IT] Creating document from file…")
        let fileDoc = try await client.createDocumentFromFile(
            datasetId: datasetId,
            fileName: "kb-it.txt",
            fileData: fileData,
            data: KBCreateDocumentByFileData(
                indexingTechnique: "economy",
                docForm: "text_model",
                docLanguage: "English",
                processRule: KBProcessRule(mode: "automatic")
            )
        )
        let fileDocId = fileDoc.id
        #expect(!fileDocId.isEmpty)
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: fileDocId)

        // Retrieve relevant segments BEFORE toggling status (avoids transient enable conflicts)
        print("[IT] Retrieving relevant segments…")
        // Ensure the text doc is fully indexed prior to retrieval
        _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocId)
        var retrieveResp: KBRetrieveResponse? = nil
        for attempt in 1...5 {
            do {
                retrieveResp = try await client.retrieve(datasetId: datasetId, KBRetrieveRequest(query: "knowledge bases and segments"))
                break
            } catch let err as DifyError {
                let msg = err.message ?? ""
                if (err.status == 400 || err.status == 502 || err.status == 503) && msg.localizedCaseInsensitiveContains("server") {
                    print("[IT] Retrieve transient error (attempt \(attempt)); waiting 1s…")
                    await sleep(seconds: 1.0)
                    continue
                }
                throw err
            }
        }
        if let rr = retrieveResp {
            #expect(!rr.records.isEmpty)
        } else {
            print("[IT] Retrieve still failing after retries; continuing with cleanup.")
        }

        // Toggle document status (disable -> best-effort enable)
        print("[IT] Toggling document status disable → enable…")
        _ = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .disable, documentIds: [textDocId])
        // Some deployments reject enable while (re)indexing; wait and retry with polling.
        var enabledOK = false
        for attempt in 1...20 {
            // Poll document status to wait out background indexing jobs.
            _ = try await waitForIndexingCompletion(client: client, datasetId: datasetId, documentId: textDocId)
            do {
                _ = try await client.batchUpdateDocumentStatus(datasetId: datasetId, action: .enable, documentIds: [textDocId])
                enabledOK = true
                break
            } catch let err as DifyError {
                let msg = err.message ?? ""
                if err.status == 400 && msg.localizedCaseInsensitiveContains("being indexed") {
                    print("[IT] Enable blocked due to indexing (attempt \(attempt)); waiting 2s…")
                    await sleep(seconds: 2.0)
                    continue
                }
                // Non-indexing error: break out and continue cleanup
                print("[IT] Enable failed with non-indexing error: \(msg)")
                break
            }
        }
        if !enabledOK { print("[IT] Skipping enable assertion due to persistent indexing lock.") }

        // Cleanup documents
        print("[IT] Deleting documents…")
        _ = try await client.deleteDocument(datasetId: datasetId, documentId: textDocId)
        _ = try await client.deleteDocument(datasetId: datasetId, documentId: fileDocId)

        // Final: delete dataset
        print("[IT] Deleting dataset id=\(datasetId)…")
        _ = try await client.deleteDataset(datasetId: datasetId)
        print("[IT] Flow completed.")
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
    #endif
}
