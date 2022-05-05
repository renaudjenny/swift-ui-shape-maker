import SwiftUI
import Combine
import ComposableArchitecture

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    let store: Store<AppState, AppAction>
    @State private var image: Image?
    @State private var imageOpacity = 1.0
    @State private var selectedPathTool: PathTool = .line
    @State private var isCodeInEditionMode = false
    @State private var hoveredOffsets = Set<Int>()
    @State private var lastZoomGestureDelta: CGFloat?
    @State private var isDrawingPanelTargetedForImageDrop = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        WithViewStore(store) { viewStore in
            let zoomLevel = viewStore.drawing.zoomLevel
            VStack {
                VStack {
                    HStack {
                        Slider(value: $imageOpacity) { Text("Image opacity") }
                        Button("Choose an image") { openImagePicker() }
                        zoom(viewStore: viewStore)
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
                        Toggle("Display path indicators", isOn: viewStore.binding(
                            get: \.configuration.isPathIndicatorsDisplayed,
                            send: { .configuration(.displayPathIndicatorsToggleChanged(isOn: $0)) }
                        ).animation())
                        Spacer()
                    }
                }
                .padding()
                HStack {
                    ScrollView([.horizontal, .vertical]) {
                        ZStack {
                            DrawingPanel(
                                store: store,
                                hoveredOffsets: $hoveredOffsets,
                                selectedPathTool: selectedPathTool
                            )

                            image?
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(imageOpacity)
                                .allowsHitTesting(false)
                        }
                        .onDrop(of: [.fileURL], isTargeted: $isDrawingPanelTargetedForImageDrop) { items in
                            _ = items.first?.loadObject(ofClass: URL.self, completionHandler: { url, error in
                                guard error == nil, let url = url else { return }
                                image = Image(nsImage: NSImage(byReferencing: url))
                            })
                            return image != nil
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
                            clampZoomLevel(viewStore, add: delta)
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
                                clampZoomLevel(viewStore, add: $0.deltaY/100)
                            }
                            .store(in: &cancellables)
                        #endif
                    }

                    CodeView(
                        store: store,
                        hoveredOffsets: $hoveredOffsets,
                        isInEditionMode: $isCodeInEditionMode
                    )
                }
            }
        }
    }

    private func zoom(viewStore: ViewStore<AppState, AppAction>) -> some View {
        HStack {
            Slider(
                value: viewStore.binding(get: \.drawing.zoomLevel, send: { .drawing(.zoomLevelChanged($0)) }),
                in: 0.10...4
            ) { Text("Zoom level") }
            Text("\(Int(viewStore.drawing.zoomLevel * 100))%")
        }
    }

    private func openImagePicker() {
        #if os(macOS)
        let pictureTaker = IKPictureTaker.pictureTaker()
        pictureTaker?.runModal()
        pictureTaker?.outputImage().map { image = Image(nsImage: $0) }
        #endif
    }

    private func clampZoomLevel(_ viewStore: ViewStore<AppState, AppAction>, add delta: CGFloat) {
        let deltaAdded = viewStore.drawing.zoomLevel + delta
        switch deltaAdded {
        case 4...:
            viewStore.send(.drawing(.zoomLevelChanged(4)))
        case ...0.10:
            viewStore.send(.drawing(.zoomLevelChanged(0.10)))
        default:
            viewStore.send(.drawing(.zoomLevelChanged(deltaAdded)))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment()
        ))
    }
}
