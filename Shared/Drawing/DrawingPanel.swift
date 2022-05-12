import SwiftUI
import ComposableArchitecture

struct DrawingPanel: View {
    let store: Store<AppState, AppAction>
    @State private var draggingID: PathElement.ID?

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
        ForEachStore(store.scope(state: \.drawing.pathElements, action: /AppAction.drawing(.pathElement))) { store in
            WithViewStore(store) { viewStore in
                switch viewStore.element.type {
                case let .move(to), let .line(to):
                    moveAndLineGuide(to: to, id: viewStore.id, viewStore: viewStore)
                case let .quadCurve(to, control):
                    quadCurveGuides(to: to, control: control, id: viewStore.id, viewStore: viewStore)
                case let .curve(to, control1, control2):
                    curveGuides(to: to, control1: control1, control2: control2, id: viewStore.id, viewStore: viewStore)
                }
            }
        }
    }

    private func moveAndLineGuide(
        to: CGPoint,
        id: PathElement.ID,
        viewStore: ViewStore<AppState, AppAction>
    ) -> some View {
        GuideView(
            store: store.scope(state: \.drawing, action: AppAction.drawing),
            type: .to,
            position: to,
            id: id,
            isHovered: isHovered(id: id, viewStore: viewStore)
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
                isHovered: isHovered(id: id, viewStore: viewStore)
            )
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .quadCurveControl,
                position: control,
                id: id,
                isHovered: isHovered(id: id, viewStore: viewStore)
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
                isHovered: isHovered(id: id, viewStore: viewStore)
            )
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .curveControl1,
                position: control1,
                id: id,
                isHovered: isHovered(id: id, viewStore: viewStore)
            )
            GuideView(
                store: store.scope(state: \.drawing, action: AppAction.drawing),
                type: .curveControl2,
                position: control2,
                id: id,
                isHovered: isHovered(id: id, viewStore: viewStore)
            )
            Path { path in
                path.move(to: previousTo.applyZoomLevel(zoomLevel))
                path.addLine(to: control1.applyZoomLevel(zoomLevel))
                path.addLine(to: control2.applyZoomLevel(zoomLevel))
                path.addLine(to: to.applyZoomLevel(zoomLevel))
            }.stroke(style: .init(dash: [5], dashPhase: 1))
        }
    }

    private func isHovered(id: PathElement.ID, viewStore: ViewStore<AppState, AppAction>) -> Binding<Bool> {
        Binding<Bool>(
            get: { viewStore.drawing.hoveredPathElementID == id },
            set: { isHovered, _ in
                if isHovered {
                    viewStore.send(.drawing(.updateHoveredPathElement(id: id)))
                } else {
                    viewStore.send(.drawing(.updateHoveredPathElement(id: nil)))
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
