
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Base client for interacting with the Dify API.
///
/// Responsibilities:
/// - Stores API credentials and base URL.
/// - Constructs and signs HTTP requests (Bearer token auth).
/// - Provides JSON + multipart request helpers.
/// - Centralizes error normalization (status code handling, decoding errors).
/// - Implements streaming response handling with automatic adaptation for test environments / Linux.
///
/// Subclassing:
/// Concrete domain clients (e.g. `ChatClient`, `CompletionClient`, `WorkflowClient`) inherit from
/// `DifyClient` to gain shared networking behavior. They should remain thin, focusing on shaping
/// request/response payload models.
///
/// Concurrency:
/// The class is marked `@unchecked Sendable` because `URLSession` is not formally `Sendable` in all
/// deployment targets. Public API usage is async and individual requests are independent; using a
/// dedicated `URLSession` instance or the shared session concurrently across tasks is acceptable.
///
/// Error Model:
/// Methods throw `DifyError` for known failure cases (invalid API key/URL, HTTP error responses,
/// JSON decoding issues). Unexpected underlying `URLSession` errors are surfaced directly via
/// `DifyError` factory helpers inside callers.
///
/// Streaming Strategy:
/// - On Apple platforms (non-Linux) and non-test environments, uses `URLSession.bytes` for truly
///   incremental processing of SSE lines.
/// - In unit tests (detected by presence of the custom `MockURLProtocol`) and on Linux, falls back
///   to a single buffered `data(for:)` request which is then parsed line-by-line, enabling easier
///   deterministic mocks.
///
/// Extensibility Tips:
/// - Prefer adding new high-level endpoint methods in subclasses.
/// - Keep this type focused on cross-cutting infrastructure concerns (auth, transport, decoding).
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
open class DifyClient: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// The API key used for Bearer authentication. Must be non-empty.
    public let apiKey: String
    /// The resolved base URL for the API (validated during initialization).
    public let baseURL: URL
    /// The `URLSession` used for all network tasks (inject custom session for testing / metrics / caching).
    internal var session: URLSession
    
    // MARK: - Initialization
    
    /// Initializes a new Dify client.
    ///
    /// - Parameters:
    ///   - apiKey: Your Dify API key (required, non-empty).
    ///   - baseURL: Root REST endpoint (defaults to the production Dify API). May include version path.
    ///   - session: Custom `URLSession` to control caching, timeout policies, or to enable protocol
    ///              injection for tests. Defaults to `.shared`.
    /// - Throws: `DifyError.invalidAPIKey()` if `apiKey` is blank; `DifyError.invalidURL()` if
    ///           `baseURL` cannot be parsed or lacks a scheme.
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
    ///
    /// Applies query parameters (if provided), sets HTTP method, attaches Authorization header and
    /// encodes either JSON or multipart body (mutually exclusive—`multipart` takes precedence when
    /// both parameters are non-nil). JSON bodies use a custom-configured `JSONEncoder` via
    /// `JSONEncoder.difyEncoder`.
    ///
    /// - Parameters:
    ///   - method: HTTP verb (`GET`, `POST`, etc.).
    ///   - endpoint: Relative path (should not start with the base host; leading slash optional but
    ///               recommended for clarity).
    ///   - params: Optional query string key/value pairs (unsafely unescaped values should already
    ///             be encoded if necessary).
    ///   - body: Optional `Codable` payload encoded as JSON if provided.
    ///   - multipart: Optional multipart form container; overrides JSON body if present.
    /// - Returns: A fully prepared `URLRequest` (no network I/O performed).
    /// - Throws: Encoding errors when serializing `body`.
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
        
        // Debug: outbound request snapshot
        if DifySDKDebug.enabled {
            let headers = request.allHTTPHeaderFields ?? [:]
            let sanitized = DifySDKDebug.sanitizeHeaders(headers)
            let bodyInfo: String
            if let bodyData = request.httpBody { bodyInfo = "(\(bodyData.count) bytes) \(DifySDKDebug.dump(bodyData))" } else { bodyInfo = "<none>" }
            DifySDKDebug.log("-> \(method.rawValue) \(url.absoluteString)\n   headers: \(sanitized)\n   body: \(bodyInfo)")
        }
        
        return request
    }

    /// Sends a standard (non-streaming) request and returns the raw response `Data`.
    ///
    /// Successful (2xx) responses are returned verbatim; non-2xx responses attempt to decode a
    /// `DifyError` payload before throwing a wrapped error. Callers are responsible for invoking
    /// `decode(_:to:)` with the expected response model.
    ///
    /// - Parameters:
    ///   - method: HTTP verb.
    ///   - endpoint: API path segment.
    ///   - params: Optional query items.
    ///   - body: Optional JSON encodable payload.
    /// - Returns: Raw response body.
    /// - Throws: `DifyError.invalidResponse()` if no HTTP response, `DifyError.httpError` for
    ///           non-success status codes, encoding errors, or underlying transport errors.
    internal func sendRequest(method: HTTPMethod, endpoint: String, params: [String: String]? = nil, body: (any Codable)? = nil) async throws -> Data {
        let request = try createURLRequest(method: method, endpoint: endpoint, params: params, body: body)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse()
        }
        
        // Debug: inbound response snapshot
        if DifySDKDebug.enabled {
            let headers = DifySDKDebug.sanitizeHeaders(httpResponse.allHeaderFields)
            DifySDKDebug.log("<- [\(httpResponse.statusCode)] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")\n   headers: \(headers)\n   body: (\(data.count) bytes) \(DifySDKDebug.dump(data))")
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let error = try? decode(data, to: DifyError.self)
            throw DifyError.httpError(httpResponse.statusCode, error?.message ?? "Unknown API error")
        }
        
        return data
    }

    /// Sends a multipart/form-data request and returns the raw response `Data`.
    ///
    /// Error semantics mirror `sendRequest` (JSON variant). Use this for file uploads or endpoints
    /// requiring mixed form fields and binary data.
    ///
    /// - Parameters:
    ///   - method: HTTP verb.
    ///   - endpoint: API path segment.
    ///   - multipart: Constructed multipart payload.
    /// - Returns: Raw response body.
    /// - Throws: `DifyError.invalidResponse`, `DifyError.httpError`, or networking errors.
    internal func sendMultipartRequest(method: HTTPMethod, endpoint: String, multipart: MultipartFormData) async throws -> Data {
        let request = try createURLRequest(method: method, endpoint: endpoint, multipart: multipart)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse()
        }
        
        // Debug: inbound response snapshot (multipart)
        if DifySDKDebug.enabled {
            let headers = DifySDKDebug.sanitizeHeaders(httpResponse.allHeaderFields)
            DifySDKDebug.log("<- [\(httpResponse.statusCode)] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "") (multipart)\n   headers: \(headers)\n   body: (\(data.count) bytes) \(DifySDKDebug.dump(data))")
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let error = try? decode(data, to: DifyError.self)
            throw DifyError.httpError(httpResponse.statusCode, error?.message ?? "Unknown API error")
        }
        
        return data
    }

    /// Creates an `AsyncThrowingStream` representing a Server-Sent Events (SSE) style streaming endpoint.
    ///
    /// Chooses an implementation strategy based on platform & testing context:
    /// - Test (MockURLProtocol detected) or Linux: buffered data task fallback, then parse lines.
    /// - Apple production: incremental `URLSession.bytes` streaming for lower latency.
    ///
    /// - Parameter request: Pre-built request containing correct method, headers and body.
    /// - Returns: A lazily consumed `AsyncThrowingStream` of decoded event objects.
    /// - Throws: Networking errors establishing the connection or initial HTTP validation failures.
    internal func createStreamingResponse<T: Decodable & Sendable>(for request: URLRequest) async throws -> AsyncThrowingStream<T, Error> {
        // Check if we're running in a test environment with MockURLProtocol
        let isTestEnvironment = session.configuration.protocolClasses?.contains { protocolClass in
            NSStringFromClass(protocolClass) == "DifySwiftClientTests.MockURLProtocol"
        } ?? false
        
        if isTestEnvironment {
            // Use data task approach for compatibility with URLProtocol
            return try await createStreamingResponseUsingDataTask(for: request)
        } else {
            // Use the appropriate streaming method based on platform
            #if canImport(FoundationNetworking)
            // Linux doesn't support URLSession.bytes, use data task approach
            return try await createStreamingResponseUsingDataTask(for: request)
            #else
            // Use the modern bytes API for Apple platforms
            return try await createStreamingResponseUsingBytes(for: request)
            #endif
        }
    }
    
    #if !canImport(FoundationNetworking)
    /// Creates streaming response using `URLSession.bytes` (Apple platforms production path).
    ///
    /// Reads SSE lines incrementally, decoding each JSON payload after the `data: ` prefix. Attempts
    /// graceful degradation by checking if a line decodes into `DifyError` when the primary model
    /// decoding fails.
    ///
    /// - Parameter request: Configured streaming request.
    /// - Returns: `AsyncThrowingStream` yielding decoded events.
    /// - Throws: Immediate HTTP response validation errors before stream emission begins.
    private func createStreamingResponseUsingBytes<T: Decodable & Sendable>(for request: URLRequest) async throws -> AsyncThrowingStream<T, Error> {
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
                                if let difyError = try? self.decode(jsonData, to: DifyError.self),
                                   difyError.message != nil || difyError.code != nil || difyError.status != nil {
                                    continuation.finish(throwing: difyError)
                                    return
                                }
                                // Re-throw the original decoding error
                                continuation.finish(throwing: error)
                                return
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
    #endif
    
    /// Creates streaming response using a buffered data task (test & Linux compatibility path).
    ///
    /// The entire payload is downloaded, then split into newline-delimited SSE lines. This approach
    /// trades latency for deterministic behavior in environments where `URLSession.bytes` is
    /// unsupported or incompatible with `URLProtocol` mocking.
    ///
    /// - Parameter request: Configured streaming request.
    /// - Returns: `AsyncThrowingStream` emitting decoded events sequentially.
    /// - Throws: Immediate HTTP validation / network errors prior to building the stream.
    private func createStreamingResponseUsingDataTask<T: Decodable & Sendable>(for request: URLRequest) async throws -> AsyncThrowingStream<T, Error> {
        // First perform the request to get the data
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DifyError.invalidResponse()
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw DifyError.httpError(httpResponse.statusCode, errorBody)
        }
        
        // Parse SSE data and return as stream
        return AsyncThrowingStream { continuation in
            Task {
                let dataString = String(data: data, encoding: .utf8) ?? ""
                let lines = dataString.components(separatedBy: "\n")
                
                for line in lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = String(line.dropFirst(6))
                        let jsonData = Data(jsonString.utf8)
                        do {
                            let decodedObject = try self.decode(jsonData, to: T.self)
                            continuation.yield(decodedObject)
                        } catch {
                            // Try to decode a DifyError if object decoding fails
                            if let difyError = try? self.decode(jsonData, to: DifyError.self),
                               difyError.message != nil || difyError.code != nil || difyError.status != nil {
                                continuation.finish(throwing: difyError)
                                return
                            }
                            // Re-throw the original decoding error
                            continuation.finish(throwing: error)
                            return
                        }
                    }
                }
                
                continuation.finish()
            }
        }
    }
    
    /// Decodes JSON `Data` into a strongly typed model.
    ///
    /// Wraps failures in `DifyError.decodingError` for enriched error context.
    ///
    /// - Parameters:
    ///   - data: Raw JSON bytes.
    ///   - type: Target `Decodable` type.
    /// - Returns: Instance of `T`.
    /// - Throws: `DifyError.decodingError` if decoding fails.
    internal func decode<T: Decodable>(_ data: Data, to type: T.Type) throws -> T {
        // Some Dify endpoints legitimately return 204 No Content (empty body)
        // even when callers expect a trivial acknowledgement payload.
        // Gracefully map empty bodies to a sensible default for lightweight
        // response types we model as `BaseResponse`.
        if data.isEmpty {
            if T.self == BaseResponse.self, let value = BaseResponse(result: "success") as? T {
                return value
            }
        }

        do {
            return try JSONDecoder.difyDecoder.decode(type, from: data)
        } catch {
            // Some deployments return plain scalars like "204" or "OK" for ack endpoints.
            if T.self == BaseResponse.self {
                let scalar = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                if scalar == "ok" || scalar == "success" || scalar == "true" || Int(scalar) != nil {
                    if let value = BaseResponse(result: "success") as? T { return value }
                }
            }
            if DifySDKDebug.enabled {
                DifySDKDebug.log("Decode failed for type=\(T.self) bytes=\(data.count) error=\(error.localizedDescription)\n   body snippet: \(DifySDKDebug.dump(data))")
            }
            throw DifyError.decodingError(error)
        }
    }
}
