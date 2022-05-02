import ComposableArchitecture

struct AppState: Equatable {
    var configuration = ConfigurationState()
    var drawing = DrawingState()
    var code = CodeState()
}

enum AppAction: Equatable {
    case configuration(ConfigurationAction)
    case drawing(DrawingAction)
    case code(CodeAction)
}

struct AppEnvironment {}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>
    .combine(
        configurationReducer.pullback(
            state: \.configuration,
            action: /AppAction.configuration,
            environment: { _ in ConfigurationEnvironement() }
        )
    )
