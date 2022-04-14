import SwiftUI

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    @State private var image: Image? = nil
    @State private var imageOpacity = 1.0
    @State private var codeLines: [AnyView] = []

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
                        DrawingPanel(codeLines: $codeLines)
                        image?
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(imageOpacity)
                    }
                    .frame(width: 800, height: 800)
                    .padding()
                }
                VStack {
                    ForEach(Array(codeLines.enumerated()), id: \.offset) { offset, code in
                        code
                    }
                }
            }
        }
    }

    func openImagePicker() {
        #if os(macOS)
        let pictureTaker = IKPictureTaker.pictureTaker()
        pictureTaker?.runModal()
        pictureTaker?.outputImage().map { image = Image(nsImage: $0) }
        #endif
    }
}

struct DrawingPanel: View {
    @State private var tapGesturePoint: CGPoint = .zero {
        didSet { updateCode() }
    }
    @State private var points: [CGPoint] = [] {
        didSet { updateCode() }
    }
    @State private var hoveredPointsIndexes: Set<Int> = Set() {
        didSet { updateCode() }
    }
    @Binding var codeLines: [AnyView]

    private var hoveredPointIndex: Int? { hoveredPointsIndexes.first }

    var body: some View {
        ZStack {
            Color.white
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring()) { tapGesturePoint = value.location }
                        }
                        .onEnded { _ in
                            points.append(tapGestureStandardizedPosition)
                            tapGesturePoint = .zero
                        }
                )

            Path { path in
                points.first.map { path.move(to: $0) }
                points.forEach { path.addLine(to: $0) }
            }.stroke()

            if tapGesturePoint != .zero {
                Circle()
                    .frame(width: 10, height: 10)
                    .position(tapGestureStandardizedPosition)
            }

            ForEach(Array(points.enumerated()), id: \.offset) { offset, point in
                Circle()
                    .frame(width: hoveredPointIndex == offset ? 10 : 5)
                    .onHover { isHovered in
                        withAnimation(.easeInOut) {
                            if isHovered {
                                hoveredPointsIndexes.insert(offset)
                            } else {
                                hoveredPointsIndexes.remove(offset)
                            }
                        }
                    }
                    .position(point)
            }
        }
    }

    private var tapGestureStandardizedPosition: CGPoint {
        var standardizedPoint = tapGesturePoint
        if standardizedPoint.x < 0 {
            standardizedPoint.x = 0
        }
        if standardizedPoint.y < 0 {
            standardizedPoint.y = 0
        }
        if standardizedPoint.x > 800 {
            standardizedPoint.x = 800
        }
        if standardizedPoint.y > 800 {
            standardizedPoint.y = 800
        }
        return standardizedPoint
    }

    private func updateCode() {
        let pointsCode = points.enumerated().map { offset, point -> AnyView in
            let pointInCode = pointInCode(point)
            return AnyView(
                Text("""
                path.addLine(to: CGPoint(
                    x: rect.midX \(pointInCode.xSign) width * \(pointInCode.x)/1000,
                    y: rect.midY \(pointInCode.ySign) width * \(pointInCode.y)/1000
                )
                """)
                .scaleEffect(offset == hoveredPointIndex ? 1.1 : 1)
                .onHover { isHovered in
                    withAnimation(.easeInOut) {
                        if isHovered {
                            hoveredPointsIndexes.insert(offset)
                        } else {
                            hoveredPointsIndexes.remove(offset)
                        }
                    }
                }
            )
        }

        if tapGesturePoint != .zero {
            let dragPointInCode = pointInCode(tapGesturePoint)
            codeLines = pointsCode + [AnyView(Text("")), AnyView(Text("""
            path.addLine(to: CGPoint(
                x: rect.midX \(dragPointInCode.xSign) width * \(dragPointInCode.x)/1000,
                y: rect.midY \(dragPointInCode.ySign) width * \(dragPointInCode.y)/1000
            )
            """).bold())]
        } else {
            codeLines = pointsCode
        }
    }

    private func pointInCode(_ point: CGPoint) -> (x: Int, y: Int, xSign: String, ySign: String) {
        let x = abs(point.x - 400) * 10/8
        let y = abs(point.y - 400) * 10/8
        let xSign = point.x > 400 ? "+" : "-"
        let ySign = point.y > 400 ? "-" : "+"
        return (Int(x.rounded()), Int(y.rounded()), xSign, ySign)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
