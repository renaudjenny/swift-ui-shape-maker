import ComposableArchitecture
@testable import SwiftUI_Shape_Maker
import XCTest

final class CodeCoreTests: XCTestCase {
    func testChangeEditing() {
        let store = TestStore(
            initialState: CodeState(pathElements: [], mode: .blocks),
            reducer: codeReducer,
            environment: CodeEnvironment()
        )

        store.send(.modeChanged(.edition)) { state in
            state.mode = .edition
        }
    }

    func testRemovePathElement() {
        let id: UUID = .incrementation(0)
        let store = TestStore(
            initialState: CodeState(
                pathElements: [
                    PathElement(
                        id: id,
                        type: .line,
                        segment: Segment(startPoint: CGPoint(x: 123, y: 123), endPoint: CGPoint(x: 234, y: 234))
                    ),
                ],
                mode: .blocks
            ),
            reducer: codeReducer,
            environment: CodeEnvironment()
        )

        store.send(.pathElement(id: id, action: .remove)) { state in
            state.pathElements.remove(id: id)
        }
    }

    func testTransformPathElement() {
        let id: UUID = .incrementation(0)
        let pathElement = PathElement(
            id: id,
            type: .line,
            segment: Segment(startPoint: CGPoint(x: 123, y: 123), endPoint: CGPoint(x: 234, y: 234))
        )
        let store = TestStore(
            initialState: CodeState(pathElements: [pathElement], mode: .blocks),
            reducer: codeReducer,
            environment: CodeEnvironment()
        )

        store.send(.pathElement(id: id, action: .transform(to: .move))) { state in
            state.pathElements[id: id]?.type = .move
        }
        store.send(.pathElement(id: id, action: .transform(to: .line))) { state in
            state.pathElements[id: id]?.type = .line
        }
        store.send(.pathElement(id: id, action: .transform(to: .quadCurve))) { state in
            state.pathElements[id: id]?.type = .quadCurve(control: pathElement.segment.initialQuadCurveControl)
        }
        store.send(.pathElement(id: id, action: .transform(to: .curve))) { state in
            let (control1, control2) = pathElement.segment.initialCurveControls
            state.pathElements[id: id]?.type = .curve(control1: control1, control2: control2)
        }
    }
}
