import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Errors

/// Errors that can occur when using the Dify client.
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

    static let invalidURL: @Sendable () -> DifyError = { DifyError(message: "Invalid URL provided.") }
    static let noData: @Sendable () -> DifyError = { DifyError(message: "No data received from the server.") }
    static let decodingError: @Sendable (Error) -> DifyError = { (error: Error) in DifyError(message: "Failed to decode response: \(error.localizedDescription)") }
    static let httpError: @Sendable (Int, String?) -> DifyError = { (statusCode: Int, message: String?) in DifyError(message: "HTTP error: \(message ?? "Unknown")", status: statusCode) }
    static let networkError: @Sendable (Error) -> DifyError = { (error: Error) in DifyError(message: "Network error: \(error.localizedDescription)") }
    static let invalidResponse: @Sendable () -> DifyError = { DifyError(message: "Invalid response from the server.") }
    static let fileNotFound: @Sendable (String) -> DifyError = { (path: String) in DifyError(message: "File not found at path: \(path)") }
    static let invalidAPIKey: @Sendable () -> DifyError = { DifyError(message: "Invalid API key provided.") }
    static let missingDatasetId: @Sendable () -> DifyError = { DifyError(message: "Dataset ID is required for this operation.") }
}


// MARK: - HTTP Method

/// HTTP methods for API requests.
public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - URL Extension

extension URL {
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

// MARK: - MultipartFormData

/// A helper class to build `multipart/form-data` request bodies.
public class MultipartFormData {
    private var fields: [String: String] = [:]
    private var files: [(name: String, fileName: String, data: Data, mimeType: String)] = []
    
    public init() {}
    
    /// Adds a text field to the form data.
    public func addTextField(named name: String, value: String) {
        fields[name] = value
    }
    
    /// Adds a file to the form data.
    public func addFileField(named name: String, fileName: String, data: Data, mimeType: String) {
        files.append((name, fileName, data, mimeType))}
    
    /// Builds the final multipart body and headers.
    /// - Returns: A tuple containing the request headers and the body data.
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
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}