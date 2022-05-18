import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class CodeCoreTests: XCTestCase {
    func testChangeEditing() {
        let store = TestStore(initialState: CodeState(), reducer: codeReducer, environment: CodeEnvironment())

        store.send(.editChanged(true)) { state in
            state.isEditing = true
        }
    }
}
