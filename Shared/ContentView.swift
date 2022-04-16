import SwiftUI

#if os(macOS)
import Quartz
#endif

enum PathTool: CaseIterable, Identifiable {
    case move
    case line
    case quadCurve

    var id: Int { hashValue }
}

enum PathElement {
    case move(to: CGPoint)
    case line(to: CGPoint)
    case quadCurve(to: CGPoint, control: CGPoint)

    var to: CGPoint {
        switch self {
        case let .move(to), let .line(to), let .quadCurve(to: to, _):
            return to
        }
    }

    mutating func update(to newTo: CGPoint? = nil, control newControl: CGPoint? = nil) {
        switch self {
        case let .move(to):
            self = .move(to: newTo ?? to)
        case let .line(to):
            self = .line(to: newTo ?? to)
        case let .quadCurve(to: to, control: control):
            self = .quadCurve(to: newTo ?? to, control: newControl ?? control)
        }
    }
}

struct ContentView: View {
    @State private var image: Image?
    @State private var imageOpacity = 1.0
    @State private var pathElements: [PathElement] = []
    @State private var selectedPathTool: PathTool = .line
    @State private var configuration = Configuration()

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Slider(value: $imageOpacity) { Text("Image opacity") }
                    Button("Choose an image") { openImagePicker() }
                }
                HStack {
                    Picker("Tool", selection: $selectedPathTool) {
                        Text("Move").tag(PathTool.move)
                        Text("Line").tag(PathTool.line)
                        Text("Quad curve").tag(PathTool.quadCurve)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 300)
                    Toggle("Display path indicators", isOn: $configuration.isPathIndicatorsDisplayed)
                    Spacer()
                }
            }
            .padding()
            HStack {
                ZStack {
                    ZStack {
                        DrawingPanel(
                            pathElements: $pathElements,
                            selectedPathTool: selectedPathTool,
                            configuration: configuration
                        )
                        image?
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(imageOpacity)
                    }
                    .frame(width: 800, height: 800)
                    .padding()
                }

                TextEditor(text: code)
                    .font(.body.monospaced())
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    private func openImagePicker() {
        #if os(macOS)
        let pictureTaker = IKPictureTaker.pictureTaker()
        pictureTaker?.runModal()
        pictureTaker?.outputImage().map { image = Image(nsImage: $0) }
        #endif
    }

    private var code: Binding<String> {
        Binding<String>(
            get: { """
            import SwiftUI

            struct MyShape: Shape {
                func path(in rect: CGRect) -> Path {
                    var path = Path()
                    let width = min(rect.width, rect.height)

                    \(pathElements.map(code).joined(separator: "\n"))

                    return path
                }
            }
            """ },
            set: { _, _ in }
        )
    }

    // swiftlint:disable indentation_width
    private func code(fromPathElement pathElement: PathElement) -> String {
        switch pathElement {
        case let .move(to):
            return """
            path.move(
                        to: \(pointForCode(to))
                    )
            """
        case let .line(to):
            return """
                    path.addPoint(
                        to: \(pointForCode(to))
                    )
            """
        case let .quadCurve(to, control):
            return """
                    path.addQuadCurve(
                        to: \(pointForCode(to)),
                        control: \(pointForCode(control))
                    )
            """
        }
    }
    // swiftlint: enable identation_width

    private func pointForCode(_ point: CGPoint) -> String {
        let x = abs(point.x - 400) * 10/8
        let y = abs(point.y - 400) * 10/8
        let xSign = point.x > 400 ? "+" : "-"
        let ySign = point.y > 400 ? "-" : "+"
        return """
        CGPoint(
                        x: rect.midX \(xSign) width * \(Int(x.rounded()))/1000,
                        y: rect.midY \(ySign) width * \(Int(y.rounded()))/1000
                    )
        """
    }
}

struct DrawingPanel: View {
    @State private var isAdding = false
    @State private var draggingElementOffset: Int?
    @Binding var pathElements: [PathElement]
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
                CircleElementView(isDragged: draggingElementOffset == offset)
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
                    CircleElementView(isDragged: draggingElementOffset == offset)
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
                    SquareElementView(isDragged: draggingElementOffset == offset)
                        .position(control)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        pathElements[offset].update(control: inBoundsPoint(value.location))
                                    }
                                    draggingElementOffset = offset
                                }
                                .onEnded { value in
                                    pathElements[offset].update(control: inBoundsPoint(value.location))
                                    withAnimation { draggingElementOffset = nil }
                                }
                        )
                    Path { path in
                        path.move(to: control)
                        path.addLine(to: to)
                        path.move(to: control)
                        path.addLine(to: pathElements[offset - 1].to)
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
}

private struct CircleElementView: View {
    @State private var isHovered = false
    let isDragged: Bool

    var body: some View {
        Circle()
            .frame(width: 5, height: 5)
            .padding()
            .contentShape(Rectangle())
            .onHover { hover in
                withAnimation(isHovered || isDragged ? nil : .easeInOut) {
                    isHovered = hover
                }
            }
            .scaleEffect(isHovered || isDragged ? 2 : 1)
    }
}

private struct SquareElementView: View {
    @State private var isHovered = false
    let isDragged: Bool

    var body: some View {
        Rectangle()
            .frame(width: 5, height: 5)
            .padding()
            .contentShape(Rectangle())
            .onHover { hover in
                withAnimation(isHovered || isDragged ? nil : .easeInOut) {
                    isHovered = hover
                }
            }
            .scaleEffect(isHovered || isDragged ? 2 : 1)
    }
}

private extension Path {
    mutating func addElement(_ element: PathElement) {
        switch element {
        case let .move(to):
            move(to: to)
        case let .line(to):
            addLine(to: to)
        case let .quadCurve(to, control):
            addQuadCurve(to: to, control: control)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
