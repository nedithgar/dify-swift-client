import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Debug Logger

/// Lightweight debug logger.
enum DifySDKDebug {
    // MARK: Gate is removed; keep the flag for potential future use.
    // TODO: Make this configurable via environment or build settings.
    static let enabled: Bool = true

    static func log(_ message: String) {
        print("[DifySwiftClient][DEBUG] \(message)")
    }

    static func dump(_ data: Data, limit: Int = 256) -> String {
        if data.isEmpty { return "<empty>" }
        let prefix = String(data: data.prefix(limit), encoding: .utf8) ?? "<non-utf8>"
        let more = data.count > limit ? "… (\(data.count) bytes total)" : ""
        return prefix + more
    }

    static func sanitizeHeaders(_ headers: [AnyHashable: Any]) -> [String: String] {
        var sanitized: [String: String] = [:]
        for (kAny, vAny) in headers {
            let k = String(describing: kAny)
            var v = String(describing: vAny)
            if k.lowercased() == "authorization" {
                v = "Bearer ****"
            }
            sanitized[k] = v
        }
        return sanitized
    }
}

// MARK: - Errors

/// Errors that can occur when using the Dify client.
///
/// This type mirrors the general error envelope returned by Dify's HTTP APIs.
/// In addition to being thrown internally it is also `Decodable` so a server
/// JSON error payload (even when delivered as a 200 in certain streaming edge
/// cases) can be surfaced to SDK consumers in a uniform way.
///
/// Factory helpers (static closures) are provided for common client‑side
/// construction scenarios so that error message text stays consistent.
public struct DifyError: Error, LocalizedError, Decodable, Sendable {
    public let message: String?
    public let code: String?
    public let status: Int?

    enum CodingKeys: String, CodingKey {
        case message, code, status
    }
    
    init(message: String, code: String? = nil, status: Int? = nil) {
        self.message = message
        self.code = code
        self.status = status
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.code = try container.decodeIfPresent(String.self, forKey: .code)
        self.status = try container.decodeIfPresent(Int.self, forKey: .status)
    }

    public var errorDescription: String? {
        return "Dify API Error: \(message ?? "Unknown error") (Code: \(code ?? "N/A"), Status: \(status ?? 0))"
    }

    /// Constructed when a URL cannot be formed from provided inputs.
    static let invalidURL: @Sendable () -> DifyError = { DifyError(message: "Invalid URL provided.") }
    /// Constructed when the server returned no body data where one was expected.
    static let noData: @Sendable () -> DifyError = { DifyError(message: "No data received from the server.") }
    /// Wraps an underlying decoding failure explicitly preserving the original message.
    static let decodingError: @Sendable (Error) -> DifyError = { (error: Error) in DifyError(message: "Failed to decode response: \(error.localizedDescription)") }
    /// Represents a non‑2xx HTTP status code response.
    static let httpError: @Sendable (Int, String?) -> DifyError = { (statusCode: Int, message: String?) in DifyError(message: "HTTP error: \(message ?? "Unknown")", status: statusCode) }
    /// Represents a transport / networking failure surfaced by `URLSession`.
    static let networkError: @Sendable (Error) -> DifyError = { (error: Error) in DifyError(message: "Network error: \(error.localizedDescription)") }
    /// Constructed when a response object shape is unexpected or cannot be validated.
    static let invalidResponse: @Sendable () -> DifyError = { DifyError(message: "Invalid response from the server.") }
    /// Raised when a referenced local file path does not exist.
    static let fileNotFound: @Sendable (String) -> DifyError = { (path: String) in DifyError(message: "File not found at path: \(path)") }
    /// Raised when the configured API key is absent or rejected.
    static let invalidAPIKey: @Sendable () -> DifyError = { DifyError(message: "Invalid API key provided.") }
    /// Raised when a dataset identifier is required for an operation but was not supplied.
    static let missingDatasetId: @Sendable () -> DifyError = { DifyError(message: "Dataset ID is required for this operation.") }
}


// MARK: - HTTP Method

/// HTTP methods for API requests (subset used by Dify endpoints).
///
/// These raw values map directly to the string verb placed in the `URLRequest`.
public enum HTTPMethod: String {
    /// Retrieve a resource (no side effects).
    case GET
    /// Create a resource / initiate an action.
    case POST
    /// Full update / replacement of a resource.
    case PUT
    /// Delete a resource.
    case DELETE
    /// Partial update / patch of a resource.
    case PATCH
}

// MARK: - URL Extension

extension URL {
    /// Returns a new URL by appending the given dictionary of query parameters.
    /// Existing query items are preserved and new ones are appended (not deduplicated).
    /// - Parameter parameters: Key/Value pairs to append. Values are **not** percent‑escaped beyond what `URLComponents` applies.
    /// - Returns: A new URL if composition succeeds, otherwise `self`.
    func appendingQueryParameters(_ parameters: [String: String]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url ?? self
    }
}

// MARK: - JSON Coders

extension JSONDecoder {
    /// Shared JSON decoder configured for Dify response formats.
    ///
    /// Date values returned by the API are numeric UNIX epoch seconds. Using
    /// a static instance avoids reconfiguration overhead for each request.
    static let difyDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}

extension JSONEncoder {
    /// Shared JSON encoder mirroring `difyDecoder` configuration for symmetry
    /// when the SDK needs to serialize request payloads containing dates.
    static let difyEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}

// MARK: - MultipartFormData

/// A helper class to build `multipart/form-data` request bodies.
public class MultipartFormData {
    /// Plain key/value text fields to be serialized.
    private var fields: [String: String] = [:]
    /// File parts appended in the order added (ordering can matter for certain servers).
    private var files: [(name: String, fileName: String, data: Data, mimeType: String)] = []
    
    /// Create an empty multipart accumulator.
    public init() {}
    
    /// Adds a text field to the form data.
    /// - Parameters:
    ///   - name: Name of the form part ("name" attribute in Content-Disposition).
    ///   - value: Raw string value (UTF‑8 encoded).
    public func addTextField(named name: String, value: String) {
        fields[name] = value
    }
    
    /// Adds a file part to the form data.
    /// - Parameters:
    ///   - name: Name of the form part.
    ///   - fileName: File name reported to the server.
    ///   - data: Raw binary file contents.
    ///   - mimeType: MIME type (e.g. "image/png").
    public func addFileField(named name: String, fileName: String, data: Data, mimeType: String) {
        files.append((name, fileName, data, mimeType))}
    
    /// Builds the final multipart body and headers.
    /// - Returns: A `(headers, body)` tuple. Include `headers` in your `URLRequest`.
    /// - Note: A random boundary is generated per build call; don't call again after starting an upload.
    public func build() -> (headers: [String: String], body: Data) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        for (name, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        for file in files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n")
            body.append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        
        let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        return (headers, body)
    }
}

// MARK: - Data Extension

extension Data {
    /// Appends a UTF‑8 representation of the provided string to the data buffer.
    /// If the string cannot be represented in UTF‑8 nothing is appended.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
