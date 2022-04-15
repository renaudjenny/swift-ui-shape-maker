import SwiftUI

#if os(macOS)
import Quartz
#endif

enum PathElement {
    case move(to: CGPoint)
    case line(to: CGPoint)

    mutating func update(to: CGPoint) {
        switch self {
        case .move: self = .move(to: to)
        case .line: self = .line(to: to)
        }
    }
}

struct ContentView: View {
    @State private var image: Image? = nil
    @State private var imageOpacity = 1.0
    @State private var pathElements: [PathElement] = []

    var body: some View {
        VStack {
            HStack {
                Slider(value: $imageOpacity) { Text("Image opacity") }
                Button("Choose an image") { openImagePicker() }
            }
            .padding()
            HStack {
                ZStack {
                    ZStack {
                        DrawingPanel(pathElements: $pathElements)
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
        }
    }

    private func pointForCode(_ point: CGPoint) -> String {
        let x = abs(point.x - 400) * 10/8
        let y = abs(point.y - 400) * 10/8
        let xSign = point.x > 400 ? "+" : "-"
        let ySign = point.y > 400 ? "-" : "+"
        return """
        CGPoint(
                        x: rect.midX \(xSign) width * \(x)/1000,
                        y: rect.midY \(ySign) width * \(y)/1000
                    )
        """
    }
}

struct DrawingPanel: View {
    @State private var isAdding = false
    @State private var draggingElementOffset: Int?
    @Binding var pathElements: [PathElement]

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
                                        ? .line(to: inBoundsPoint(value.location))
                                        : .move(to: inBoundsPoint(value.location))
                                )
                            } else {
                                pathElements[pathElements.count - 1].update(to: inBoundsPoint(value.location))
                            }
                        }
                        .onEnded { value in
                            isAdding = false
                            pathElements.removeLast()
                            pathElements.append(
                                pathElements.count > 0
                                    ? .line(to: inBoundsPoint(value.location))
                                    : .move(to: inBoundsPoint(value.location))
                            )
                        }
                )

            Path { path in
                pathElements.forEach { path.addElement($0) }
            }
            .stroke()

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
                }
            }
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

private extension Path {
    mutating func addElement(_ element: PathElement) {
        switch element {
        case let .move(to):
            move(to: to)
        case let .line(to):
            addLine(to: to)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
