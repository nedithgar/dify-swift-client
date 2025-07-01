import DifySwiftClient
import Foundation

@main
struct Examples {
    static func main() async throws {
        // Note: Replace with your actual API key
        let apiKey = "your_api_key_here"
        
        print("🚀 Dify Swift Client Examples")
        print("============================")
        
        await basicChatExample(apiKey: apiKey)
        await completionExample(apiKey: apiKey)
        await workflowExample(apiKey: apiKey)
        await knowledgeBaseExample(apiKey: apiKey)
        await fileUploadExample(apiKey: apiKey)
    }
    
    static func basicChatExample(apiKey: String) async {
        print("\n💬 Basic Chat Example")
        print("----------------------")
        
        do {
            let chatClient = try ChatClient(apiKey: apiKey)
            
            let response = try await chatClient.createChatMessage(
                inputs: [:],
                query: "Hello! What can you help me with?",
                user: "example_user"
            )
            
            print("✅ Chat Response: \(response.answer)")
            print("   Message ID: \(response.messageId)")
            print("   Conversation ID: \(response.conversationId)")
            
        } catch {
            print("❌ Chat Example Error: \(error)")
        }
    }
    
    static func completionExample(apiKey: String) async {
        print("\n🎯 Completion Example")
        print("----------------------")
        
        do {
            let completionClient = try CompletionClient(apiKey: apiKey)
            
            let response = try await completionClient.createCompletionMessage(
                inputs: ["query": "Explain the concept of recursion in programming"],
                responseMode: .blocking,
                user: "example_user"
            )
            
            print("✅ Completion Response: \(response.answer)")
            print("   Message ID: \(response.messageId)")
            
        } catch {
            print("❌ Completion Example Error: \(error)")
        }
    }
    
    static func workflowExample(apiKey: String) async {
        print("\n⚡ Workflow Example")
        print("-------------------")
        
        do {
            let workflowClient = try WorkflowClient(apiKey: apiKey)
            
            let response = try await workflowClient.run(
                inputs: ["topic": "artificial intelligence", "length": "short"],
                responseMode: .blocking,
                user: "example_user"
            )
            
            print("✅ Workflow Response:")
            print("   Run ID: \(response.workflowRunId)")
            print("   Task ID: \(response.taskId)")
            print("   Status: \(response.data.status)")
            print("   Outputs: \(response.data.outputs)")
            
        } catch {
            print("❌ Workflow Example Error: \(error)")
        }
    }
    
    static func knowledgeBaseExample(apiKey: String) async {
        print("\n📚 Knowledge Base Example")
        print("--------------------------")
        
        do {
            // Create a new dataset
            let kbClient = try KnowledgeBaseClient(apiKey: apiKey)
            
            let dataset = try await kbClient.createDataset(name: "Example Dataset")
            print("✅ Created Dataset: \(dataset.name) (ID: \(dataset.id))")
            
            // Create client with the dataset
            let datasetClient = try KnowledgeBaseClient(
                apiKey: apiKey,
                datasetId: dataset.id
            )
            
            // Add a document
            let document = try await datasetClient.createDocumentByText(
                name: "Swift Programming Guide",
                text: """
                Swift is a powerful and intuitive programming language for iOS, macOS, watchOS, and tvOS.
                It's designed to give developers more freedom than ever. Swift is easy to use and open source.
                """
            )
            
            print("✅ Created Document: \(document.document.name) (ID: \(document.document.id))")
            
            // List documents
            let documents = try await datasetClient.listDocuments()
            print("✅ Total Documents: \(documents.total)")
            
            // Add segments
            let segments = [
                SegmentData(
                    content: "Swift is a programming language developed by Apple.",
                    keywords: ["Swift", "Apple", "programming"]
                )
            ]
            
            let segmentResponse = try await datasetClient.addSegments(
                documentId: document.document.id,
                segments: segments
            )
            
            print("✅ Added \(segmentResponse.data.count) segments")
            
        } catch {
            print("❌ Knowledge Base Example Error: \(error)")
        }
    }
    
    static func fileUploadExample(apiKey: String) async {
        print("\n📁 File Upload Example")
        print("-----------------------")
        
        do {
            let client = try DifyClient(apiKey: apiKey)
            
            // Create sample file data
            let sampleText = "This is a sample file for testing upload functionality."
            let fileData = sampleText.data(using: .utf8)!
            
            let uploadResponse = try await client.uploadFile(
                user: "example_user",
                fileData: fileData,
                filename: "sample.txt",
                mimeType: "text/plain"
            )
            
            print("✅ File Uploaded:")
            print("   File ID: \(uploadResponse.id)")
            print("   Filename: \(uploadResponse.name)")
            print("   Size: \(uploadResponse.size) bytes")
            print("   Extension: \(uploadResponse.fileExtension)")
            
            // Use the uploaded file in a chat
            let chatClient = try ChatClient(apiKey: apiKey)
            let files = [APIFile(
                type: .image, // Note: for demo purposes, normally would be appropriate type
                transferMethod: .localFile,
                uploadFileId: uploadResponse.id
            )]
            
            // This would work with an actual image file
            // let response = try await chatClient.createChatMessage(
            //     inputs: [:],
            //     query: "What do you see in this file?",
            //     user: "example_user",
            //     files: files
            // )
            
            print("✅ File ready for use in chat with ID: \(uploadResponse.id)")
            
        } catch {
            print("❌ File Upload Example Error: \(error)")
        }
    }
}