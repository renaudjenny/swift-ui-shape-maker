import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class DrawingCoreTests: XCTestCase {
    func testAddFirstPathElement() {
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: DrawingEnvironement())

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }

        let firstElementPoint = CGPoint(x: 123, y: 123)
        store.send(.movePathElement(to: firstElementPoint)) { state in
            // It's not a line that is added firstly, it's always a "move" element
            state.pathElements = [.move(to: firstElementPoint)]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let secondElementPoint = CGPoint(x: 234, y: 234)
        let actualLine = PathElement.line(to: secondElementPoint)
        store.send(.movePathElement(to: secondElementPoint)) { state in
            state.pathElements = [.move(to: firstElementPoint), actualLine]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }
    }

    func testAddMoveElement() {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        store.send(.selectPathTool(.move)) { state in
            state.selectedPathTool = .move
        }

        let newPoint = CGPoint(x: 456, y: 456)
        store.send(.movePathElement(to: newPoint)) { state in
            state.pathElements += [.move(to: newPoint)]
            state.isAdding = true
        }
    }

    func testAddQuadCurveElement() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }

        let newPoint = CGPoint(x: 456, y: 456)
        store.send(.movePathElement(to: newPoint)) { state in
            state.pathElements += [
                .quadCurve(
                    to: newPoint,
                    control: DrawingState.test.pathElements.initialQuadCurveControl(to: newPoint)
                ),
            ]
            state.isAdding = true
        }
    }

    func testAddCurveElement() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }

        let newPoint = CGPoint(x: 456, y: 456)
        let controls = DrawingState.test.pathElements.initialCurveControls(to: newPoint)
        store.send(.movePathElement(to: newPoint)) { state in
            state.pathElements += [
                .curve(
                    to: newPoint,
                    control1: controls.0,
                    control2: controls.1
                ),
            ]
            state.isAdding = true
        }
    }

    func testAddFirstElementsWhenZoomLevelChanged() throws {
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: DrawingEnvironement())

        var pathElements: [PathElement] = []

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let scale: Double = 90/100
        store.send(.zoomLevelChanged(scale)) { state in
            state.zoomLevel = scale
        }

        let lineToMovePoint = CGPoint(x: 123, y: 123)
        let lineToMove: PathElement = .move(to: lineToMovePoint.applying(CGAffineTransform(scaleX: scale, y: scale)))
        store.send(.movePathElement(to: lineToMovePoint)) { state in
            // It's not a line that is added firstly, it's always a "move" element
            state.pathElements = [lineToMove]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }
        pathElements += [lineToMove]

        let linePoint = CGPoint(x: 234, y: 234)
        let line = PathElement.line(to: linePoint.applyZoomLevel(scale))
        store.send(.movePathElement(to: linePoint)) { state in
            state.pathElements += [line]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }
        pathElements += [line]

        store.send(.selectPathTool(.move)) { state in
            state.selectedPathTool = .move
        }
        let movePoint = CGPoint(x: 235, y: 235)
        let move = PathElement.move(to: movePoint.applyZoomLevel(scale))
        store.send(.movePathElement(to: movePoint)) { state in
            state.pathElements += [move]
            state.isAdding = true
        }
    }

    func testAddQuadCurveWhenZoomChanged() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())
        let pathElements = DrawingState.test.pathElements

        let scale: Double = 90/100
        store.send(.zoomLevelChanged(scale)) { state in
            state.zoomLevel = scale
        }

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }
        let quadCurvePoint = CGPoint(x: 345, y: 345)
        let quadCurve = PathElement.quadCurve(
            to: quadCurvePoint.applyZoomLevel(scale),
            control: pathElements.initialQuadCurveControl(to: quadCurvePoint.applyZoomLevel(scale))
        )
        store.send(.movePathElement(to: quadCurvePoint)) { state in
            state.pathElements += [quadCurve]
            state.isAdding = true
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
    }

    func testAddCurveWhenZoomChanged() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())
        let pathElements = DrawingState.test.pathElements

        let scale: Double = 90/100
        store.send(.zoomLevelChanged(scale)) { state in
            state.zoomLevel = scale
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
        let curvePoint = CGPoint(x: 345, y: 345)
        let curveControls = pathElements.initialCurveControls(to: curvePoint.applyZoomLevel(scale))
        let curve = PathElement.curve(
            to: curvePoint.applyZoomLevel(scale),
            control1: curveControls.0,
            control2: curveControls.1
        )
        store.send(.movePathElement(to: curvePoint)) { state in
            state.pathElements += [curve]
            state.isAdding = true
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
    }

    func testRemovePathElement() {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        store.send(.removePathElement(at: 1)) { state in
            state.pathElements = [state.pathElements[0]]
        }
    }
}

private extension DrawingState {
    static var test: Self {
        DrawingState(pathElements: [.move(to: CGPoint(x: 123, y: 123)), .line(to: CGPoint(x: 234, y: 234))])
    }
}
