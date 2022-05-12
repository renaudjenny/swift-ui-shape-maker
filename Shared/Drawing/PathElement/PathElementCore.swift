import ComposableArchitecture

struct PathElementState: Equatable {
    var element: PathElement
    var isHovered = false
    var zoomLevel: Double = 1
}

enum PathElementAction: Equatable {
    case move(to: CGPoint)
    case endMove
    case update(guide: PathElement.Guide)
    case hoverChanged(Bool)
}

struct PathElementEnvironement {}

let pathElementReducer = Reducer<PathElementState, PathElementAction, PathElementEnvironement> { state, action, _ in
    switch action {
    case let .move(to):
        return .none
    case .endMove:
        return .none
    case let .update(guide):
        return .none
    case let .hoverChanged(isHovered):
        state.isHovered = isHovered
        return .none
    }
}

extension PathElementState: Identifiable {
    var id: PathElement.ID { element.id }
}
