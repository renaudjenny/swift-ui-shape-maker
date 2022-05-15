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
            state.pathElements.append(PathElementState(
                element: PathElement(id: .incrementation(0), type: .move(to: firstElementPoint)),
                isHovered: true,
                previousTo: firstElementPoint
            ))
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let secondElementPoint = CGPoint(x: 234, y: 234)
        let actualLine = PathElementState(
            element: PathElement(id: .incrementation(1), type: .line(to: secondElementPoint)),
            isHovered: true,
            previousTo: firstElementPoint
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
            state.pathElements.append(PathElementState(
                element: PathElement(id: .incrementation(2), type: .move(to: newPoint)),
                isHovered: true,
                previousTo: initialState.pathElements[1].element.to
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
            state.pathElements.append(PathElementState(
                element: PathElement(id: .incrementation(2), type: .quadCurve(
                    to: newPoint,
                    control: initialState.pathElements.initialQuadCurveControl(to: newPoint)
                )),
                isHovered: true,
                previousTo: initialState.pathElements[1].element.to
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
            state.pathElements.append(PathElementState(
                element: PathElement(
                    id: .incrementation(2),
                    type: .curve(
                        to: newPoint,
                        control1: controls.0,
                        control2: controls.1
                    )
                ),
                isHovered: true,
                previousTo: initialState.pathElements[1].element.to
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
        let line = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth))
            ),
            isHovered: true,
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: outsidePoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        store.send(.endMove) { state in
            state.isAdding = false
        }

        let otherPoint = CGPoint(x: 123, y: DrawingPanel.standardWidth + 10)
        let otherLine = PathElementState(
            element: PathElement(
                id: .incrementation(3),
                type: .line(to: CGPoint(x: 123, y: DrawingPanel.standardWidth))
            ),
            isHovered: true,
            previousTo: CGPoint(x: DrawingPanel.standardWidth, y: DrawingPanel.standardWidth)
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
        let line = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: initialPoint)
            ),
            isHovered: true,
            previousTo: initialState.pathElements[1].element.to
        )
        store.send(.addOrMovePathElement(to: initialPoint)) { state in
            state.pathElements.append(line)
            state.isAdding = true
        }
        let nextPoint = CGPoint(x: 234, y: 234)
        let guide = PathElement.Guide(type: .to, position: nextPoint)
        store.send(.addOrMovePathElement(to: nextPoint))
        store.receive(.pathElement(id: .incrementation(2), action: .update(guide: guide))) { state in
            state.pathElements[id: .incrementation(2)]?.element.update(guide: guide)
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
        let line = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: initialPoint)
            ),
            isHovered: true,
            previousTo: initialState.pathElements[1].element.to
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
            state.pathElements[id: .incrementation(2)]?.element.update(guide: amendedGuide)
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
        let line = PathElementState(
            element: PathElement(
                id: .incrementation(2),
                type: .line(to: initialPoint.applyZoomLevel(1/zoomLevel))
            ),
            isHovered: true,
            zoomLevel: zoomLevel,
            previousTo: initialState.pathElements[1].element.to
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
            state.pathElements[id: .incrementation(2)]?.element.update(guide: amendedGuide)
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
}
