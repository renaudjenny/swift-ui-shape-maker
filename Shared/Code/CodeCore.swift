import ComposableArchitecture

struct CodeState: Equatable {
    var isEditing = false
}

enum CodeAction: Equatable {
    case editChanged(Bool)
}

struct CodeEnvironment {}

let codeReducer = Reducer<CodeState, CodeAction, CodeEnvironment> { state, action, _ in
    switch action {
    case let .editChanged(isEditing):
        state.isEditing = isEditing
        return .none
    }
}
