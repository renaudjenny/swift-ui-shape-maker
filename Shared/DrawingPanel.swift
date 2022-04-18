import SwiftUI

struct DrawingPanel: View {
    @State private var isAdding = false
    @State private var draggingElementOffset: Int?
    @Binding var pathElements: [PathElement]
    @Binding var hoveredOffsets: Set<Int>
    let selectedPathTool: PathTool
    let configuration: Configuration

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
                                    ? element(to: inBoundsPoint(value.location))
                                    : .move(to: inBoundsPoint(value.location))
                                )
                            } else {
                                pathElements[pathElements.count - 1].update(to: inBoundsPoint(value.location))
                            }
                        }
                        .onEnded { value in
                            isAdding = false
                            let lastElement = pathElements.removeLast()
                            pathElements.append(
                                pathElements.count > 0
                                ? element(to: inBoundsPoint(value.location), lastElement: lastElement)
                                : .move(to: inBoundsPoint(value.location))
                            )
                        }
                )

            Path { path in
                pathElements.forEach { path.addElement($0) }
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
                    .position(to)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.interactiveSpring()) {
                                    pathElements[offset].update(to: inBoundsPoint(value.location))
                                }
                                draggingElementOffset = offset
                            }
                            .onEnded { value in
                                pathElements[offset].update(to: inBoundsPoint(value.location))
                                withAnimation { draggingElementOffset = nil }
                            }
                    )
            case let .quadCurve(to, control):
                ZStack {
                    CircleElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(to)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(to: inBoundsPoint(value.location))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(to: inBoundsPoint(value.location))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(quadCurveControl: value.location)
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(quadCurveControl: value.location)
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    Path { path in
                        path.move(to: pathElements[offset - 1].to)
                        path.addLine(to: control)
                        path.addLine(to: to)
                    }.stroke(style: .init(dash: [5], dashPhase: 1))
                }
            case let .curve(to, control1, control2):
                ZStack {
                    CircleElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(to)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(to: inBoundsPoint(value.location))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(to: inBoundsPoint(value.location))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control1)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(curveControls: (value.location, nil))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(curveControls: (value.location, nil))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    SquareElementView(isHovered: isHovered(offset: offset), isDragged: draggingElementOffset == offset)
                        .position(control2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(curveControls: (nil, value.location))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(curveControls: (nil, value.location))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    Path { path in
                        path.move(to: pathElements[offset - 1].to)
                        path.addLine(to: control1)
                        path.addLine(to: control2)
                        path.addLine(to: to)
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
        if inBondsPoint.x > 800 {
            inBondsPoint.x = 800
        }
        if inBondsPoint.y > 800 {
            inBondsPoint.y = 800
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
