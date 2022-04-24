import SwiftUI

struct DrawingPanel: View {
    @State private var isAdding = false
    @State private var draggingElementOffset: Int?
    @Binding var pathElements: [PathElement]
    @Binding var hoveredOffsets: Set<Int>
    @Binding var zoomLevel: Double
    let selectedPathTool: PathTool
    let configuration: Configuration

    static let standardWidth: CGFloat = 1000

    var body: some View {
        ZStack {
            Color.white
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isAdding {
                                isAdding = true
                                pathElements.append(
                                    pathElements.count > 0
                                    ? element(to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel)))
                                    : .move(to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel)))
                                )
                            } else {
                                pathElements[pathElements.count - 1].update(
                                    to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                )
                            }
                        }
                        .onEnded { value in
                            isAdding = false
                            let lastElement = pathElements.removeLast()
                            pathElements.append(
                                pathElements.count > 0
                                ? element(
                                    to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel)),
                                    lastElement: lastElement
                                )
                                : .move(to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel)))
                            )
                        }
                )

            Path { path in
                pathElements.forEach { path.addElement($0, zoomLevel: zoomLevel) }
            }
            .stroke()

            if configuration.isPathIndicatorsDisplayed {
                pathIndicators()
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func pathIndicators() -> some View {
        ForEach(Array(pathElements.enumerated()), id: \.offset) { offset, element in
            switch element {
            case let .move(to), let .line(to):
                CircleElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                    .position(to.applyZoomLevel(zoomLevel))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.interactiveSpring()) {
                                    pathElements[offset].update(
                                        to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                    )
                                }
                                draggingElementOffset = offset
                            }
                            .onEnded { value in
                                pathElements[offset].update(
                                    to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                )
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
                                        pathElements[offset].update(
                                            to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                        )
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(
                                        to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                    )
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(
                                            quadCurveControl: value.location.applyZoomLevel(1/zoomLevel)
                                        )
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(
                                        quadCurveControl: value.location.applyZoomLevel(1/zoomLevel)
                                    )
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    Path { path in
                        path.move(to: pathElements[offset - 1].to.applyZoomLevel(zoomLevel))
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
                                        pathElements[offset].update(
                                            to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                        )
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(
                                        to: inBoundsPoint(value.location.applyZoomLevel(1/zoomLevel))
                                    )
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control1.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(
                                            curveControls: (value.location.applyZoomLevel(1/zoomLevel), nil)
                                        )
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(
                                        curveControls: (value.location.applyZoomLevel(1/zoomLevel), nil)
                                    )
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control2.applyZoomLevel(zoomLevel))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(
                                            curveControls: (nil, value.location.applyZoomLevel(1/zoomLevel))
                                        )
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(
                                        curveControls: (nil, value.location.applyZoomLevel(1/zoomLevel))
                                    )
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    Path { path in
                        path.move(to: pathElements[offset - 1].to.applyZoomLevel(zoomLevel))
                        path.addLine(to: control1.applyZoomLevel(zoomLevel))
                        path.addLine(to: control2.applyZoomLevel(zoomLevel))
                        path.addLine(to: to.applyZoomLevel(zoomLevel))
                    }.stroke(style: .init(dash: [5], dashPhase: 1))
                }
            }
        }
    }

    private func element(to: CGPoint, lastElement: PathElement? = nil) -> PathElement {
        switch selectedPathTool {
        case .move: return .move(to: to)
        case .line: return .line(to: to)
        case .quadCurve:
            guard let lastPoint = pathElements.last?.to else { return .line(to: to) }
            if case let .quadCurve(_, control) = lastElement {
                return .quadCurve(to: to, control: control)
            }
            let x = (to.x + lastPoint.x) / 2
            let y = (to.y + lastPoint.y) / 2
            let control = CGPoint(x: x - 20, y: y - 20)
            return .quadCurve(to: to, control: control)
        case .curve:
            guard let lastPoint = pathElements.last?.to else { return .line(to: to) }
            if case let .curve(_, control1, control2) = lastElement {
                return .curve(to: to, control1: control1, control2: control2)
            }
            let x = (to.x + lastPoint.x) / 2
            let y = (to.y + lastPoint.y) / 2
            let control1 = CGPoint(x: (lastPoint.x + x) / 2 - 20, y: (lastPoint.y + y) / 2 - 20)
            let control2 = CGPoint(x: (x + to.x) / 2 + 20, y: (y + to.y) / 2 + 20)
            return .curve(to: to, control1: control1, control2: control2)
        }
    }

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
