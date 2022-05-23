import ComposableArchitecture
import SwiftUI

struct GuideView: View {
    let store: Store<PathElement, PathElementAction>
    let type: PathElement.GuideType
    let position: CGPoint

    var body: some View {
        WithViewStore(store) { viewStore in
            element
                .position(position.applyZoomLevel(viewStore.zoomLevel))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            viewStore.send(.update(guide: PathElement.Guide(type: type, position: value.location)))
                        }
                )
        }
    }

    @ViewBuilder
    var element: some View {
        switch type {
        case .to:
            CircleElementView(store: store)
        case .quadCurveControl, .curveControl1, .curveControl2:
            SquareElementView(store: store)
        }
    }
}
