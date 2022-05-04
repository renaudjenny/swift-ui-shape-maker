import SwiftUI
import ComposableArchitecture

struct DrawingPanel: View {
    let store: Store<AppState, AppAction>
    @State private var isAdding = false
    @State private var draggingElementOffset: Int?
    @Binding var hoveredOffsets: Set<Int>
    @Binding var zoomLevel: Double
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
                    viewStore.drawing.pathElements.forEach { path.addElement($0, zoomLevel: zoomLevel) }
                }
                .stroke()

                if viewStore.configuration.isPathIndicatorsDisplayed {
                    pathIndicators(viewStore: viewStore)
                }
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func pathIndicators(viewStore: ViewStore<AppState, AppAction>) -> some View {
        ForEach(Array(viewStore.drawing.pathElements.enumerated()), id: \.offset) { offset, element in
            switch element {
            case let .move(to), let .line(to):
                CircleElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                    .position(to.applyZoomLevel(zoomLevel))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.interactiveSpring()) {
                                    viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                        at: offset,
                                        to: value.location
                                    ))))
                                }
                                draggingElementOffset = offset
                            }
                            .onEnded { value in
                                viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                    at: offset,
                                    to: value.location
                                ))))
                                withAnimation { draggingElementOffset = nil }
                            }
                    )
            case let .quadCurve(to, control):
                ZStack {
                    CircleElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(to.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                            at: offset,
                                            to: value.location
                                        ))))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                        at: offset,
                                        to: value.location
                                    ))))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                            at: offset,
                                            quadCurveControl: value.location
                                        ))))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                        at: offset,
                                        quadCurveControl: value.location
                                    ))))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    Path { path in
                        path.move(to: viewStore.drawing.pathElements[offset - 1].to.applyZoomLevel(zoomLevel))
                        path.addLine(to: control.applyZoomLevel(zoomLevel))
                        path.addLine(to: to.applyZoomLevel(zoomLevel))
                    }.stroke(style: .init(dash: [5], dashPhase: 1))
                }
            case let .curve(to, control1, control2):
                ZStack {
                    CircleElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(to.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                            at: offset,
                                            to: value.location
                                        ))))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                        at: offset,
                                        to: value.location
                                    ))))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control1.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                            at: offset,
                                            curveControls: (value.location, nil)
                                        ))))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                        at: offset,
                                        curveControls: (value.location, nil)
                                    ))))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control2.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                            at: offset,
                                            curveControls: (nil, value.location)
                                        ))))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    viewStore.send(.drawing(.updatePathElement(UpdatePathElement(
                                        at: offset,
                                        curveControls: (nil, value.location)
                                    ))))
                                    withAnimation { draggingElementOffset = nil }
                                }
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

    // TODO: move this to the Core code
    private func inBoundsPoint(_ point: CGPoint) -> CGPoint {
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
