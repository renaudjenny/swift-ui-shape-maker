import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class AppCoreTests: XCTestCase {
    func testUpdateImageData() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.incrementing)
        )

        let data = Data(count: 123)
        store.send(.updateImageData(data)) { state in
            state.imageData = data
        }
    }
}
