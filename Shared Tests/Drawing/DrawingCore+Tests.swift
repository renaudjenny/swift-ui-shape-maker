import ComposableArchitecture
import SwiftUI

extension DrawingEnvironement {
    static var test: Self {
        DrawingEnvironement(uuid: UUID.incrementing)
    }
}

extension BaseState where State == DrawingState {
    static func test(environment: DrawingEnvironement) -> Self {
        let pathElements = IdentifiedArrayOf(uniqueElements: [
            PathElement(
                id: environment.uuid(),
                type: .move,
                segment: Segment(startPoint: CGPoint(x: 123, y: 123), endPoint: CGPoint(x: 123, y: 123))
            ),
            PathElement(
                id: environment.uuid(),
                type: .line,
                segment: Segment(startPoint: CGPoint(x: 123, y: 123), endPoint: CGPoint(x: 234, y: 234))
            ),
        ])
        return BaseState(pathElements: pathElements, state: DrawingState())
    }
}
