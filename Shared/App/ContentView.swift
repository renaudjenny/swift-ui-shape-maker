import SwiftUI
import Combine
import ComposableArchitecture

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    let store: Store<AppState, AppAction>
    @State private var isCodeInEditionMode = false
    @State private var lastZoomGestureDelta: CGFloat?
    @State private var isDrawingPanelTargetedForImageDrop = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    HStack {
                        Slider(value: viewStore.binding(
                            get: \.imageOpacity,
                            send: AppAction.imageOpacityChanged
                        )) { Text("Image opacity") }
                        Button("Choose an image") { openImagePicker(viewStore: viewStore) }
                        zoom(viewStore: viewStore)
                    }
                    HStack {
                        Picker("Tool", selection: viewStore.binding(
                            get: \.drawing.selectedPathTool,
                            send: { .drawing(.selectPathTool($0)) }
                        )) {
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
                    drawingZone(viewStore: viewStore)

                    CodeView(
                        store: store.scope(state: \.drawing, action: AppAction.drawing),
                        isInEditionMode: $isCodeInEditionMode
                    )
                }
            }
        }
    }

    private func drawingZone(viewStore: ViewStore<AppState, AppAction>) -> some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                DrawingPanel(store: store)

                viewStore.image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(viewStore.imageOpacity)
                    .allowsHitTesting(false)
            }
            .onDrop(of: [.fileURL], isTargeted: $isDrawingPanelTargetedForImageDrop) { items in
                _ = items.first?.loadObject(ofClass: URL.self, completionHandler: { url, error in
                    guard error == nil, let url = url, let data = try? Data(contentsOf: url) else { return }
                    viewStore.send(.updateImageData(data))
                })
                return viewStore.imageData != nil
            }
            .frame(
                width: DrawingPanel.standardWidth * viewStore.drawing.zoomLevel,
                height: DrawingPanel.standardWidth * viewStore.drawing.zoomLevel
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
                .subscribe(on: DispatchQueue.main)
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

    private func openImagePicker(viewStore: ViewStore<AppState, AppAction>) {
        #if os(macOS)
        let pictureTaker = IKPictureTaker.pictureTaker()
        pictureTaker?.runModal()
        pictureTaker?.outputImage().map { $0.tiffRepresentation.map { viewStore.send(.updateImageData($0)) } }
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

private extension AppState {
    var image: Image? {
        #if os(macOS)
        imageData.flatMap { NSImage(data: $0).map { Image(nsImage: $0) } }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(uuid: UUID.init)
        ))
    }
}
