
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Base client for interacting with the Dify API. It handles authentication, request signing, and basic network communication.
/// Specialized clients like `ChatClient` or `CompletionClient` should inherit from this class.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
open class DifyClient: @unchecked Sendable {
    
    // MARK: - Properties
    
    public let apiKey: String
    public let baseURL: URL
    private let session: URLSession
    
    // MARK: - Initialization
    
    /// Initializes a new Dify client.
    /// - Parameters:
    ///   - apiKey: Your Dify API key.
    ///   - baseURL: The base URL for the Dify API (e.g., "https://api.dify.ai/v1").
    ///   - session: The URLSession to use for network requests. Defaults to `URLSession.shared`.
    public init(apiKey: String, baseURL: String = "https://api.dify.ai/v1", session: URLSession = .shared) throws {
        guard !apiKey.isEmpty else {
            throw DifyError.invalidAPIKey()
        }
        
        guard let url = URL(string: baseURL), url.scheme != nil else {
            throw DifyError.invalidURL()
        }
        
        self.apiKey = apiKey
        self.baseURL = url
        self.session = session
    }
    
    // MARK: - Internal Request Handling
    
    /// Creates a `URLRequest` for a given API endpoint.
    internal func createURLRequest(method: HTTPMethod, endpoint: String, params: [String: String]? = nil, body: (any Codable)? = nil, multipart: MultipartFormData? = nil) throws -> URLRequest {
        var url = baseURL.appendingPathComponent(endpoint)
        if let params, !params.isEmpty {
            url = url.appendingQueryParameters(params)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try JSONEncoder.difyEncoder.encode(body)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        } else if let multipart {
            let (headers, body) = multipart.build()
            request.httpBody = body
            for (header, value) in headers {
                request.setValue(value, forHTTPHeaderField: header)
            }
        }
        
        return request
    }

    /// Sends a standard (non-streaming) request and returns the raw `Data`.
    internal func sendRequest(method: HTTPMethod, endpoint: String, params: [String: String]? = nil, body: (any Codable)? = nil) async throws -> Data {
        let request = try createURLRequest(method: method, endpoint: endpoint, params: params, body: body)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse()
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let error = try? decode(data, to: DifyError.self)
            throw DifyError.httpError(httpResponse.statusCode, error?.message ?? "Unknown API error")
        }
        
        return data
    }

    /// Sends a multipart request and returns the raw `Data`.
    internal func sendMultipartRequest(method: HTTPMethod, endpoint: String, multipart: MultipartFormData) async throws -> Data {
        let request = try createURLRequest(method: method, endpoint: endpoint, multipart: multipart)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse()
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let error = try? decode(data, to: DifyError.self)
            throw DifyError.httpError(httpResponse.statusCode, error?.message ?? "Unknown API error")
        }
        
        return data
    }

    /// Creates an `AsyncThrowingStream` for a streaming API endpoint.
    internal func createStreamingResponse<T: Decodable>(for request: URLRequest) async throws -> AsyncThrowingStream<T, Error> {
        let (bytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse()
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            // Attempt to read the error body for more details
            var errorBody = ""
            for try await byte in bytes {
                errorBody.append(String(UnicodeScalar(byte)))
            }
            throw DifyError.httpError(httpResponse.statusCode, errorBody)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonData = Data(line.dropFirst(6).utf8)
                            do {
                                let decodedObject = try self.decode(jsonData, to: T.self)
                                continuation.yield(decodedObject)
                            } catch {
                                // Try to decode a DifyError if object decoding fails
                                if let difyError = try? self.decode(jsonData, to: DifyError.self) {
                                    continuation.finish(throwing: difyError)
                                    return
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Decodes JSON data into a specified `Codable` type.
    internal func decode<T: Decodable>(_ data: Data, to type: T.Type) throws -> T {
        do {
            return try JSONDecoder.difyDecoder.decode(type, from: data)
        } catch {
            throw DifyError.decodingError(error)
        }
    }
}
