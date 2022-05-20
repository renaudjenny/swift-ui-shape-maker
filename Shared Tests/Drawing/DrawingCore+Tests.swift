import ComposableArchitecture
import SwiftUI

extension DrawingState {
    static func test(environment: DrawingEnvironement) -> Self {
        DrawingState(pathElements: [
            PathElement(
                id: environment.uuid(),
                type: .move(to: CGPoint(x: 123, y: 123)),
                previousTo: CGPoint(x: 123, y: 123)
            ),
            PathElement(
                id: environment.uuid(),
                type: .line(to: CGPoint(x: 234, y: 234)),
                previousTo: CGPoint(x: 123, y: 123)
            ),
        ])
    }

    mutating func updatePathElementsZoomLevel(_ zoomLevel: Double) {
        pathElements.map(\.id).forEach {
            pathElements[id: $0]?.zoomLevel = zoomLevel
        }
    }
}

extension DrawingEnvironement {
    static var test: Self {
        DrawingEnvironement(uuid: UUID.incrementing)
    }
}
