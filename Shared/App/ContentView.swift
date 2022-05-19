import SwiftUI
import ComposableArchitecture

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    let store: Store<AppState, AppAction>

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
                    DrawingZone(store: store)
                    CodeView(store: store.scope(state: \.code, action: AppAction.code))
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
