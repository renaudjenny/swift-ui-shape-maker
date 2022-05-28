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

    func testRemovePathElementFromCode() throws {
        let uuid = UUID.incrementing
        let initialState = AppState(drawing: .test(environment: .init(uuid: uuid)))
        let store = TestStore(initialState: initialState, reducer: appReducer, environment: AppEnvironment(uuid: uuid))
        let startPoint = try XCTUnwrap(initialState.drawing.pathElements.last?.segment.endPoint)
        let newPoint = CGPoint(x: 111, y: 111)
        store.send(.drawing(.addOrMovePathElement(to: newPoint))) { state in
            state.drawing.pathElements.append(PathElement(
                id: .incrementation(2),
                type: .line,
                segment: Segment(startPoint: startPoint, endPoint: newPoint),
                isHovered: true
            ))
            state.drawing.isAdding = true
        }
        store.send(.drawing(.endMove)) { state in
            state.drawing.isAdding = false
        }

        store.send(.code(.pathElement(id: .incrementation(1), action: .remove))) { state in
            state.drawing.pathElements.remove(id: .incrementation(1))
            let newStartPoint = try XCTUnwrap(state.drawing.pathElements[id: .incrementation(0)]?.segment.endPoint)
            state.drawing.pathElements[id: .incrementation(2)]?.segment.startPoint = newStartPoint
        }
    }
}
