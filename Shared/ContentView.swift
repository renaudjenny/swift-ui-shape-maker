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
                ZStack {
                    ZStack {
                        DrawingPanel(
                            pathElements: $pathElements,
                            hoveredOffsets: $hoveredOffsets,
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
                }.onHover { isHovered in
                    if isHovered {
                        isCodeInEditionMode = false
                    }
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
