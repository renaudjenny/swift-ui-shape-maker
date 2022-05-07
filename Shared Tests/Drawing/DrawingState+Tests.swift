import SwiftUI

extension DrawingState {
    static var test: Self {
        DrawingState(pathElements: [.move(to: CGPoint(x: 123, y: 123)), .line(to: CGPoint(x: 234, y: 234))])
    }
}
