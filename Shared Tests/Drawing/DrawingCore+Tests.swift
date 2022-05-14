import ComposableArchitecture
import SwiftUI

extension DrawingState {
    static func test(environment: DrawingEnvironement) -> Self {
        DrawingState(pathElements: [
            PathElementState(
                element: PathElement(id: environment.uuid(), type: .move(to: CGPoint(x: 123, y: 123))),
                previousTo: CGPoint(x: 123, y: 123)
            ),
            PathElementState(
                element: PathElement(id: environment.uuid(), type: .line(to: CGPoint(x: 234, y: 234))),
                previousTo: CGPoint(x: 123, y: 123)
            ),
        ])
    }
}

extension DrawingEnvironement {
    static var test: Self {
        DrawingEnvironement(uuid: UUID.incrementing)
    }
}
