import SwiftUI

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    @State private var image: Image?
    @State private var imageOpacity = 1.0
    @State private var pathElements: [PathElement] = []
    @State private var selectedPathTool: PathTool = .line
    @State private var configuration = Configuration()
    @State private var isCodeInEditionMode = false
    @State private var hoveredOffsets = Set<Int>()
    @State private var zoomLevel: Double = 1
    @State private var lastZoomGestureDelta: CGFloat?

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Slider(value: $imageOpacity) { Text("Image opacity") }
                    Button("Choose an image") { openImagePicker() }
                    HStack {
                        Slider(value: $zoomLevel, in: 0.10...2) { Text("Zoom level") }
                        Text("\(Int(zoomLevel * 100))%")
                    }
                }
                HStack {
                    Picker("Tool", selection: $selectedPathTool) {
                        Text("Move").tag(PathTool.move)
                        Text("Line").tag(PathTool.line)
                        Text("Quad curve").tag(PathTool.quadCurve)
                        Text("Curve").tag(PathTool.curve)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 300)
                    Toggle("Display path indicators", isOn: $configuration.isPathIndicatorsDisplayed)
                    Spacer()
                }
            }
            .padding()
            HStack {
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        DrawingPanel(
                            pathElements: $pathElements,
                            hoveredOffsets: $hoveredOffsets,
                            zoomLevel: $zoomLevel,
                            selectedPathTool: selectedPathTool,
                            configuration: configuration
                        )
                        image?
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(imageOpacity)
                            .allowsHitTesting(false)
                    }
                    .frame(width: DrawingPanel.defaultWidth * zoomLevel, height: DrawingPanel.defaultWidth * zoomLevel)
                    .padding(.horizontal, 64)
                    .padding(.vertical, 32)
                }
                .onHover { isHovered in
                    if isHovered {
                        isCodeInEditionMode = false
                    }
                }
                .highPriorityGesture(MagnificationGesture()
                    .onChanged { scale in
                        let delta = scale - (lastZoomGestureDelta ?? 1)
                        zoomLevel += delta
                        lastZoomGestureDelta = scale
                    }
                    .onEnded { _ in
                        lastZoomGestureDelta = nil
                    }
                )

                CodeView(
                    pathElements: $pathElements,
                    hoveredOffsets: $hoveredOffsets,
                    isInEditionMode: $isCodeInEditionMode
                )
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

    private func replaceElementsOnZoomChanged(_ isZoomChanged: Bool) {
        pathElements = pathElements.map {
            var newPathElement = $0
            newPathElement.applyZoomLevel(zoomLevel)
            return newPathElement
        }
    }
}

private extension PathElement {
    mutating func applyZoomLevel(_ zoomLevel: CGFloat) {
        switch self {
        case let .move(to), let .line(to):
            self.update(to: to.applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel)))
        case let .quadCurve(to, control):
            self.update(
                to: to.applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel)),
                quadCurveControl: control.applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel))
            )
        case let .curve(to, control1, control2):
            self.update(
                to: to.applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel)),
                curveControls: (
                    control1.applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel)),
                    control2.applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel))
                )
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
