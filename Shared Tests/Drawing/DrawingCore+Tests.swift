import ComposableArchitecture
import SwiftUI

extension DrawingState {
    static func test(environment: DrawingEnvironement) -> Self {
        DrawingState(pathElements: [
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
