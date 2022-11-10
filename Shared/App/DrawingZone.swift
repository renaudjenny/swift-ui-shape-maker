import ComposableArchitecture
import SwiftUI

struct DrawingZone: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView([.horizontal, .vertical]) {
                DrawingPanel(store: store)
                    .onDrop(
                        of: [.fileURL],
                        isTargeted: viewStore.binding(
                            get: \.isDrawingPanelTargetedForImageDrop,
                            send: AppAction.drawingPanelTargetedForDropChanged
                        )
                    ) { items in
                        _ = items.first?.loadObject(ofClass: URL.self, completionHandler: { @MainActor url, error in
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
