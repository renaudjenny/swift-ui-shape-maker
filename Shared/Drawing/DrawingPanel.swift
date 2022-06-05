import SwiftUI
import ComposableArchitecture

struct DrawingPanel: View {
    let store: Store<AppState, AppAction>

    static let standardWidth: CGFloat = 1000

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.white
                    .overlay(viewStore.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(viewStore.imageOpacity)
                        .allowsHitTesting(false)
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { viewStore.send(.drawing(.addOrMovePathElement(to: $0.location))) }
                            .onEnded { _ in viewStore.send(.drawing(.endMove)) }
                    )

                DrawingPath(store: store.scope(state: \.drawingState).actionless)

                if viewStore.configuration.isPathIndicatorsDisplayed {
                    pathIndicators(store: store.scope(state: \.drawingState, action: AppAction.drawing))
                }
            }
        }
    }

    @ViewBuilder
    private func pathIndicators(store: Store<BaseState<DrawingState>, DrawingAction>) -> some View {
        ForEachStore(store.scope(state: \.pathElements, action: DrawingAction.pathElement(id:action:))) { store in
            WithViewStore(store) { viewStore in
                switch viewStore.type {
                case .move, .line:
                    GuideView(store: store, type: .to, position: viewStore.segment.endPoint)
                case let .quadCurve(control):
                    quadCurveGuides(store: store, to: viewStore.segment.endPoint, control: control)
                case let .curve(control1, control2):
                    curveGuides(store: store, to: viewStore.segment.endPoint, control1: control1, control2: control2)
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
                    path.move(to: viewStore.segment.startPoint.applyZoomLevel(viewStore.zoomLevel))
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
                    path.move(to: viewStore.segment.startPoint.applyZoomLevel(viewStore.zoomLevel))
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

private extension AppState {
    var image: Image? {
        #if os(macOS)
        imageData.flatMap { NSImage(data: $0).map { Image(nsImage: $0) } }
        #else
        imageData.flatMap { UIImage(data: $0).map { Image(uiImage: $0) } }
        #endif
    }
}
