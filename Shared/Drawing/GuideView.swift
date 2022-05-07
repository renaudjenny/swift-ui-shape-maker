import ComposableArchitecture
import SwiftUI

struct GuideView: View {
    let store: Store<DrawingState, DrawingAction>
    let type: PathElement.GuideType
    let position: CGPoint
    let id: PathElement.ID
    @Binding var isHovered: Bool
    @Binding var draggingID: PathElement.ID?

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
                            draggingID = id
                        }
                        .onEnded { _ in
                            withAnimation { draggingID = nil }
                        }
                )
        }
    }

    @ViewBuilder
    var element: some View {
        switch type {
        case .to:
            CircleElementView(isHovered: $isHovered, isDragged: draggingID == id)
        case .quadCurveControl, .curveControl1, .curveControl2:
            SquareElementView(isHovered: $isHovered, isDragged: draggingID == id)
        }
    }
}
