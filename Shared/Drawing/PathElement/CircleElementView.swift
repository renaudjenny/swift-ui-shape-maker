import SwiftUI

struct CircleElementView: View {
    @Binding var isHovered: Bool

    var body: some View {
        Circle()
            .frame(width: 5, height: 5)
            .padding()
            .contentShape(Rectangle())
            .onHover { hover in
                withAnimation(isHovered ? nil : .easeInOut) {
                    isHovered = hover
                }
            }
            .scaleEffect(isHovered ? 2 : 1)
    }
}
