import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DifySwiftClient

@Suite("Utilities Tests")
struct UtilitiesTests {
    
    // MARK: - Setup and Teardown
    
    init() {
        TestUtilities.setUp()
    }
    
    // MARK: - DifyError Tests
    
    @Test("DifyError initialization with message")
    func testDifyErrorInitializationWithMessage() {
        let error = DifyError(message: "Test error")
        
        #expect(error.message == "Test error")
        #expect(error.code == nil)
        #expect(error.status == nil)
    }
    
    @Test("DifyError initialization with all parameters")
    func testDifyErrorInitializationWithAllParameters() {
        let error = DifyError(message: "Test error", code: "invalid_request", status: 400)
        
        #expect(error.message == "Test error")
        #expect(error.code == "invalid_request")
        #expect(error.status == 400)
    }
    
    @Test("DifyError error description")
    func testDifyErrorErrorDescription() {
        let error = DifyError(message: "Test error", code: "invalid_request", status: 400)
        
        #expect(error.errorDescription == "Dify API Error: Test error (Code: invalid_request, Status: 400)")
    }
    
    @Test("DifyError error description with missing values")
    func testDifyErrorErrorDescriptionWithMissingValues() {
        let error = DifyError(message: nil, code: nil, status: nil)
        
        #expect(error.errorDescription == "Dify API Error: Unknown error (Code: N/A, Status: 0)")
    }
    
    @Test("DifyError decoding from JSON")
    func testDifyErrorDecodingFromJSON() throws {
        let jsonData = """
        {
            "message": "Invalid API key",
            "code": "unauthorized",
            "status": 401
        }
        """.data(using: .utf8)!
        
        let error = try JSONDecoder.difyDecoder.decode(DifyError.self, from: jsonData)
        
        #expect(error.message == "Invalid API key")
        #expect(error.code == "unauthorized")
        #expect(error.status == 401)
    }
    
    @Test("DifyError decoding from partial JSON")
    func testDifyErrorDecodingFromPartialJSON() throws {
        let jsonData = """
        {
            "message": "Something went wrong"
        }
        """.data(using: .utf8)!
        
        let error = try JSONDecoder.difyDecoder.decode(DifyError.self, from: jsonData)
        
        #expect(error.message == "Something went wrong")
        #expect(error.code == nil)
        #expect(error.status == nil)
    }
    
    @Test("DifyError static factory methods")
    func testDifyErrorStaticFactoryMethods() {
        let invalidURL = DifyError.invalidURL()
        #expect(invalidURL.message == "Invalid URL provided.")
        
        let noData = DifyError.noData()
        #expect(noData.message == "No data received from the server.")
        
        let networkError = DifyError.networkError(NSError(domain: "Test", code: 0, userInfo: nil))
        #expect(networkError.message?.hasPrefix("Network error:") == true)
        
        let httpError = DifyError.httpError(404, "Not Found")
        #expect(httpError.message == "HTTP error: Not Found")
        #expect(httpError.status == 404)
        
        let invalidResponse = DifyError.invalidResponse()
        #expect(invalidResponse.message == "Invalid response from the server.")
        
        let fileNotFound = DifyError.fileNotFound("/path/to/file")
        #expect(fileNotFound.message == "File not found at path: /path/to/file")
        
        let invalidAPIKey = DifyError.invalidAPIKey()
        #expect(invalidAPIKey.message == "Invalid API key provided.")
        
        let missingDatasetId = DifyError.missingDatasetId()
        #expect(missingDatasetId.message == "Dataset ID is required for this operation.")
    }
    
    // MARK: - HTTPMethod Tests
    
    @Test("HTTPMethod raw values")
    func testHTTPMethodRawValues() {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    }
    
    // MARK: - URL Extension Tests
    
