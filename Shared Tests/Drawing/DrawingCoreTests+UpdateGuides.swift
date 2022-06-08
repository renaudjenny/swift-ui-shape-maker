import ComposableArchitecture
import Foundation

extension DrawingCoreTests {
    func testUpdatePathElementGuideUpdateTheNextstartPoint() {
        let environment = DrawingEnvironement.test
        let initialState = BaseState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(0)

        let newPosition = CGPoint(x: 101, y: 101)
        let guide = PathElement.Guide(type: .to, position: newPosition)
        store.send(.pathElement(id: id, action: .update(guide: guide))) { state in
            state.pathElements[id: id]?.update(guide: guide)
            let nextElementID: UUID = .incrementation(1)
            state.pathElements[id: nextElementID]?.segment.startPoint = newPosition
        }
    }

    func testUpdatePathElementGuideUpdateTheNextstartPointOutOfBounds() {
        let environment = DrawingEnvironement.test
        let initialState = BaseState.test(environment: environment)
        let store = TestStore(initialState: initialState, reducer: drawingReducer, environment: environment)
        let id: UUID = .incrementation(0)

        let newPosition = CGPoint(x: 101, y: DrawingPanel.standardWidth + 10)
        let guide = PathElement.Guide(type: .to, position: newPosition)
        store.send(.pathElement(id: id, action: .update(guide: guide))) { state in
            let amendedNewPosition = CGPoint(x: 101, y: DrawingPanel.standardWidth)
            let amendedGuide = PathElement.Guide(type: .to, position: amendedNewPosition)
            state.pathElements[id: id]?.update(guide: amendedGuide)
            let nextElementID: UUID = .incrementation(1)
            state.pathElements[id: nextElementID]?.segment.startPoint = amendedNewPosition
        }
    }
}
