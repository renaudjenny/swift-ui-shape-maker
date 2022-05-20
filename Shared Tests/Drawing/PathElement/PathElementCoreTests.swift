import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class PathElementCoreTests: XCTestCase {
    func testChangeHover() {
        let store = TestStore(initialState: .test, reducer: pathElementReducer, environment: PathElementEnvironement())

        store.send(.hoverChanged(true)) { state in
            state.isHovered = true
        }
    }

    func testUpdateGuide() throws {
        let store = TestStore(initialState: .test, reducer: pathElementReducer, environment: PathElementEnvironement())

        let newPoint = CGPoint(x: 345, y: 345)
        let guide = PathElement.Guide(type: .to, position: newPoint)
        store.send(.update(guide: guide)) { state in
            state.element.update(guide: guide)
        }
    }

    func testUpdateQuadCurveControlGuide() throws {
        let store = TestStore(
            initialState: .testQuadCurve,
            reducer: pathElementReducer,
            environment: PathElementEnvironement()
        )

        let control = CGPoint(x: 300, y: 300)
        let guide = PathElement.Guide(type: .quadCurveControl, position: control)
        store.send(.update(guide: guide)) { state in
            state.element.update(guide: guide)
        }
    }

    func testUpdateGuideWhenZoomLevelChanged() throws {
        let zoomLevel: Double = 90/100
        var initialState: PathElement = .test
        initialState.zoomLevel = zoomLevel
        let store = TestStore(
            initialState: initialState,
            reducer: pathElementReducer,
            environment: PathElementEnvironement()
        )

        let newPoint = CGPoint(x: 345, y: 345)
        let guide = PathElement.Guide(type: .to, position: newPoint)
        store.send(.update(guide: guide)) { state in
            state.element.update(guide: PathElement.Guide(type: .to, position: newPoint.applyZoomLevel(1/zoomLevel)))
        }
    }

    func testUpdateGuideWhenZoomLevelChangedAndPositionOutsidePanel() throws {
        let zoomLevel: Double = 90/100
        var initialState: PathElement = .test
        initialState.zoomLevel = zoomLevel
        let store = TestStore(
            initialState: initialState,
            reducer: pathElementReducer,
            environment: PathElementEnvironement()
        )
        let newPoint = CGPoint(x: 100, y: DrawingPanel.standardWidth + 10)
        let guide = PathElement.Guide(type: .to, position: newPoint)
        store.send(.update(guide: guide)) { state in
            let newPoint = CGPoint(x: 100 * 1/zoomLevel, y: DrawingPanel.standardWidth)
            let amendedGuide = PathElement.Guide(type: .to, position: newPoint)
            state.element.update(guide: amendedGuide)
        }
    }
}

private extension PathElement {
    static var test: Self {
        DrawingState.test(environment: .test).pathElements[1]
    }

    static var testQuadCurve: Self {
        let drawingState = DrawingState.test(environment: .test)
        let quadCurvePoint = CGPoint(x: 345, y: 345)
        let quadCurveControl = drawingState.pathElements.initialQuadCurveControl(to: quadCurvePoint)
        return PathElement(
            element: PathElement(
                id: .incrementation(2),
                type: .quadCurve(to: quadCurvePoint, control: quadCurveControl)
            ),
            previousTo: drawingState.pathElements[1].element.to
        )
    }
}
