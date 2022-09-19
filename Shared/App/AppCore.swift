import ComposableArchitecture
import Foundation

struct AppState: Equatable {
    var configuration = ConfigurationState()
    var drawing = DrawingState()
    var code = CodeState()
    var pathElements: IdentifiedArrayOf<PathElement> = []
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
        Reducer<AppState, AppAction, AppEnvironment> { state, action, _ in
            switch action {
            case .configuration:
                return .none
            case .drawing:
                return .none
            case .updateImageData:
                return .none
            case .imageOpacityChanged:
                return .none
            case .drawingPanelTargetedForDropChanged:
                return .none
            case .lastZoomGestureDeltaChanged:
                return .none
            case let .code(.pathElement(id, action: .remove)):
                guard
                    let removedIndex = state.pathElements.index(id: id),
                    let nextID = state.pathElements[safe: removedIndex + 1]?.id,
                    let newStartPoint = state.pathElements[safe: removedIndex - 1]?.segment.endPoint
                else { return .none }
                state.pathElements[id: nextID]?.segment.startPoint = newStartPoint
                return .none
            case .code:
                return .none
            }
        },
        configurationReducer.pullback(
            state: \.configuration,
            action: /AppAction.configuration,
            environment: { _ in ConfigurationEnvironement() }
        ),
        drawingReducer.pullback(
            state: \AppState.drawingState,
            action: /AppAction.drawing,
            environment: { DrawingEnvironement(uuid: $0.uuid) }),
        codeReducer.pullback(
            state: \AppState.codeState,
            action: /AppAction.code,
            environment: { _ in CodeEnvironment() }
        ),
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
