import ComposableArchitecture
import SwiftUI

struct DrawingZone: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    DrawingPanel(store: store)

                    viewStore.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(viewStore.imageOpacity)
                        .allowsHitTesting(false)
                }
                .onDrop(
                    of: [.fileURL],
                    isTargeted: viewStore.binding(
                        get: \.isDrawingPanelTargetedForImageDrop,
                        send: AppAction.drawingPanelTargetedForDropChanged
                    )
                ) { items in
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
            .highPriorityGesture(MagnificationGesture()
                .onChanged { scale in viewStore.send(.lastZoomGestureDeltaChanged(scale)) }
                .onEnded { _ in viewStore.send(.lastZoomGestureDeltaChanged(nil)) }
            )
        }
    }
}

private extension AppState {
    var image: Image? {
        #if os(macOS)
        imageData.flatMap { NSImage(data: $0).map { Image(nsImage: $0) } }
        #else
        imageData.flatMap { UIImage(data: $0).map { Image(uiImage: $0) } }
        #endif
    }
}