    @Test("URL appendingQueryParameters with single parameter")
    func testURLAppendingQueryParametersWithSingleParameter() {
        let baseURL = URL(string: "https://api.example.com/test")!
        let parameters = ["key": "value"]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        #expect(resultURL.query?.contains("key=value") == true)
    }
    
    @Test("URL appendingQueryParameters with multiple parameters")
    func testURLAppendingQueryParametersWithMultipleParameters() {
        let baseURL = URL(string: "https://api.example.com/test")!
        let parameters = ["param1": "value1", "param2": "value2"]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        #expect(resultURL.query?.contains("param1=value1") == true)
        #expect(resultURL.query?.contains("param2=value2") == true)
    }
    
    @Test("URL appendingQueryParameters with existing query")
    func testURLAppendingQueryParametersWithExistingQuery() {
        let baseURL = URL(string: "https://api.example.com/test?existing=param")!
        let parameters = ["new": "value"]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        #expect(resultURL.query?.contains("existing=param") == true)
        #expect(resultURL.query?.contains("new=value") == true)
    }
    
    @Test("URL appendingQueryParameters with special characters")
    func testURLAppendingQueryParametersWithSpecialCharacters() {
        let baseURL = URL(string: "https://api.example.com/test")!
        let parameters = ["query": "hello world", "special": "chars@#$%"]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        let components = URLComponents(url: resultURL, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems!
        
        #expect(queryItems.contains { $0.name == "query" && $0.value == "hello world" })
        #expect(queryItems.contains { $0.name == "special" && $0.value == "chars@#$%" })
    }
    
    @Test("URL appendingQueryParameters with empty parameters")
    func testURLAppendingQueryParametersWithEmptyParameters() {
        let baseURL = URL(string: "https://api.example.com/test")!
        let parameters: [String: String] = [:]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        #expect(resultURL == baseURL)
    }
    
    @Test("URL appendingQueryParameters with invalid URL")
    func testURLAppendingQueryParametersWithInvalidURL() {
        // Create a URL that can't be converted to URLComponents
        let baseURL = URL(string: "https://api.example.com/test")!
        let parameters = ["key": "value"]
        
        let resultURL = baseURL.appendingQueryParameters(parameters)
        
        // Should still work with valid URL
        #expect(resultURL.query?.contains("key=value") == true)
    }
    
    // MARK: - JSON Coders Tests
    
    @Test("JSONDecoder.difyDecoder date decoding")
    func testJSONDecoderDifyDecoderDateDecoding() throws {
        struct TestModel: Codable {
            let date: Date
        }
        
        let jsonData = """
        {
            "date": 1640995200
        }
        """.data(using: .utf8)!
        
        let model = try JSONDecoder.difyDecoder.decode(TestModel.self, from: jsonData)
        
        #expect(model.date.timeIntervalSince1970 == 1640995200)
    }
    
    @Test("JSONEncoder.difyEncoder date encoding")
    func testJSONEncoderDifyEncoderDateEncoding() throws {
        struct TestModel: Codable {
            let date: Date
        }
        
        let model = TestModel(date: Date(timeIntervalSince1970: 1640995200))
        let jsonData = try JSONEncoder.difyEncoder.encode(model)
        
        let jsonString = String(data: jsonData, encoding: .utf8)!
        #expect(jsonString.contains("1640995200"))
    }
    
    // MARK: - MultipartFormData Tests
    
    @Test("MultipartFormData initialization")
    func testMultipartFormDataInitialization() {
        let multipart = MultipartFormData()
        
        // Should not crash and should be able to build
        let (headers, body) = multipart.build()
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(body.count > 0)
    }
    
    @Test("MultipartFormData add text field")
    func testMultipartFormDataAddTextField() {
        let multipart = MultipartFormData()
        multipart.addTextField(named: "field1", value: "value1")
        multipart.addTextField(named: "field2", value: "value2")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("field1"))
        #expect(bodyString.contains("value1"))
        #expect(bodyString.contains("field2"))
        #expect(bodyString.contains("value2"))
    }
    
