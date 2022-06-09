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
        WithViewStore(store) { viewStore in
            let zoomLevel = viewStore.zoomLevel
            ForEachStore(store.scope(state: \.pathElements, action: DrawingAction.pathElement(id:action:))) { store in
                WithViewStore(store) { viewStore in
                    switch viewStore.type {
                    case .move, .line:
                        GuideView(store: store, type: .to, position: viewStore.segment.endPoint, zoomLevel: zoomLevel)
                    case let .quadCurve(control):
                        quadCurveGuides(store: store, control: control, zoomLevel: zoomLevel)
                    case let .curve(control1, control2):
                        curveGuides(store: store, control1: control1, control2: control2, zoomLevel: zoomLevel)
                    }
                }
            }
        }
    }

    private func quadCurveGuides(
        store: Store<PathElement, PathElementAction>,
        control: CGPoint,
        zoomLevel: Double
    ) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                GuideView(store: store, type: .to, position: viewStore.segment.endPoint, zoomLevel: zoomLevel)
                GuideView(store: store, type: .quadCurveControl, position: control, zoomLevel: zoomLevel)
                Path { path in
                    path.move(to: viewStore.segment.startPoint.applyZoomLevel(zoomLevel))
                    path.addLine(to: control.applyZoomLevel(zoomLevel))
                    path.addLine(to: viewStore.segment.endPoint.applyZoomLevel(zoomLevel))
                }.stroke(style: .init(dash: [5], dashPhase: 1))
            }
        }
    }

    @ViewBuilder
    private func curveGuides(
        store: Store<PathElement, PathElementAction>,
        control1: CGPoint,
        control2: CGPoint,
        zoomLevel: Double
    ) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                GuideView(store: store, type: .to, position: viewStore.segment.endPoint, zoomLevel: zoomLevel)
                GuideView(store: store, type: .curveControl1, position: control1, zoomLevel: zoomLevel)
                GuideView(store: store, type: .curveControl2, position: control2, zoomLevel: zoomLevel)
                Path { path in
                    path.move(to: viewStore.segment.startPoint.applyZoomLevel(zoomLevel))
                    path.addLine(to: control1.applyZoomLevel(zoomLevel))
                    path.addLine(to: control2.applyZoomLevel(zoomLevel))
                    path.addLine(to: viewStore.segment.endPoint.applyZoomLevel(zoomLevel))
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
