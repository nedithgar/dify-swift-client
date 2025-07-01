import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Errors

/// Errors that can occur when using the Dify client
public enum DifyError: Error, LocalizedError {
    case invalidURL(String)
    case noData
    case decodingError(Error)
    case httpError(Int, String?)
    case networkError(Error)
    case invalidResponse
    case fileNotFound(String)
    case invalidAPIKey
    case missingDatasetId
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response format"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidAPIKey:
            return "Invalid API key"
        case .missingDatasetId:
            return "Dataset ID is required but not provided"
        }
    }
}

// MARK: - HTTP Method

/// HTTP methods for API requests
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Streaming Response

/// Protocol for handling streaming responses
public protocol StreamingDelegate: AnyObject {
    func didReceiveData(_ data: Data)
    func didCompleteWithError(_ error: Error?)
}

/// AsyncSequence for streaming responses
public struct StreamingResponse: AsyncSequence {
    public typealias Element = Data
    
    private let urlRequest: URLRequest
    private let session: URLSession
    
    init(urlRequest: URLRequest, session: URLSession = .shared) {
        self.urlRequest = urlRequest
        self.session = session
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(urlRequest: urlRequest, session: session)
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let urlRequest: URLRequest
        private let session: URLSession
        private var task: URLSessionDataTask?
        private var stream: AsyncStream<Data>?
        private var iterator: AsyncStream<Data>.AsyncIterator?
        
        init(urlRequest: URLRequest, session: URLSession) {
            self.urlRequest = urlRequest
            self.session = session
        }
        
        public mutating func next() async throws -> Data? {
            if stream == nil {
                setupStream()
            }
            
            if iterator == nil {
                iterator = stream?.makeAsyncIterator()
            }
            
            return await iterator?.next()
        }
        
        private mutating func setupStream() {
            let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
            self.stream = stream
            
            task = session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.finish()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode >= 400 {
                    continuation.finish()
                    return
                }
                
                if let data = data, !data.isEmpty {
                    continuation.yield(data)
                }
                
                continuation.finish()
            }
            
            task?.resume()
        }
    }
}

// MARK: - Utilities

extension URL {
    func appendingQueryItems(_ queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        
        var existingQueryItems = components.queryItems ?? []
        existingQueryItems.append(contentsOf: queryItems)
        components.queryItems = existingQueryItems
        
        return components.url ?? self
    }
}

extension URLRequest {
    mutating func setJSONBody<T: Encodable>(_ object: T) throws {
        let data = try JSONEncoder().encode(object)
        self.httpBody = data
        self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    mutating func setMultipartBody(parameters: [String: String], fileData: [(key: String, filename: String, data: Data, mimeType: String)]) {
        let boundary = UUID().uuidString
        let boundaryString = "--\(boundary)"
        
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.append("\(boundaryString)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add files
        for fileInfo in fileData {
            body.append("\(boundaryString)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fileInfo.key)\"; filename=\"\(fileInfo.filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(fileInfo.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileInfo.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        self.httpBody = body
        self.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    }
}

extension JSONDecoder {
    static let difyDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}

extension JSONEncoder {
    static let difyEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}