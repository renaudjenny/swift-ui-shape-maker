import ComposableArchitecture
import IdentifiedCollections

struct DrawingState: Equatable {
    var pathElements: IdentifiedArrayOf<PathElementState> = []
    var isAdding = false
    var zoomLevel: Double = 1
    var selectedPathTool = PathTool.line
}

enum DrawingAction: Equatable {
    case pathElement(id: PathElement.ID, action: PathElementAction)
    case addOrMovePathElement(to: CGPoint)
    case endMove
    case removePathElement(id: PathElement.ID)
    case selectPathTool(PathTool)
    case zoomLevelChanged(Double)
}

struct DrawingEnvironement {
    var uuid: () -> UUID
}

let drawingReducer = Reducer<DrawingState, DrawingAction, DrawingEnvironement>.combine(
    pathElementReducer.forEach(
        state: \.pathElements,
        action: /DrawingAction.pathElement,
        environment: { _ in PathElementEnvironement() }
    ),
    Reducer { state, action, environment in
        switch action {
        case let .addOrMovePathElement(to):
            guard !state.isAdding else {
                let lastElementID = state.pathElements[state.pathElements.count - 1].id
                let guide = PathElement.Guide(type: .to, position: to)
                return Effect(value: .pathElement(id: lastElementID, action: .update(guide: guide)))
            }

            state.isAdding = true

            guard !state.pathElements.isEmpty else {
                let pathElementState = PathElementState(
                    element: PathElement(id: environment.uuid(), type: .move(to: to)),
                    isHovered: true,
                    zoomLevel: state.zoomLevel,
                    previousTo: to
                )
                state.pathElements.append(pathElementState)
                return .none
            }
            let pathElementState: PathElementState
            switch state.selectedPathTool {
            case .move:
                pathElementState = PathElementState(
                    element: PathElement(id: environment.uuid(), type: .move(to: to)),
                    isHovered: true,
                    zoomLevel: state.zoomLevel,
                    previousTo: state.pathElements.last?.element.to ?? .zero
                )
            case .line:
                pathElementState = PathElementState(
                    element: PathElement(id: environment.uuid(), type: .line(to: to)),
                    isHovered: true,
                    zoomLevel: state.zoomLevel,
                    previousTo: state.pathElements.last?.element.to ?? .zero
                )
            case .quadCurve:
                let control = state.pathElements.initialQuadCurveControl(to: to)
                pathElementState = PathElementState(
                    element: PathElement(id: environment.uuid(), type: .quadCurve(to: to, control: control)),
                    isHovered: true,
                    zoomLevel: state.zoomLevel,
                    previousTo: state.pathElements.last?.element.to ?? .zero
                )
            case .curve:
                let (control1, control2) = state.pathElements.initialCurveControls(to: to)
                pathElementState = PathElementState(
                    element: PathElement(
                        id: environment.uuid(),
                        type: .curve(to: to, control1: control1, control2: control2)
                    ),
                    isHovered: true,
                    zoomLevel: state.zoomLevel,
                    previousTo: state.pathElements.last?.element.to ?? .zero
                )
            }
            state.pathElements.append(pathElementState)
            return .none
        case .endMove:
            state.isAdding = false
            return .none
        case let .removePathElement(id):
            state.pathElements.remove(id: id)
            return .none
        case let .selectPathTool(pathTool):
            state.selectedPathTool = pathTool
            return .none
        case let .zoomLevelChanged(zoomLevel):
            state.zoomLevel = zoomLevel
            state.pathElements.map(\.id).forEach {
                state.pathElements[id: $0]?.zoomLevel = zoomLevel
            }
            return .none
        case .pathElement:
            return .none
        }
    }
)
