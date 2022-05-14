import ComposableArchitecture
@testable import SwiftUI_Shape_Maker

extension DrawingCoreTests {
    func testAddFirstElementsWhenZoomLevelChanged() throws {
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: .test)

        var pathElements: [PathElementState] = []

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        let lineToMovePoint = CGPoint(x: 123, y: 123)
        let lineToMove = PathElementState(
            element: PathElement(
                id: .incrementation(0),
                type: .move(to: lineToMovePoint.applyZoomLevel(1/zoomLevel))
            ),
            previousTo: lineToMovePoint
        )
        store.send(.addOrMovePathElement(to: lineToMovePoint)) { state in
            // It's not a line that is added firstly, it's always a "move" element
            state.pathElements = [lineToMove]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }
        pathElements += [lineToMove]

        let linePoint = CGPoint(x: 234, y: 234)
        let line = PathElementState(
            element: PathElement(id: .incrementation(1), type: .line(to: linePoint.applyZoomLevel(1/zoomLevel))),
            previousTo: lineToMovePoint
        )
        store.send(.addOrMovePathElement(to: linePoint)) { state in
            state.pathElements.append(line)
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
        let move = PathElementState(
            element: PathElement(id: .incrementation(2), type: .move(to: movePoint.applyZoomLevel(1/zoomLevel))),
            previousTo: linePoint
        )
        store.send(.addOrMovePathElement(to: movePoint)) { state in
            state.pathElements.append(move)
            state.isAdding = true
        }
    }

    func testAddQuadCurveWhenZoomChanged() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }
        let quadCurvePoint = CGPoint(x: 345, y: 345)
        let quadCurve = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .quadCurve(
                    to: quadCurvePoint.applyZoomLevel(1/zoomLevel),
                    control: initialState.pathElements.initialQuadCurveControl(
                        to: quadCurvePoint.applyZoomLevel(1/zoomLevel)
                    )
                )
            ),
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: quadCurvePoint)) { state in
            state.pathElements.append(quadCurve)
            state.isAdding = true
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
    }

    func testAddCurveWhenZoomChanged() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
        let curvePoint = CGPoint(x: 345, y: 345)
        let curveControls = initialState.pathElements.initialCurveControls(to: curvePoint.applyZoomLevel(1/zoomLevel))
        let curve = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .curve(
                    to: curvePoint.applyZoomLevel(1/zoomLevel),
                    control1: curveControls.0,
                    control2: curveControls.1
                )
            ),
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: curvePoint)) { state in
            state.pathElements.append(curve)
            state.isAdding = true
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
    }

    func testAddElementWhenOutsideOfThePanelAndZoomLevelChanged() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }
        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let outsidePoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: DrawingPanel.standardWidth + 10)
        let line = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth))
            ),
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: outsidePoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let otherPoint = CGPoint(x: 125, y: DrawingPanel.standardWidth + 10)
        let otherLine = PathElementState(
            element: PathElement(
                id: .incrementation(3),
                type: .line(to: CGPoint(x: 125 * 1/zoomLevel, y: DrawingPanel.standardWidth))
            ),
            previousTo: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth)
        )
        store.send(.addOrMovePathElement(to: otherPoint)) { state in
            state.pathElements.append(otherLine)
            state.isAdding = true
        }
    }

    func testMoveLineWhenZoomLevelChanged() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }
        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let initialPoint = CGPoint(x: 123, y: 123)
        let line = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: initialPoint.applyZoomLevel(1/zoomLevel))
            ),
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: 234, y: 234)
        let movedLine = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: nextPoint.applyZoomLevel(1/zoomLevel))
            ),
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: nextPoint)) { state in
            state.pathElements.update(movedLine, at: 2)
        }
        store.receive(.pathElement(id: .incrementation(2), action: .hoverChanged(true))) { state in
            state.pathElements[id: .incrementation(2)]?.isHovered = true
        }
    }
}
