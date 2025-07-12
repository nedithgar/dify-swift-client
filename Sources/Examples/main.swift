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
        await streamingChatExample(apiKey: apiKey)
        await completionExample(apiKey: apiKey)
        await streamingCompletionExample(apiKey: apiKey)
        await workflowExample(apiKey: apiKey)
        await streamingWorkflowExample(apiKey: apiKey)
        await knowledgeBaseExample(apiKey: apiKey)
        await fileUploadExample(apiKey: apiKey)
        await conversationManagementExample(apiKey: apiKey)
        await messageFeedbackExample(apiKey: apiKey)
    }
    
    static func basicChatExample(apiKey: String) async {
        print("\n💬 Basic Chat Example")
        print("----------------------")
        
        do {
            let chatClient = try ChatClient(apiKey: apiKey)
            
            let response = try await chatClient.createChatMessage(
                inputs: [:],
                query: "Hello! What can you help me with?",
                user: "example_user",
                responseMode: .blocking
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
    
    static func streamingChatExample(apiKey: String) async {
        print("\n🌊 Streaming Chat Example")
        print("--------------------------")
        
        do {
            let chatClient = try ChatClient(apiKey: apiKey)
            
            let stream = try await chatClient.createChatMessage(
                inputs: [:],
                query: "Write a short story about a robot learning to paint.",
                user: "example_user",
                responseMode: .streaming
            )
            
            print("✅ Streaming Response:")
            for try await event in stream {
                switch event {
                case .message(let messageEvent):
                    print("   [Message] \(messageEvent.answer)", terminator: "")
                case .messageDelta(let deltaEvent):
                    print(deltaEvent.answer, terminator: "")
                case .messageEnd(let endEvent):
                    print("\n   [End] Message ID: \(endEvent.id)")
                    print("   Conversation ID: \(endEvent.conversationId)")
                    print("   Total Tokens: \(endEvent.metadata.usage.totalTokens)")
                default:
                    break
                }
            }
            
        } catch {
            print("❌ Streaming Chat Example Error: \(error)")
        }
    }
    
    static func streamingCompletionExample(apiKey: String) async {
        print("\n🌊 Streaming Completion Example")
        print("--------------------------------")
        
        do {
            let completionClient = try CompletionClient(apiKey: apiKey)
            
            let stream = try await completionClient.createCompletionMessage(
                inputs: ["topic": "quantum computing"],
                responseMode: .streaming,
                user: "example_user"
            )
            
            print("✅ Streaming Response:")
            for try await event in stream {
                switch event {
                case .message(let messageEvent):
                    print("   [Message] \(messageEvent.answer)", terminator: "")
                case .messageDelta(let deltaEvent):
                    print(deltaEvent.answer, terminator: "")
                case .messageEnd(let endEvent):
                    print("\n   [End] Total Tokens: \(endEvent.metadata.usage.totalTokens)")
                default:
                    break
                }
            }
            
        } catch {
            print("❌ Streaming Completion Example Error: \(error)")
        }
    }
    
    static func streamingWorkflowExample(apiKey: String) async {
        print("\n⚡ Streaming Workflow Example")
        print("-----------------------------")
        
        do {
            let workflowClient = try WorkflowClient(apiKey: apiKey)
            
            let stream = try await workflowClient.run(
                inputs: ["task": "analyze sentiment", "text": "I love this product!"],
                responseMode: .streaming,
                user: "example_user"
            )
            
            print("✅ Streaming Workflow Events:")
            for try await event in stream {
                switch event {
                case .workflowStarted(let startEvent):
                    print("   [Started] Workflow Run ID: \(startEvent.workflowRunId)")
                    print("   Task ID: \(startEvent.taskId)")
                case .nodeStarted(let nodeEvent):
                    print("   [Node Started] \(nodeEvent.nodeId) - \(nodeEvent.nodeType)")
                case .nodeFinished(let nodeEvent):
                    print("   [Node Finished] \(nodeEvent.nodeId)")
                    if !nodeEvent.outputs.isEmpty {
                        print("     Outputs: \(nodeEvent.outputs)")
                    }
                case .workflowFinished(let finishEvent):
                    print("   [Finished] Status: \(finishEvent.data.status)")
                    print("   Total Steps: \(finishEvent.data.totalSteps)")
                    print("   Total Tokens: \(finishEvent.data.totalTokens)")
                    print("   Final Outputs: \(finishEvent.data.outputs)")
                default:
                    break
                }
            }
            
        } catch {
            print("❌ Streaming Workflow Example Error: \(error)")
        }
    }
    
    static func conversationManagementExample(apiKey: String) async {
        print("\n💬 Conversation Management Example")
        print("-----------------------------------")
        
        do {
            let chatClient = try ChatClient(apiKey: apiKey)
            
            // Create a conversation
            let response = try await chatClient.createChatMessage(
                inputs: [:],
                query: "Let's start a conversation about Swift programming.",
                user: "example_user",
                responseMode: .blocking
            )
            
            let conversationId = response.conversationId
            print("✅ Created conversation: \(conversationId)")
            
            // Continue the conversation
            let followUp = try await chatClient.createChatMessage(
                inputs: [:],
                query: "What are the key features of Swift 6?",
                user: "example_user",
                responseMode: .blocking,
                conversationId: conversationId
            )
            print("✅ Follow-up message sent")
            
            // List conversations
            let conversations = try await chatClient.getConversations(
                user: "example_user",
                limit: 5
            )
            print("✅ Total conversations: \(conversations.data.count)")
            for conv in conversations.data.prefix(3) {
                print("   - \(conv.id): \(conv.name) (\(conv.messageCount) messages)")
            }
            
            // Get conversation messages
            let messages = try await chatClient.getConversationMessages(
                user: "example_user",
                conversationId: conversationId
            )
            print("✅ Messages in conversation: \(messages.data.count)")
            
            // Rename conversation
            let renamed = try await chatClient.renameConversation(
                user: "example_user",
                conversationId: conversationId,
                name: "Swift Programming Discussion"
            )
            print("✅ Conversation renamed to: \(renamed.name)")
            
            // Delete conversation (commented out to preserve example data)
            // try await chatClient.deleteConversation(
            //     user: "example_user",
            //     conversationId: conversationId
            // )
            // print("✅ Conversation deleted")
            
        } catch {
            print("❌ Conversation Management Example Error: \(error)")
        }
    }
    
    static func messageFeedbackExample(apiKey: String) async {
        print("\n👍 Message Feedback Example")
        print("----------------------------")
        
        do {
            let chatClient = try ChatClient(apiKey: apiKey)
            
            // Create a message to provide feedback on
            let response = try await chatClient.createChatMessage(
                inputs: [:],
                query: "What is the capital of France?",
                user: "example_user",
                responseMode: .blocking
            )
            
            print("✅ Chat Response: \(response.answer)")
            print("   Message ID: \(response.messageId)")
            
            // Provide feedback
            let feedback = try await chatClient.messageFeedback(
                user: "example_user",
                messageId: response.messageId,
                rating: .like
            )
            print("✅ Feedback submitted: \(feedback.result)")
            
            // Get message details with feedback
            let messages = try await chatClient.getConversationMessages(
                user: "example_user",
                conversationId: response.conversationId
            )
            
            if let message = messages.data.first(where: { $0.id == response.messageId }) {
                print("✅ Message feedback status: \(message.feedbacks?.first?.rating ?? "none")")
            }
            
        } catch {
            print("❌ Message Feedback Example Error: \(error)")
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
                type: .document,
                transferMethod: .localFile,
                uploadFileId: uploadResponse.id
            )]
            
            let response = try await chatClient.createChatMessage(
                inputs: [:],
                query: "Please summarize the content of the uploaded file.",
                user: "example_user",
                responseMode: .blocking,
                files: files
            )
            
            print("✅ Chat response using file: \(response.answer)")
            
        } catch {
            print("❌ File Upload Example Error: \(error)")
        }
    }
}