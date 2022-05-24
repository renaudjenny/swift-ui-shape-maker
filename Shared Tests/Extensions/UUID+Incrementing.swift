import Foundation

extension UUID {
    // A deterministic, auto-incrementing "UUID" generator for testing.
    // swiftlint:disable:next line_length
    // Source: https://github.com/pointfreeco/swift-composable-architecture/blob/02cf7590ff90455d967417a69dd4f765870ddbd9/Examples/Todos/TodosTests/TodosTests.swift#L324-L333
    static var incrementing: () -> UUID {
        var uuid = 0
        return {
            defer { uuid += 1 }
            // swiftlint:disable:next force_unwrapping
            return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
        }
    }

    static func incrementation(_ incrementation: Int) -> UUID {
        // swiftlint:disable:next force_unwrapping
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", incrementation))")!
    }
}
