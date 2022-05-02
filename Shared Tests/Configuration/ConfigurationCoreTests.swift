import XCTest
import ComposableArchitecture
@testable import SwiftUI_Shape_Maker

final class ConfigurationCoreTests: XCTestCase {
    func testUpdatingPathIndicatorsDisplayState() {
        let store = TestStore(
            initialState: ConfigurationState(),
            reducer: configurationReducer,
            environment: ConfigurationEnvironement()
        )

        store.send(.hidePathIndicators) {
            $0.isPathIndicatorsDisplayed = false
        }
        store.send(.displayPathIndicators) {
            $0.isPathIndicatorsDisplayed = true
        }
    }
}
