import SwiftUI

extension DrawingState {
    static var test: Self {
        DrawingState(pathElements: [
            PathElement(index: 0, type: .move(to: CGPoint(x: 123, y: 123))),
            PathElement(index: 1, type: .line(to: CGPoint(x: 234, y: 234))),
        ])
    }
}
