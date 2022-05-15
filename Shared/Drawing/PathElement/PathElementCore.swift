import ComposableArchitecture

struct PathElementState: Equatable {
    var element: PathElement
    var isHovered = false
    var zoomLevel: Double = 1
    var previousTo: CGPoint
}

enum PathElementAction: Equatable {
    case update(guide: PathElement.Guide)
    case hoverChanged(Bool)
    case remove
}

struct PathElementEnvironement {}

let pathElementReducer = Reducer<PathElementState, PathElementAction, PathElementEnvironement> { state, action, _ in
    switch action {
    case let .update(guide):
        let newGuidePosition = DrawingPanel.inBoundsPoint(guide.position.applyZoomLevel(1/state.zoomLevel))
        state.element.update(guide: PathElement.Guide(type: guide.type, position: newGuidePosition))
        return .none
    case let .hoverChanged(isHovered):
        state.isHovered = isHovered
        return .none
    case .remove:
        return .none
    }
}

extension PathElementState: Identifiable {
    var id: PathElement.ID { element.id }
}
