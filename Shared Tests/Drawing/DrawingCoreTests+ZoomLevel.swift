import ComposableArchitecture
@testable import SwiftUI_Shape_Maker

extension DrawingCoreTests {
    // swiftlint:disable:next function_body_length
    func testAddFirstElementsWhenZoomLevelChanged() throws {
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: .test)

        var pathElements: [PathElement] = []

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
        }

        let lineToMovePoint = CGPoint(x: 123, y: 123)
        // It's not a line that is added firstly, it's always a "move" element, and it cannot be transformed
        let lineToMove = PathElement(
            id: .incrementation(0),
            type: .move,
            segment: Segment(
                startPoint: lineToMovePoint.applyZoomLevel(1/zoomLevel),
                endPoint: lineToMovePoint.applyZoomLevel(1/zoomLevel)
            ),
            isHovered: true,
            zoomLevel: zoomLevel,
            isTransformable: false
        )
        store.send(.addOrMovePathElement(to: lineToMovePoint)) { state in
            state.pathElements = [lineToMove]
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }
        pathElements += [lineToMove]

        let linePoint = CGPoint(x: 234, y: 234)
        let line = PathElement(
            id: .incrementation(1),
            type: .line,
            segment: Segment(
                startPoint: lineToMovePoint.applyZoomLevel(1/zoomLevel),
                endPoint: linePoint.applyZoomLevel(1/zoomLevel)
            ),
            isHovered: true,
            zoomLevel: zoomLevel
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
        let move = PathElement(
            id: .incrementation(2),
            type: .move,
            segment: Segment(
                startPoint: linePoint.applyZoomLevel(1/zoomLevel),
                endPoint: movePoint.applyZoomLevel(1/zoomLevel)
            ),
            isHovered: true,
            zoomLevel: zoomLevel
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
            state.updatePathElementsZoomLevel(zoomLevel)
        }

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }
        let quadCurvePoint = CGPoint(x: 345, y: 345)
        let quadCurveSegment = Segment(
            startPoint: initialState.pathElements[1].segment.endPoint,
            endPoint: quadCurvePoint.applyZoomLevel(1/zoomLevel)
        )
        let quadCurve = PathElement(
            id: .incrementation(2),
            type: .quadCurve(control: quadCurveSegment.initialQuadCurveControl),
            segment: quadCurveSegment,
            isHovered: true,
            zoomLevel: zoomLevel
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
            state.updatePathElementsZoomLevel(zoomLevel)
        }

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }
        let curvePoint = CGPoint(x: 345, y: 345)
        let curveSegment = Segment(
            startPoint: initialState.pathElements[1].segment.endPoint,
            endPoint: curvePoint.applyZoomLevel(1/zoomLevel)
        )
        let (control1, control2) = curveSegment.initialCurveControls
        let curve = PathElement(
            id: .incrementation(2),
            type: .curve(control1: control1, control2: control2),
            segment: curveSegment,
            isHovered: true,
            zoomLevel: zoomLevel
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
            state.updatePathElementsZoomLevel(zoomLevel)
        }
        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let outsidePoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: DrawingPanel.standardWidth + 10)
        let line = PathElement(
            id: .incrementation(2),
            type: .line,
            segment: Segment(
                startPoint: initialState.pathElements[1].segment.endPoint,
                endPoint: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth)
            ),
            isHovered: true,
            zoomLevel: zoomLevel
        )
        store.send(.addOrMovePathElement(to: outsidePoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let otherPoint = CGPoint(x: 125, y: DrawingPanel.standardWidth + 10)
        let otherLine = PathElement(
            id: .incrementation(3),
            type: .line,
            segment: Segment(
                startPoint: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth),
                endPoint: CGPoint(x: 125 * 1/zoomLevel, y: DrawingPanel.standardWidth)
            ),
            isHovered: true,
            zoomLevel: zoomLevel
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
            state.updatePathElementsZoomLevel(zoomLevel)
        }
        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let initialPoint = CGPoint(x: 123, y: 123)
        let line = PathElement(
            id: .incrementation(2),
            type: .line,
            segment: Segment(
                startPoint: initialState.pathElements[1].segment.endPoint,
                endPoint: initialPoint.applyZoomLevel(1/zoomLevel)
            ),
            isHovered: true,
            zoomLevel: zoomLevel
        )
        store.send(.addOrMovePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: 234, y: 234)
        let guide = PathElement.Guide(type: .to, position: nextPoint)
        store.send(.addOrMovePathElement(to: nextPoint))
        store.receive(.pathElement(id: .incrementation(2), action: .update(guide: guide))) { state in
            let amendedGuide = PathElement.Guide(type: .to, position: nextPoint.applyZoomLevel(1/zoomLevel))
            state.pathElements[id: .incrementation(2)]?.update(guide: amendedGuide)
        }
    }

    func testUpdatePathElementGuideUpdateTheNextstartPointWhenZoomLevelChanged() {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(0)

        let zoomLevel: Double = 90/100
        store.send(.zoomLevelChanged(zoomLevel)) { state in
            state.zoomLevel = zoomLevel
            state.updatePathElementsZoomLevel(zoomLevel)
        }

        let newPosition = CGPoint(x: 101, y: 101)
        let guide = PathElement.Guide(type: .to, position: newPosition)
        store.send(.pathElement(id: id, action: .update(guide: guide))) { state in
            let amendedGuide = PathElement.Guide(type: .to, position: newPosition.applyZoomLevel(1/zoomLevel))
            state.pathElements[id: id]?.update(guide: amendedGuide)
            let nextElementID: UUID = .incrementation(1)
            state.pathElements[id: nextElementID]?.segment.startPoint = newPosition.applyZoomLevel(1/zoomLevel)
        }
    }

    func testIncrementZoomLevel() {
        let environment = DrawingEnvironement.test
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: environment)

        store.send(.incrementZoomLevel)
        store.receive(.zoomLevelChanged(1.1)) { state in
            state.zoomLevel += 0.1
        }
    }

    func testDecrementZoomLevel() {
        let environment = DrawingEnvironement.test
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: environment)

        store.send(.decrementZoomLevel)
        store.receive(.zoomLevelChanged(0.9)) { state in
            state.zoomLevel -= 0.1
        }
    }
}
