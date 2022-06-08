import SwiftUI
import ComposableArchitecture

@main
struct SwiftUIShapeMakerApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: AppEnvironment(uuid: UUID.init)
            ))
        }
        #if os(macOS)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
    }
}
