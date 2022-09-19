import ComposableArchitecture

struct CodeState: Equatable {
    var mode: CodeMode = .blocks
}

enum CodeMode {
    case blocks
    case edition
    case hidden
}

enum CodeAction: Equatable {
    case modeChanged(CodeMode)
    case pathElement(id: PathElement.ID, action: PathElementAction)
}

struct CodeEnvironment {}

let codeReducer = Reducer<BaseState<CodeState>, CodeAction, CodeEnvironment>.combine(
    pathElementReducer.forEach(
        state: \BaseState<CodeState>.pathElements,
        action: /CodeAction.pathElement,
        environment: { _ in PathElementEnvironement() }
    ),
    Reducer { state, action, _ in
        switch action {
        case let .modeChanged(mode):
            state.mode = mode
            return .none
        case .pathElement(id: let id, action: .remove):
            state.pathElements.remove(id: id)
            return .none
        case let .pathElement(id: id, action: .transform(to: pathTool)):
            guard var pathElement = state.pathElements[id: id] else { return .none }
            pathElement.type = pathTool.pathElementType(for: pathElement)
            state.pathElements.updateOrAppend(pathElement)
            return .none
        case .pathElement:
            return .none
        }
    }
)

private extension PathTool {
    func pathElementType(for pathElement: PathElement) -> PathElement.PathElementType {
        switch self {
        case .move: return .move
        case .line: return .line
        case .quadCurve: return .quadCurve(control: pathElement.segment.initialQuadCurveControl)
        case .curve:
            let (control1, control2) = pathElement.segment.initialCurveControls
            return .curve(control1: control1, control2: control2)
        }
    }
}
