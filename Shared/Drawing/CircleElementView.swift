import SwiftUI

struct CircleElementView: View {
    @Binding var isHovered: Bool
    let isDragged: Bool

    var body: some View {
        Circle()
            .frame(width: 5, height: 5)
            .padding()
            .contentShape(Rectangle())
            .onHover { hover in
                withAnimation(isHovered || isDragged ? nil : .easeInOut) {
                    isHovered = hover
                }
            }
            .scaleEffect(isHovered || isDragged ? 2 : 1)
    }
}
