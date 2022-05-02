import ComposableArchitecture

struct ConfigurationState: Equatable {
    var isPathIndicatorsDisplayed = true
}

enum ConfigurationAction: Equatable {
    case displayPathIndicators
    case hidePathIndicators
}

struct ConfigurationEnvironement {}

let configurationReducer = Reducer<
    ConfigurationState,
    ConfigurationAction,
    ConfigurationEnvironement
> { state, action, _ in
    switch action {
    case .displayPathIndicators:
        state.isPathIndicatorsDisplayed = true
        return .none
    case .hidePathIndicators:
        state.isPathIndicatorsDisplayed = false
        return .none
    }
}
