import SwiftUI
import ComposableArchitecture

struct DrawingPanel: View {
    let store: Store<AppState, AppAction>

    static let standardWidth: CGFloat = 1000

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.white
                    .gesture(
                        DragGesture()
                            .onChanged { viewStore.send(.drawing(.addOrMovePathElement(to: $0.location))) }
                            .onEnded { _ in viewStore.send(.drawing(.endMove)) }
                    )

                path(store: store.scope(state: \.drawing, action: AppAction.drawing))

                if viewStore.configuration.isPathIndicatorsDisplayed {
                    pathIndicators(store: store.scope(state: \.drawing, action: AppAction.drawing))
                }
            }
        }
    }

    private func path(store: Store<DrawingState, DrawingAction>) -> some View {
        WithViewStore(store) { viewStore in
            Path { path in
                viewStore.pathElements.forEach {
                    path.addElement($0, zoomLevel: viewStore.zoomLevel)
                }
            }.stroke()
        }
    }

    @ViewBuilder
    private func pathIndicators(store: Store<DrawingState, DrawingAction>) -> some View {
        ForEachStore(store.scope(state: \.pathElements, action: DrawingAction.pathElement(id:action:))) { store in
            WithViewStore(store) { viewStore in
                switch viewStore.type {
                case let .move(to), let .line(to):
                    GuideView(store: store, type: .to, position: to)
                case let .quadCurve(to, control):
                    quadCurveGuides(store: store, to: to, control: control)
                case let .curve(to, control1, control2):
                    curveGuides(store: store, to: to, control1: control1, control2: control2)
                }
            }
        }
    }

    private func quadCurveGuides(
        store: Store<PathElement, PathElementAction>,
        to: CGPoint,
        control: CGPoint
    ) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                GuideView(store: store, type: .to, position: to)
                GuideView(store: store, type: .quadCurveControl, position: control)
                Path { path in
                    path.move(to: viewStore.previousTo.applyZoomLevel(viewStore.zoomLevel))
                    path.addLine(to: control.applyZoomLevel(viewStore.zoomLevel))
                    path.addLine(to: to.applyZoomLevel(viewStore.zoomLevel))
                }.stroke(style: .init(dash: [5], dashPhase: 1))
            }
        }
    }

    @ViewBuilder
    private func curveGuides(
        store: Store<PathElement, PathElementAction>,
        to: CGPoint,
        control1: CGPoint,
        control2: CGPoint
    ) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                GuideView(store: store, type: .to, position: to)
                GuideView(store: store, type: .curveControl1, position: control1)
                GuideView(store: store, type: .curveControl2, position: control2)
                Path { path in
                    path.move(to: viewStore.previousTo.applyZoomLevel(viewStore.zoomLevel))
                    path.addLine(to: control1.applyZoomLevel(viewStore.zoomLevel))
                    path.addLine(to: control2.applyZoomLevel(viewStore.zoomLevel))
                    path.addLine(to: to.applyZoomLevel(viewStore.zoomLevel))
                }.stroke(style: .init(dash: [5], dashPhase: 1))
            }
        }
    }
}

extension DrawingPanel {
    static func inBoundsPoint(_ point: CGPoint) -> CGPoint {
        var inBondsPoint = point
        if inBondsPoint.x < 0 {
            inBondsPoint.x = 0
        }
        if inBondsPoint.y < 0 {
            inBondsPoint.y = 0
        }
        if inBondsPoint.x > DrawingPanel.standardWidth {
            inBondsPoint.x = DrawingPanel.standardWidth
        }
        if inBondsPoint.y > DrawingPanel.standardWidth {
            inBondsPoint.y = DrawingPanel.standardWidth
        }
        return inBondsPoint
    }
}
