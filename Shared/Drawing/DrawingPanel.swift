import SwiftUI
import ComposableArchitecture

struct DrawingPanel: View {
    let store: Store<AppState, AppAction>
    @State private var draggingID: PathElement.ID?
    @Binding var hoveredIDs: Set<PathElement.ID>

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

    private func pathIndicators(viewStore: ViewStore<AppState, AppAction>) -> some View {
        ForEach(viewStore.drawing.pathElements) { element in
            switch element.type {
            case let .move(to), let .line(to):
                moveAndLineGuide(to: to, id: element.id)
            case let .quadCurve(to, control):
                quadCurveGuides(to: to, control: control, id: element.id, viewStore: viewStore)
            case let .curve(to, control1, control2):
                curveGuides(to: to, control1: control1, control2: control2, id: element.id, viewStore: viewStore)
            }
        }
    }

    private func moveAndLineGuide(to: CGPoint, id: PathElement.ID) -> some View {
        GuideView(
            store: store.scope(state: \.drawing, action: AppAction.drawing),
            type: .to,
            position: to,
            id: id,
            isHovered: isHovered(id: id),
            draggingID: $draggingID
        )
    }

    @ViewBuilder
    private func quadCurveGuides(
        to: CGPoint,
        control: CGPoint,
        id: PathElement.ID,
        viewStore: ViewStore<AppState, AppAction>
    ) -> some View {
        let previousTo = viewStore.drawing.pathElements.previous(of: id).to
        let zoomLevel = viewStore.drawing.zoomLevel
        ZStack {
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .to,
                position: to,
                id: id,
                isHovered: isHovered(id: id),
                draggingID: $draggingID
            )
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .quadCurveControl,
                position: control,
                id: id,
                isHovered: isHovered(id: id),
                draggingID: $draggingID
            )
            Path { path in
                path.move(to: previousTo.applyZoomLevel(zoomLevel))
                path.addLine(to: control.applyZoomLevel(zoomLevel))
                path.addLine(to: to.applyZoomLevel(zoomLevel))
            }.stroke(style: .init(dash: [5], dashPhase: 1))
        }
    }

    @ViewBuilder
    private func curveGuides(
        to: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        id: PathElement.ID,
        viewStore: ViewStore<AppState, AppAction>
    ) -> some View {
        let previousTo = viewStore.drawing.pathElements.previous(of: id).to
        let zoomLevel = viewStore.drawing.zoomLevel
        ZStack {
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .to,
                position: to,
                id: id,
                isHovered: isHovered(id: id),
                draggingID: $draggingID
            )
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .curveControl1,
                position: control1,
                id: id,
                isHovered: isHovered(id: id),
                draggingID: $draggingID
            )
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .curveControl2,
                position: control2,
                id: id,
                isHovered: isHovered(id: id),
                draggingID: $draggingID
            )
            Path { path in
                path.move(to: previousTo.applyZoomLevel(zoomLevel))
                path.addLine(to: control1.applyZoomLevel(zoomLevel))
                path.addLine(to: control2.applyZoomLevel(zoomLevel))
                path.addLine(to: to.applyZoomLevel(zoomLevel))
            }.stroke(style: .init(dash: [5], dashPhase: 1))
        }
    }

    private func isHovered(id: PathElement.ID) -> Binding<Bool> {
        Binding<Bool>(
            get: { hoveredIDs.contains(id) },
            set: { isHovered, _ in
                if isHovered {
                    hoveredIDs.insert(id)
                } else {
                    hoveredIDs.remove(id)
                }
            }
        )
    }
}

private extension IdentifiedArray where ID == PathElement.ID, Element == PathElement {
    func previous(of id: PathElement.ID) -> Element {
        guard let currentElement = self[id: id] else {
            fatalError("Cannot get the current element in IdentifiedArray")
        }
        guard let currentIndex = elements.firstIndex(of: currentElement) else {
            fatalError("Cannot get the current index in IdentifiedArray")
        }
        guard elements.count > currentIndex - 1 else {
            fatalError("Cannot access to current index - 1 in IdentifiedArray")
        }
        return elements[currentIndex - 1]
    }
}
