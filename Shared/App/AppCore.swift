import ComposableArchitecture

struct AppState: Equatable {
    var configuration = ConfigurationState()
    var drawing = DrawingState()
    var code = CodeState()
    var imageData: Data?
    var imageOpacity = 1.0
    var isDrawingPanelTargetedForImageDrop = false
    var lastZoomGestureDelta: Double?
}

enum AppAction: Equatable {
    case configuration(ConfigurationAction)
    case drawing(DrawingAction)
    case code(CodeAction)
    case updateImageData(Data)
    case imageOpacityChanged(Double)
    case drawingPanelTargetedForDropChanged(Bool)
    case lastZoomGestureDeltaChanged(Double?)
}

struct AppEnvironment {
    var uuid: () -> UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>
    .combine(
        configurationReducer.pullback(
            state: \.configuration,
            action: /AppAction.configuration,
            environment: { _ in ConfigurationEnvironement() }
        ),
        drawingReducer.pullback(
            state: \.drawing,
            action: /AppAction.drawing,
            environment: { DrawingEnvironement(uuid: $0.uuid) }),
        Reducer<AppState, AppAction, AppEnvironment> { state, action, _ in
            enum ScrollWheelChangedNotificationID {}

            switch action {
            case .configuration:
                return .none
            case .drawing:
                return .none
            case .code:
                return .none
            case let .updateImageData(data):
                state.imageData = data
                return .none
            case let .imageOpacityChanged(value):
                state.imageOpacity = value
                return .none
            case let .drawingPanelTargetedForDropChanged(isTargeted):
                state.isDrawingPanelTargetedForImageDrop = isTargeted
                return .none
            case let .lastZoomGestureDeltaChanged(value):
                guard let value = value else {
                    state.lastZoomGestureDelta = nil
                    return .none
                }
                // TODO: Test
                let delta = value - (state.lastZoomGestureDelta ?? 1)

                let deltaAdded = state.drawing.zoomLevel + delta
                let clampedDeltaValue: Double
                switch deltaAdded {
                case 4...: clampedDeltaValue = 4
                case ...0.10: clampedDeltaValue = 0.10
                default: clampedDeltaValue = deltaAdded
                }

                state.lastZoomGestureDelta = value
                return Effect(value: .drawing(.zoomLevelChanged(clampedDeltaValue)))
            }
        }
    )
