import SwiftUI
import ComposableArchitecture

struct DrawingPanel: View {
    let store: Store<AppState, AppAction>
    @State private var isAdding = false
    @State private var draggingElementOffset: Int?
    @Binding var hoveredOffsets: Set<Int>
    let selectedPathTool: PathTool

    static let standardWidth: CGFloat = 1000

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.white
                    .gesture(
                        DragGesture()
                            .onChanged { viewStore.send(.drawing(.movePathElement(to: $0.location))) }
                            .onEnded { _ in viewStore.send(.drawing(.endMove)) }
                    )

                Path { path in
                    viewStore.drawing.pathElements.forEach {
                        path.addElement($0, zoomLevel: viewStore.drawing.zoomLevel)
                    }
                }
                .stroke()

                if viewStore.configuration.isPathIndicatorsDisplayed {
                    pathIndicators(viewStore: viewStore)
                }
            }
        }
    }

    @ViewBuilder
    private func pathIndicators(viewStore: ViewStore<AppState, AppAction>) -> some View {
        let zoomLevel = viewStore.drawing.zoomLevel
        ForEach(Array(viewStore.drawing.pathElements.enumerated()), id: \.offset) { offset, element in
            switch element {
            case let .move(to), let .line(to):
                GuideView(
                    store: store.scope(state: \.drawing, action: AppAction.drawing),
                    type: .to,
                    position: to,
                    offset: offset,
                    isHovered: isHovered(offset: offset),
                    draggingElementOffset: $draggingElementOffset
                )
            case let .quadCurve(to, control):
                ZStack {
                    GuideView(
                        store: store.scope(state: \.drawing, action: AppAction.drawing),
                        type: .to,
                        position: to,
                        offset: offset,
                        isHovered: isHovered(offset: offset),
                        draggingElementOffset: $draggingElementOffset
                    )
                    GuideView(
                        store: store.scope(state: \.drawing, action: AppAction.drawing),
                        type: .quadCurveControl,
                        position: control,
                        offset: offset,
                        isHovered: isHovered(offset: offset),
                        draggingElementOffset: $draggingElementOffset
                    )
                    Path { path in
                        path.move(to: viewStore.drawing.pathElements[offset - 1].to.applyZoomLevel(zoomLevel))
                        path.addLine(to: control.applyZoomLevel(zoomLevel))
                        path.addLine(to: to.applyZoomLevel(zoomLevel))
                    }.stroke(style: .init(dash: [5], dashPhase: 1))
                }
            case let .curve(to, control1, control2):
                ZStack {
                    GuideView(
                        store: store.scope(state: \.drawing, action: AppAction.drawing),
                        type: .to,
                        position: to,
                        offset: offset,
                        isHovered: isHovered(offset: offset),
                        draggingElementOffset: $draggingElementOffset
                    )
                    GuideView(
                        store: store.scope(state: \.drawing, action: AppAction.drawing),
                        type: .curveControl1,
                        position: control1,
                        offset: offset,
                        isHovered: isHovered(offset: offset),
                        draggingElementOffset: $draggingElementOffset
                    )
                    GuideView(
                        store: store.scope(state: \.drawing, action: AppAction.drawing),
                        type: .curveControl2,
                        position: control2,
                        offset: offset,
                        isHovered: isHovered(offset: offset),
                        draggingElementOffset: $draggingElementOffset
                    )
                    Path { path in
                        path.move(to: viewStore.drawing.pathElements[offset - 1].to.applyZoomLevel(zoomLevel))
                        path.addLine(to: control1.applyZoomLevel(zoomLevel))
                        path.addLine(to: control2.applyZoomLevel(zoomLevel))
                        path.addLine(to: to.applyZoomLevel(zoomLevel))
                    }.stroke(style: .init(dash: [5], dashPhase: 1))
                }
            }
        }
    }

    private func isHovered(offset: Int) -> Binding<Bool> {
        Binding<Bool>(
            get: { hoveredOffsets.contains(offset) },
            set: { isHovered, _ in
                if isHovered {
                    hoveredOffsets.insert(offset)
                } else {
                    hoveredOffsets.remove(offset)
                }
            }
        )
    }
}
