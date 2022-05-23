import ComposableArchitecture
import SwiftUI

struct CircleElementView: View {
    let store: Store<PathElement, PathElementAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            Circle()
                .frame(width: 5, height: 5)
                .padding()
                .contentShape(Rectangle())
                .onHover { hover in
                    withAnimation(.easeInOut) {
                        viewStore.send(.hoverChanged(hover))
                    }
                }
                .scaleEffect(viewStore.isHovered ? 2 : 1)
        }
    }
}
