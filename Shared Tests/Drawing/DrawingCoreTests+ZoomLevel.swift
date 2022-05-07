import ComposableArchitecture
@testable import SwiftUI_Shape_Maker

extension DrawingCoreTests {
    func testAddFirstElementsWhenZoomLevelChanged() throws {
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: DrawingEnvironement())

        var pathElements: [PathElement] = []

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        let lineToMovePoint = CGPoint(x: 123, y: 123)
        let lineToMove: PathElement = .move(to: lineToMovePoint.applyZoomLevel(1/zoomLevel))
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
        let line = PathElement.line(to: linePoint.applyZoomLevel(1/zoomLevel))
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
        let move = PathElement.move(to: movePoint.applyZoomLevel(1/zoomLevel))
        store.send(.movePathElement(to: movePoint)) { state in
            state.pathElements += [move]
            state.isAdding = true
        }
    }

    func testAddQuadCurveWhenZoomChanged() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())
        let pathElements = DrawingState.test.pathElements

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }
        let quadCurvePoint = CGPoint(x: 345, y: 345)
        let quadCurve = PathElement.quadCurve(
            to: quadCurvePoint.applyZoomLevel(1/zoomLevel),
            control: pathElements.initialQuadCurveControl(to: quadCurvePoint.applyZoomLevel(1/zoomLevel))
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

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
        let curvePoint = CGPoint(x: 345, y: 345)
        let curveControls = pathElements.initialCurveControls(to: curvePoint.applyZoomLevel(1/zoomLevel))
        let curve = PathElement.curve(
            to: curvePoint.applyZoomLevel(1/zoomLevel),
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

    func testAddElementWhenOutsideOfThePanelAndZoomLevelChanged() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }
        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let outsidePoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: DrawingPanel.standardWidth + 10)
        let line = PathElement.line(to: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth))
        store.send(.movePathElement(to: outsidePoint)) { state in
            state.pathElements += [line]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let otherPoint = CGPoint(x: 125, y: DrawingPanel.standardWidth + 10)
        let otherLine = PathElement.line(to: CGPoint(x: 125 * 1/zoomLevel, y: DrawingPanel.standardWidth))
        store.send(.movePathElement(to: otherPoint)) { state in
            state.pathElements += [otherLine]
            state.isAdding = true
        }
    }

    func testMoveLineWhenZoomLevelChanged() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())
        let pathElements = DrawingState.test.pathElements

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }
        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let initialPoint = CGPoint(x: 123, y: 123)
        let line = PathElement.line(to: initialPoint.applyZoomLevel(1/zoomLevel))
        store.send(.movePathElement(to: initialPoint)) { state in
            state.pathElements = pathElements + [line]
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: 234, y: 234)
        let movedLine = PathElement.line(to: nextPoint.applyZoomLevel(1/zoomLevel))
        store.send(.movePathElement(to: nextPoint)) { state in
            state.pathElements = pathElements + [movedLine]
        }
    }

    func testUpdateGuideWhenZoomLevelChanged() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }
        let newPoint = CGPoint(x: 345, y: 345)
        store.send(.updatePathElement(at: 1, PathElement.Guide(type: .to, position: newPoint))) { state in
            state.pathElements[1] = .line(to: newPoint.applyZoomLevel(1/zoomLevel))
        }
    }

    func testUpdateGuideWhenZoomLevelChangedAndPositionOutsidePanel() throws {
        let store = TestStore(initialState: .test, reducer: drawingReducer, environment: DrawingEnvironement())

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }
        let newPoint = CGPoint(x: 100, y: DrawingPanel.standardWidth + 10)
        store.send(.updatePathElement(at: 1, PathElement.Guide(type: .to, position: newPoint))) { state in
            let newPoint = CGPoint(x: 100 * 1/zoomLevel, y: DrawingPanel.standardWidth)
            state.pathElements[1] = .line(to: newPoint)
        }
    }
}
