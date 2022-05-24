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

        store.send(.displayPathIndicatorsToggleChanged(isOn: false)) {
            $0.isPathIndicatorsDisplayed = false
        }
        store.send(.displayPathIndicatorsToggleChanged(isOn: true)) {
            $0.isPathIndicatorsDisplayed = true
        }
    }
}
