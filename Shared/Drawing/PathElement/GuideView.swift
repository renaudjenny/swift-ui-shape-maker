import ComposableArchitecture
import SwiftUI

struct GuideView: View {
    let store: Store<DrawingState, DrawingAction>
    let type: PathElement.GuideType
    let position: CGPoint
    let id: PathElement.ID
    @Binding var isHovered: Bool

    var body: some View {
        WithViewStore(store) { viewStore in
            element
                .position(position.applyZoomLevel(viewStore.zoomLevel))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring()) {
                                viewStore.send(.updatePathElement(
                                    id: id,
                                    PathElement.Guide(type: type, position: value.location)
                                ))
                            }
                        }
                )
        }
    }

    @ViewBuilder
    var element: some View {
        switch type {
        case .to:
            CircleElementView(isHovered: $isHovered)
        case .quadCurveControl, .curveControl1, .curveControl2:
            SquareElementView(isHovered: $isHovered)
        }
    }
}
