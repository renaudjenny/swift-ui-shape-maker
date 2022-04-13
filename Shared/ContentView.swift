import SwiftUI

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    @State private var image: Image? = nil
    @State private var imageOpacity = 1.0
    @State private var code: String = "Code"

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
                        DrawingPanel(code: $code)
                        image?
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(imageOpacity)
                    }
                    .frame(width: 800, height: 800)
                    .padding()
                }
                Text(code).frame(maxWidth: .infinity)
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
    @State private var tapGesturePoint: CGPoint = .zero
    @State private var points: [CGPoint] = [] {
        didSet { updateCode() }
    }
    @Binding var code: String

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
                        }
                )

            if tapGesturePoint != .zero {
                Circle()
                    .frame(width: 10, height: 10)
                    .position(tapGestureStandardizedPosition)
            }

            ForEach(Array(points.enumerated()), id: \.offset) { offset, point in
                Circle()
                    .frame(width: 5, height: 5)
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
        code = points.map { point in
            let x = abs(point.x - 400) * 10/8
            let y = abs(point.y - 400) * 10/8
            let xSign = point.x > 400 ? "+" : "-"
            let ySign = point.y > 400 ? "-" : "+"
            return """
            path.addLine(to: CGPoint(
                x: rect.midX \(xSign) width * \(Int(x.rounded()))/1000,
                y: rect.midY \(ySign) width * \(Int(y.rounded()))/1000
            )
            """
        }.joined(separator: "\n")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
