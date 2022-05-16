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
                state.lastZoomGestureDelta = value
                return .none
            }
        }
    )
