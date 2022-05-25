import SwiftUI
import ComposableArchitecture

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                DrawingZone(store: store)
                CodeView(store: store.scope(state: \.code, action: AppAction.code))
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
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

                    Toggle(isOn: viewStore.binding(
                        get: \.configuration.isPathIndicatorsDisplayed,
                        send: { .configuration(.displayPathIndicatorsToggleChanged(isOn: $0)) }
                    ).animation()) {
                        let systemImage = viewStore.configuration.isPathIndicatorsDisplayed
                        ? "point.3.filled.connected.trianglepath.dotted"
                        : "point.3.connected.trianglepath.dotted"
                        Label("Display path indicators", systemImage: systemImage)
                    }
                }

                ToolbarItemGroup {
                    Button { openImagePicker(viewStore: viewStore) } label: {
                        Label("Choose an image", systemImage: "photo")
                    }

                    Slider(value: viewStore.binding(
                        get: \.imageOpacity,
                        send: AppAction.imageOpacityChanged
                    )) { Text("Image opacity") }.frame(width: 100)

                    Button { openImagePicker(viewStore: viewStore) } label: {
                        Label("Choose an image", systemImage: "photo.fill")
                    }
                }

                ToolbarItemGroup {
                    Button { viewStore.send(.drawing(.decrementZoomLevel)) } label: {
                        Label("Reset zoom", systemImage: "minus.magnifyingglass")
                    }

                    Slider(
                        value: viewStore.binding(get: \.drawing.zoomLevel, send: { .drawing(.zoomLevelChanged($0)) }),
                        in: 0.10...4
                    ) { Text("Zoom level") }.frame(width: 100)

                    Button { viewStore.send(.drawing(.incrementZoomLevel)) } label: {
                        Label("Reset zoom", systemImage: "plus.magnifyingglass")
                    }
                }
            }
        }
    }

    private func openImagePicker(viewStore: ViewStore<AppState, AppAction>) {
        #if os(macOS)
        let pictureTaker = IKPictureTaker.pictureTaker()
        pictureTaker?.runModal()
        pictureTaker?.outputImage().map { $0.tiffRepresentation.map { viewStore.send(.updateImageData($0)) } }
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
