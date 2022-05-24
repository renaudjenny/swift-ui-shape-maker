import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class CodeCoreTests: XCTestCase {
    func testChangeEditing() {
        let store = TestStore(
            initialState: CodeState(pathElements: [], isEditing: false),
            reducer: codeReducer,
            environment: CodeEnvironment()
        )

        store.send(.editChanged(true)) { state in
            state.isEditing = true
        }
    }

    func testRemovePathElement() {
        let id: UUID = .incrementation(0)
        let store = TestStore(
            initialState: CodeState(
                pathElements: [
                    PathElement(
                        id: id,
                        type: .line,
                        startPoint: CGPoint(x: 123, y: 123),
                        endPoint: CGPoint(x: 234, y: 234)
                    ),
                ],
                isEditing: false
            ),
            reducer: codeReducer,
            environment: CodeEnvironment()
        )

        store.send(.pathElement(id: id, action: .remove)) { state in
            state.pathElements.remove(id: id)
        }
    }
}
