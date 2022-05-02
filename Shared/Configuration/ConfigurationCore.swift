import ComposableArchitecture

struct ConfigurationState: Equatable {
    var isPathIndicatorsDisplayed = true
}

enum ConfigurationAction: Equatable {
    case displayPathIndicatorsToggleChanged(isOn: Bool)
}

struct ConfigurationEnvironement {}

let configurationReducer = Reducer<
    ConfigurationState, ConfigurationAction, ConfigurationEnvironement
> { state, action, _ in
    switch action {
    case let .displayPathIndicatorsToggleChanged(isOn):
        state.isPathIndicatorsDisplayed = isOn
        return .none
    }
}
