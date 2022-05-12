import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class PathElementCoreTests: XCTestCase {
    func testChangeHover() {
        let pathElement = PathElement(id: UUID(), type: .line(to: CGPoint(x: 123, y: 123)))
        let store = TestStore(
            initialState: PathElementState(element: pathElement),
            reducer: pathElementReducer,
            environment: PathElementEnvironement()
        )

        store.send(.hoverChanged(true)) { state in
            state.isHovered = true
        }
    }
}