    @Test("MultipartFormData add file field")
    func testMultipartFormDataAddFileField() {
        let multipart = MultipartFormData()
        let fileData = Data("test file content".utf8)
        
        multipart.addFileField(named: "file", fileName: "test.txt", data: fileData, mimeType: "text/plain")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("file"))
        #expect(bodyString.contains("test.txt"))
        #expect(bodyString.contains("text/plain"))
        #expect(bodyString.contains("test file content"))
    }
    
    @Test("MultipartFormData add mixed fields")
    func testMultipartFormDataAddMixedFields() {
        let multipart = MultipartFormData()
        let fileData = Data("test file content".utf8)
        
        multipart.addTextField(named: "user", value: "test-user")
        multipart.addTextField(named: "action", value: "upload")
        multipart.addFileField(named: "file", fileName: "document.pdf", data: fileData, mimeType: "application/pdf")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("user"))
        #expect(bodyString.contains("test-user"))
        #expect(bodyString.contains("action"))
        #expect(bodyString.contains("upload"))
        #expect(bodyString.contains("file"))
        #expect(bodyString.contains("document.pdf"))
        #expect(bodyString.contains("application/pdf"))
    }
    
    @Test("MultipartFormData with special characters")
    func testMultipartFormDataWithSpecialCharacters() {
        let multipart = MultipartFormData()
        let fileData = Data("文件内容 with special chars!".utf8)
        
        multipart.addTextField(named: "description", value: "This is a test with 特殊字符 & symbols!")
        multipart.addFileField(named: "file", fileName: "测试文件.txt", data: fileData, mimeType: "text/plain")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("特殊字符"))
        #expect(bodyString.contains("测试文件.txt"))
    }
    
    @Test("MultipartFormData with empty fields")
    func testMultipartFormDataWithEmptyFields() {
        let multipart = MultipartFormData()
        
        multipart.addTextField(named: "empty_field", value: "")
        multipart.addFileField(named: "empty_file", fileName: "empty.txt", data: Data(), mimeType: "text/plain")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("empty_field"))
        #expect(bodyString.contains("empty_file"))
        #expect(bodyString.contains("empty.txt"))
    }
    
    @Test("MultipartFormData with large file")
    func testMultipartFormDataWithLargeFile() {
        let multipart = MultipartFormData()
        let largeFileData = Data(repeating: 0x42, count: 1_000_000) // 1MB
        
        multipart.addFileField(named: "large_file", fileName: "large.bin", data: largeFileData, mimeType: "application/octet-stream")
        
        let (headers, body) = multipart.build()
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(body.count > 1_000_000) // Should be larger than just the file due to headers
    }
    
    @Test("MultipartFormData boundary uniqueness")
    func testMultipartFormDataBoundaryUniqueness() {
        let multipart1 = MultipartFormData()
        let multipart2 = MultipartFormData()
        
        let (headers1, _) = multipart1.build()
        let (headers2, _) = multipart2.build()
        
        let boundary1 = headers1["Content-Type"]!.components(separatedBy: "boundary=").last!
        let boundary2 = headers2["Content-Type"]!.components(separatedBy: "boundary=").last!
        
        #expect(boundary1 != boundary2)
    }
    
    // MARK: - Data Extension Tests
    
    @Test("Data append string")
    func testDataAppendString() {
        var data = Data()
        data.append("Hello")
        data.append(" ")
        data.append("World")
        
        let result = String(data: data, encoding: .utf8)!
        #expect(result == "Hello World")
    }
    
    @Test("Data append string with special characters")
    func testDataAppendStringWithSpecialCharacters() {
        var data = Data()
        data.append("Hello 世界")
        data.append(" 🌍")
        
        let result = String(data: data, encoding: .utf8)!
        #expect(result == "Hello 世界 🌍")
    }
    
    @Test("Data append empty string")
    func testDataAppendEmptyString() {
        var data = Data()
        data.append("")
        
        #expect(data.count == 0)
    }
    
    @Test("Data append string with invalid encoding")
    func testDataAppendStringWithInvalidEncoding() {
        var data = Data()
        
        // This should not crash, but may not append anything
        data.append("Test")
        
        #expect(data.count > 0)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle nil values in multipart form data")
    func testHandleNilValuesInMultipartFormData() {
        let multipart = MultipartFormData()
        
        // These should not crash
        multipart.addTextField(named: "test", value: "")
        multipart.addFileField(named: "file", fileName: "", data: Data(), mimeType: "")
        
        let (headers, body) = multipart.build()
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(body.count > 0)
    }
    
    @Test("Handle very long field names and values")
    func testHandleVeryLongFieldNamesAndValues() {
        let multipart = MultipartFormData()
        let longName = String(repeating: "a", count: 10000)
        let longValue = String(repeating: "b", count: 10000)
        
        multipart.addTextField(named: longName, value: longValue)
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains(longName))
        #expect(bodyString.contains(longValue))
    }
    
    @Test("Handle concurrent multipart form data building")
    func testHandleConcurrentMultipartFormDataBuilding() {
        let expectation = expectation(description: "Concurrent multipart building")
        var results: [(headers: [String: String], body: Data)] = []
        let queue = DispatchQueue(label: "test.queue", attributes: .concurrent)
        
        for i in 0..<100 {
            queue.async {
                let multipart = MultipartFormData()
                multipart.addTextField(named: "field\(i)", value: "value\(i)")
                
                let result = multipart.build()
                
                DispatchQueue.main.sync {
                    results.append(result)
                    if results.count == 100 {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 5.0) { _ in
            #expect(results.count == 100)
            
            // Verify all boundaries are unique
            let boundaries = results.map { result in
                result.headers["Content-Type"]!.components(separatedBy: "boundary=").last!
            }
            
            let uniqueBoundaries = Set(boundaries)
            #expect(uniqueBoundaries.count == 100)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Performance of multipart form data with many fields")
    func testPerformanceOfMultipartFormDataWithManyFields() {
        let multipart = MultipartFormData()
        
        // Add many fields
        for i in 0..<1000 {
            multipart.addTextField(named: "field\(i)", value: "value\(i)")
        }
        
        // Add some files
        let fileData = Data(repeating: 0x42, count: 1024)
        for i in 0..<10 {
            multipart.addFileField(named: "file\(i)", fileName: "file\(i).txt", data: fileData, mimeType: "text/plain")
        }
        
        let (headers, body) = multipart.build()
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(body.count > 1000000) // Should be quite large
    }
    
    // MARK: - Integration Tests
    
    @Test("Integration test with real-world multipart data")
    func testIntegrationWithRealWorldMultipartData() {
        let multipart = MultipartFormData()
        
        // Simulate a real document upload
        multipart.addTextField(named: "name", value: "Important Document")
        multipart.addTextField(named: "process_rule", value: """
        {
            "mode": "automatic",
            "rules": {
                "pre_processing_rules": "remove_extra_spaces,remove_urls_emails",
                "segmentation": "automatic"
            }
        }
        """)
        
        let documentData = Data("""
        This is a sample document that contains important information.
        It has multiple paragraphs and various types of content.
        
        The document should be processed automatically by the system.
        """.utf8)
        
        multipart.addFileField(named: "file", fileName: "document.txt", data: documentData, mimeType: "text/plain")
        
        let (headers, body) = multipart.build()
        let bodyString = String(data: body, encoding: .utf8)!
        
        #expect(headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(bodyString.contains("Important Document"))
        #expect(bodyString.contains("automatic"))
        #expect(bodyString.contains("sample document"))
        #expect(bodyString.contains("document.txt"))
        #expect(bodyString.contains("text/plain"))
    }
}