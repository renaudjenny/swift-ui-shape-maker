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
        store.send(.addOrMovePathElement(to: firstElementPoint)) { state in
            // It's not a line that is added firstly, it's always a "move" element
            state.pathElements.append(PathElement(
                id: .incrementation(0),
                type: .move(to: firstElementPoint),
                startPoint: firstElementPoint,
                isHovered: true
            ))
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let secondElementPoint = CGPoint(x: 234, y: 234)
        let actualLine = PathElement(
            id: .incrementation(1),
            type: .line(to: secondElementPoint),
            startPoint: firstElementPoint,
            isHovered: true
        )
        store.send(.addOrMovePathElement(to: secondElementPoint)) { state in
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
        store.send(.addOrMovePathElement(to: newPoint)) { state in
            state.pathElements.append(PathElement(
                id: .incrementation(2),
                type: .move(to: newPoint),
                startPoint: initialState.pathElements[1].to,
                isHovered: true
            ))
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
        store.send(.addOrMovePathElement(to: newPoint)) { state in
            state.pathElements.append(PathElement(
                id: .incrementation(2),
                type: .quadCurve(
                    to: newPoint,
                    control: initialState.pathElements.initialQuadCurveControl(to: newPoint)
                ),
                startPoint: initialState.pathElements[1].to,
                isHovered: true
            ))
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
        store.send(.addOrMovePathElement(to: newPoint)) { state in
            state.pathElements.append(PathElement(
                id: .incrementation(2),
                type: .curve(
                    to: newPoint,
                    control1: controls.0,
                    control2: controls.1
                ),
                startPoint: initialState.pathElements[1].to,
                isHovered: true
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
            type: .line(to: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth)),
            startPoint: initialState.pathElements[1].to,
            isHovered: true
        )
        store.send(.addOrMovePathElement(to: outsidePoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let otherPoint = CGPoint(x: 123, y: DrawingPanel.standardWidth + 10)
        let otherLine = PathElement(
            id: .incrementation(3),
            type: .line(to: CGPoint(x: 123, y: DrawingPanel.standardWidth)),
            startPoint: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth),
            isHovered: true
        )
        store.send(.addOrMovePathElement(to: otherPoint)) { state in
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
            type: .line(to: initialPoint),
            startPoint: initialState.pathElements[1].to,
            isHovered: true
        )
        store.send(.addOrMovePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: 234, y: 234)
        let guide = PathElement.Guide(type: .to, position: nextPoint)
        store.send(.addOrMovePathElement(to: nextPoint))
        store.receive(.pathElement(id: .incrementation(2), action: .update(guide: guide))) { state in
            state.pathElements[id: .incrementation(2)]?.update(guide: guide)
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
            type: .line(to: initialPoint),
            startPoint: initialState.pathElements[1].to,
            isHovered: true
        )
        store.send(.addOrMovePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: 234)
        let guide = PathElement.Guide(type: .to, position: nextPoint)
        store.send(.addOrMovePathElement(to: nextPoint))
        store.receive(.pathElement(id: .incrementation(2), action: .update(guide: guide))) { state in
            let amendedGuide = PathElement.Guide(type: .to, position: CGPoint(x: DrawingPanel.standardWidth, y: 234))
            state.pathElements[id: .incrementation(2)]?.update(guide: amendedGuide)
        }
    }

    func testMoveLineOutsideOfThePanelAndZoomLevelChanged() throws {
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
            type: .line(to: initialPoint.applyZoomLevel(1/zoomLevel)),
            startPoint: initialState.pathElements[1].to,
            isHovered: true,
            zoomLevel: zoomLevel
        )
        store.send(.addOrMovePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: DrawingPanel.standardWidth + 10, y: 234)
        let guide = PathElement.Guide(type: .to, position: nextPoint)
        store.send(.addOrMovePathElement(to: nextPoint))
        store.receive(.pathElement(id: .incrementation(2), action: .update(guide: guide))) { state in
            let amendedGuide = PathElement.Guide(
                type: .to,
                position: CGPoint(x: DrawingPanel.standardWidth, y: 234 * 1/zoomLevel)
            )
            state.pathElements[id: .incrementation(2)]?.update(guide: amendedGuide)
        }
    }

    func testRemovePathElement() {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(1)

        store.send(.pathElement(id: id, action: .remove)) { state in
            state.pathElements.remove(id: id)
        }
    }

    func testUpdatePathElementGuideUpdateTheNextstartPoint() {
        let environment = DrawingEnvironement.test
        let initialState = DrawingState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(0)

        let newPosition = CGPoint(x: 101, y: 101)
        let guide = PathElement.Guide(type: .to, position: newPosition)
        store.send(.pathElement(id: id, action: .update(guide: guide))) { state in
            state.pathElements[id: id]?.update(guide: guide)
            let nextElementID: UUID = .incrementation(1)
            state.pathElements[id: nextElementID]?.startPoint = newPosition
        }
    }
}
