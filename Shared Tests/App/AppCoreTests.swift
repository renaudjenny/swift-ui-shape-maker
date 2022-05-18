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

    func testUpdateImageOpacity() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.incrementing)
        )

        let value = 0.6
        store.send(.imageOpacityChanged(value)) { state in
            state.imageOpacity = value
        }
    }

    func testUpdateDrawingPanelTargetedForDrop() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.incrementing)
        )

        store.send(.drawingPanelTargetedForDropChanged(true)) { state in
            state.isDrawingPanelTargetedForImageDrop = true
        }
    }

    func testUpdateLastZoomGestureDelta() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.incrementing)
        )

        store.send(.lastZoomGestureDeltaChanged(0.5)) { state in
            state.lastZoomGestureDelta = 0.5
        }
        store.receive(.drawing(.zoomLevelChanged(0.5))) { state in
            state.drawing.zoomLevel = 0.5
        }
        store.send(.lastZoomGestureDeltaChanged(nil)) { state in
            state.lastZoomGestureDelta = nil
        }
    }

    func testUpdateLastZoomGestureDeltaClampedHigh() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.incrementing)
        )

        store.send(.lastZoomGestureDeltaChanged(4.1)) { state in
            state.lastZoomGestureDelta = 4.1
        }
        store.receive(.drawing(.zoomLevelChanged(4.0))) { state in
            state.drawing.zoomLevel = 4.0
        }
    }

    func testUpdateLastZoomGestureDeltaClampedLow() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.incrementing)
        )

        store.send(.lastZoomGestureDeltaChanged(0.09)) { state in
            state.lastZoomGestureDelta = 0.09
        }
        store.receive(.drawing(.zoomLevelChanged(0.10))) { state in
            state.drawing.zoomLevel = 0.10
        }
    }
}
