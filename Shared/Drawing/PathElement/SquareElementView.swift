import ComposableArchitecture
import SwiftUI

struct SquareElementView: View {
    let store: Store<PathElementState, PathElementAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            Rectangle()
                .frame(width: 5, height: 5)
                .padding()
                .contentShape(Rectangle())
                .onHover { hover in
                    withAnimation(viewStore.isHovered ? nil : .easeInOut) {
                        viewStore.send(.hoverChanged(hover))
                    }
                }
                .scaleEffect(viewStore.isHovered ? 2 : 1)
        }
    }
}