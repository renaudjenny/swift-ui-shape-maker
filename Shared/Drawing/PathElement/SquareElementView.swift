import ComposableArchitecture
import SwiftUI

struct SquareElementView: View {
    let store: Store<PathElement, PathElementAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            Rectangle()
                .frame(width: 5, height: 5)
                .padding()
                .contentShape(Rectangle())
                .onHover { hover in viewStore.send(.hoverChanged(hover), animation: .easeInOut) }
                .scaleEffect(viewStore.isHovered ? 2 : 1)
        }
    }
}
