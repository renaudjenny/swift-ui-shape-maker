import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class DrawingCoreTests: XCTestCase {
    func testAddFirstPathElement() {
        let store = TestStore(initialState: DrawingState(), reducer: drawingReducer, environment: .test)

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }

        let firstElementPoint = CGPoint(x: 123, y: 123)
        store.send(.movePathElement(to: firstElementPoint)) { state in
            // It's not a line that is added firstly, it's always a "move" element
            state.pathElements.append(PathElement(id: .incrementation(0), type: .move(to: firstElementPoint)))
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let secondElementPoint = CGPoint(x: 234, y: 234)
        let actualLine = PathElement(id: .incrementation(1), type: .line(to: secondElementPoint))
        store.send(.movePathElement(to: secondElementPoint)) { state in
            state.pathElements.append(actualLine)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }
    }

    func testAddMoveElement() {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.move)) { state in
            state.selectedPathTool = .move
        }

        let newPoint = CGPoint(x: 456, y: 456)
        store.send(.movePathElement(to: newPoint)) { state in
            state.pathElements.append(PathElement(id: .incrementation(2), type: .move(to: newPoint)))
            state.isAdding = true
        }
    }

    func testAddQuadCurveElement() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }

        let newPoint = CGPoint(x: 456, y: 456)
        store.send(.movePathElement(to: newPoint)) { state in
            state.pathElements.append(PathElement(id: .incrementation(2), type: .quadCurve(
                to: newPoint,
                control: initialState.pathElements.initialQuadCurveControl(to: newPoint)
            )))
            state.isAdding = true
        }
    }

    func testAddCurveElement() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.curve)) { state in
            state.selectedPathTool = .curve
        }

        let newPoint = CGPoint(x: 456, y: 456)
        let controls = initialState.pathElements.initialCurveControls(to: newPoint)
        store.send(.movePathElement(to: newPoint)) { state in
            state.pathElements.append(PathElement(
                id: .incrementation(2),
                type: .curve(
                    to: newPoint,
                    control1: controls.0,
                    control2: controls.1
                )
            ))
            state.isAdding = true
        }
    }

    func testAddElementWhenOutsideOfThePanel() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let outsidePoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: DrawingPanel.standardWidth + 10)
        let line = PathElement(
            id: .incrementation(2),
            type: .line(to: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth))
        )
        store.send(.movePathElement(to: outsidePoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let otherPoint = CGPoint(x: 123, y: DrawingPanel.standardWidth + 10)
        let otherLine = PathElement(
            id: .incrementation(3),
            type: .line(to: CGPoint(x: 123, y: DrawingPanel.standardWidth))
        )
        store.send(.movePathElement(to: otherPoint)) { state in
            state.pathElements.append(otherLine)
            state.isAdding = true
        }
    }

    func testMoveLine() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let initialPoint = CGPoint(x: 123, y: 123)
        let line = PathElement(
            id: .incrementation(2),
            type: .line(to: initialPoint)
        )
        store.send(.movePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: 234, y: 234)
        let movedLine = PathElement(
            id: .incrementation(2),
            type: .line(to: nextPoint)
        )
        store.send(.movePathElement(to: nextPoint)) { state in
            state.pathElements.update(movedLine, at: 2)
        }
        store.receive(.updateHoveredPathElement(id: .incrementation(2))) { state in
            state.hoveredPathElementID = .incrementation(2)
        }
    }

    func testMoveLineOutsideOfThePanel() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.line)) { state in
            state.selectedPathTool = .line
        }
        let initialPoint = CGPoint(x: 123, y: 123)
        let line = PathElement(
            id: .incrementation(2),
            type: .line(to: initialPoint)
        )
        store.send(.movePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: 234)
        let movedLine = PathElement(
            id: .incrementation(2),
            type: .line(to: CGPoint(x: DrawingPanel.standardWidth, y: 234))
        )
        store.send(.movePathElement(to: nextPoint)) { state in
            state.pathElements.update(movedLine, at: 2)
        }
        store.receive(.updateHoveredPathElement(id: .incrementation(2))) { state in
            state.hoveredPathElementID = .incrementation(2)
        }
    }

    func testMoveLineOutsideOfThePanelAndZoomLevelChanged() throws {
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
        let line = PathElement(
            id: .incrementation(2),
            type: .line(to: initialPoint.applyZoomLevel(1/zoomLevel))
        )
        store.send(.movePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: 234)
        let movedLine = PathElement(
            id: .incrementation(2),
            type: .line(to: CGPoint(x: DrawingPanel.standardWidth, y: 234 * 1/zoomLevel))
        )
        store.send(.movePathElement(to: nextPoint)) { state in
            state.pathElements.update(movedLine, at: 2)
        }
        store.receive(.updateHoveredPathElement(id: .incrementation(2))) { state in
            state.hoveredPathElementID = .incrementation(2)
        }
    }

    func testUpdateGuide() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(1)

        let newPoint = CGPoint(x: 345, y: 345)
        store.send(.updatePathElement(id: id, PathElement.Guide(type: .to, position: newPoint))) { state in
            state.pathElements[id: id] = PathElement(id: id, type: .line(to: newPoint))
        }
    }

    func testUpdateQuadCurveControlGuide() throws {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.selectPathTool(.quadCurve)) { state in
            state.selectedPathTool = .quadCurve
        }
        let quadCurvePoint = CGPoint(x: 345, y: 345)
        let quadCurveControl = initialState.pathElements.initialQuadCurveControl(to: quadCurvePoint)
        let quadCurve = PathElement(
            id: .incrementation(2),
            type: .quadCurve(to: quadCurvePoint, control: quadCurveControl)
        )
        store.send(.movePathElement(to: CGPoint(x: 345, y: 345))) { state in
            state.pathElements.append(quadCurve)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let newControl = CGPoint(x: 300, y: 300)
        let newGuide = PathElement.Guide(type: .quadCurveControl, position: newControl)
        let id: UUID = .incrementation(2)
        store.send(.updatePathElement(id: id, newGuide)) { state in
            state.pathElements[id: id] = PathElement(id: id, type: .quadCurve(to: quadCurvePoint, control: newControl))
        }
    }

    func testRemovePathElement() {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(1)

        store.send(.removePathElement(id: id)) { state in
            state.pathElements.remove(id: id)
        }
    }

    func testUpdateHoveredPathElement() {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)

        store.send(.updateHoveredPathElement(id: .incrementation(1))) { state in
            state.hoveredPathElementID = .incrementation(1)
        }
    }
}
