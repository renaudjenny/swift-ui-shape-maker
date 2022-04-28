import SwiftUI
import Combine

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
    @State private var cancellables = Set<AnyCancellable>()

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
                    .frame(
                        width: DrawingPanel.standardWidth * zoomLevel,
                        height: DrawingPanel.standardWidth * zoomLevel
                    )
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
                        clampZoomLevel(add: delta)
                        lastZoomGestureDelta = scale
                    }
                    .onEnded { _ in
                        lastZoomGestureDelta = nil
                    }
                )
                .task {
                    #if os(macOS)
                    NSApp.publisher(for: \.currentEvent)
                        .filter {
                            $0?.type == .scrollWheel
                            && ($0?.modifierFlags.contains(.command) ?? false)
                        }
                        .compactMap { $0 }
                        .sink {
                            clampZoomLevel(add: $0.deltaY/100)
                        }
                        .store(in: &cancellables)
                    #endif
                }

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

    private func clampZoomLevel(add delta: CGFloat) {
        switch zoomLevel + delta {
        case 4...:
            zoomLevel = 4
        case ...0.10:
            zoomLevel = 0.10
        default:
            zoomLevel += delta
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
