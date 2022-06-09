import ComposableArchitecture
import SwiftUI

struct GuideView: View {
    let store: Store<PathElement, PathElementAction>
    let type: PathElement.GuideType
    let position: CGPoint
    let zoomLevel: Double

    var body: some View {
        WithViewStore(store) { viewStore in
            element
                .position(position.applyZoomLevel(zoomLevel))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let guide = PathElement.Guide(type: type, position: value.location)
                            viewStore.send(.update(guide: guide, zoomLevel: zoomLevel))
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
