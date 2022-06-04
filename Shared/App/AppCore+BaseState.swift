import ComposableArchitecture

@dynamicMemberLookup
struct BaseState<State: Equatable>: Equatable {
    var pathElements: IdentifiedArrayOf<PathElement>
    var state: State

    subscript<T>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
        get { self.state[keyPath: keyPath] }
        set { self.state[keyPath: keyPath] = newValue }
    }
}

extension AppState {
    var drawingState: BaseState<DrawingState> {
        get { BaseState(pathElements: pathElements, state: drawing) }
        set { (pathElements, drawing) = (newValue.pathElements, newValue.state) }
    }

    var codeState: BaseState<CodeState> {
        get { BaseState(pathElements: pathElements, state: code) }
        set { (pathElements, code) = (newValue.pathElements, newValue.state) }
    }
}
