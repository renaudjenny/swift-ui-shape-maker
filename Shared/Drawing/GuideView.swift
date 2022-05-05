import ComposableArchitecture
import SwiftUI

struct GuideView: View {
    let store: Store<DrawingState, DrawingAction>
    let type: PathElement.GuideType
    let position: CGPoint
    let offset: Int
    @Binding var isHovered: Bool
    @Binding var draggingElementOffset: Int?

    var body: some View {
        WithViewStore(store) { viewStore in
            element
                .position(position.applyZoomLevel(viewStore.zoomLevel))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring()) {
                                viewStore.send(.updatePathElement(
                                    at: offset,
                                    PathElement.Guide(type: type, position: value.location)
                                ))
                            }
                            draggingElementOffset = offset
                        }
                        .onEnded { _ in
                            withAnimation { draggingElementOffset = nil }
                        }
                )
        }
    }

    @ViewBuilder
    var element: some View {
        switch type {
        case .to:
            CircleElementView(isHovered: $isHovered, isDragged: draggingElementOffset == offset)
        case .quadCurveControl, .curveControl1, .curveControl2:
            SquareElementView(isHovered: $isHovered, isDragged: draggingElementOffset == offset)
        }
    }
}
