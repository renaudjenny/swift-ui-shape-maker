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

                ZStack {
                    if isCodeInEditionMode {
                        TextEditor(text: code)
                            .font(.body.monospaced())
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ScrollView {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(codeHeader.codeFormatted)
                                    ForEach(Array(pathElements.enumerated()), id: \.offset) { offset, element in
                                        HStack {
                                            Text(element.code.codeFormatted(extraIndentation: 2))
                                            if hoveredOffsets.contains(offset) {
                                                Button("Remove", role: .destructive) {
                                                    pathElements.remove(at: offset)
                                                }
                                                .padding(.horizontal)
                                            }
                                        }
                                        .background {
                                            if hoveredOffsets.contains(offset) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                                    .shadow(color: .black, radius: 4)
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                                    .padding()
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onHover { isHovered in
                                            withAnimation(.easeInOut) {
                                                if isHovered {
                                                    hoveredOffsets.insert(offset)
                                                } else {
                                                    hoveredOffsets.remove(offset)
                                                }
                                            }
                                        }
                                    }
                                    Text(codeFooter)
                                }
                                .padding(.horizontal, 5)
                                Spacer()
                            }
                        }
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity)
                        .font(.body.monospaced())
                        .background(Color.white)
                        .padding()
                    }
                }.onTapGesture {
                    isCodeInEditionMode = true
                }
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
            get: { [
                codeHeader,
                pathElements.map(\.code).joined(separator: "\n"),
                codeFooter,
            ].joined(separator: "\n").codeFormatted },
            set: { _, _ in }
        )
    }

    private var codeHeader: String { """
    import SwiftUI

    struct MyShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = min(rect.width, rect.height)
    """}

    // swiftlint: disable indentation_width
    private var codeFooter: String { """
            return path
        }
    }
    """ }
    // swiftlint: enable indentation_width
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
