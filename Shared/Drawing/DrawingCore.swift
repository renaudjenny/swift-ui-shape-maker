import ComposableArchitecture
import IdentifiedCollections

struct DrawingState: Equatable {
    var pathElements: IdentifiedArrayOf<PathElement> = []
    var isAdding = false
    var zoomLevel: Double = 1
    var selectedPathTool = PathTool.line
}

enum DrawingAction: Equatable {
    case pathElement(id: PathElement.ID, action: PathElementAction)
    case addOrMovePathElement(to: CGPoint)
    case endMove
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
            let to = DrawingPanel.inBoundsPoint(to.applyZoomLevel(1/state.zoomLevel))

            guard !state.pathElements.isEmpty else {
                state.pathElements.append(PathElement(
                    id: environment.uuid(),
                    type: .move,
                    startPoint: to,
                    endPoint: to,
                    isHovered: true,
                    zoomLevel: state.zoomLevel
                ))
                return .none
            }
            let pathElement: PathElement
            switch state.selectedPathTool {
            case .move:
                pathElement = PathElement(
                    id: environment.uuid(),
                    type: .move,
                    startPoint: state.pathElements.last?.endPoint ?? .zero,
                    endPoint: to,
                    isHovered: true,
                    zoomLevel: state.zoomLevel
                )
            case .line:
                pathElement = PathElement(
                    id: environment.uuid(),
                    type: .line,
                    startPoint: state.pathElements.last?.endPoint ?? .zero,
                    endPoint: to,
                    isHovered: true,
                    zoomLevel: state.zoomLevel
                )
            case .quadCurve:
                let control = state.pathElements.initialQuadCurveControl(to: to)
                pathElement = PathElement(
                    id: environment.uuid(),
                    type: .quadCurve( control: control),
                    startPoint: state.pathElements.last?.endPoint ?? .zero,
                    endPoint: to,
                    isHovered: true,
                    zoomLevel: state.zoomLevel
                )
            case .curve:
                let (control1, control2) = state.pathElements.initialCurveControls(to: to)
                pathElement = PathElement(
                    id: environment.uuid(),
                    type: .curve(control1: control1, control2: control2),
                    startPoint: state.pathElements.last?.endPoint ?? .zero,
                    endPoint: to,
                    isHovered: true,
                    zoomLevel: state.zoomLevel
                )
            }
            state.pathElements.append(pathElement)
            return .none
        case .endMove:
            state.isAdding = false
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
        case let .pathElement(id, action: .update(guide)):
            guard
                guide.type == .to,
                let index = state.pathElements.index(id: id),
                let nextElementID = state.pathElements[safe: index + 1]?.id
            else { return .none }
            state.pathElements[id: nextElementID]?.startPoint = guide.position
            return .none
        case .pathElement:
            return .none
        }
    }
)
