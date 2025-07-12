import Foundation
import Testing
@testable import DifySwiftClient

/// Helper functions for tests to ensure proper mock setup and teardown
extension DifyTestCase {
    /// Setup test environment with mock reset
    /// Call this at the beginning of each test that uses mocks
    func setupTest() {
        MockURLProtocol.reset()
    }
}

/// Macro to ensure test setup is called
/// Usage: @Test func myTest() async throws {
///     setupTest()
///     // ... rest of test
/// }