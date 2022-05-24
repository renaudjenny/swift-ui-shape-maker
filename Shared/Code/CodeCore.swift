import ComposableArchitecture

struct CodeState: Equatable {
    var pathElements: IdentifiedArrayOf<PathElement>
    var isEditing: Bool
}

enum CodeAction: Equatable {
    case editChanged(Bool)
    case pathElement(id: PathElement.ID, action: PathElementAction)
}

struct CodeEnvironment {}

let codeReducer = Reducer<CodeState, CodeAction, CodeEnvironment>.combine(
    pathElementReducer.forEach(
        state: \.pathElements,
        action: /CodeAction.pathElement,
        environment: { _ in PathElementEnvironement() }
    ),
    Reducer { state, action, _ in
        switch action {
        case let .editChanged(isEditing):
            state.isEditing = isEditing
            return .none
        case .pathElement(id: let id, action: .remove):
            state.pathElements.remove(id: id)
            return .none
        case .pathElement:
            return .none
        }
    }
)
