import ComposableArchitecture

enum PathElementAction: Equatable {
    case update(guide: PathElement.Guide)
    case hoverChanged(Bool)
    case remove
    case transform(to: PathTool)
}

struct PathElementEnvironement {}

let pathElementReducer = Reducer<PathElement, PathElementAction, PathElementEnvironement> { state, action, _ in
    switch action {
    case let .update(guide):
        let newGuidePosition: CGPoint
        if guide.type == .to {
            newGuidePosition = DrawingPanel.inBoundsPoint(guide.position.applyZoomLevel(1/state.zoomLevel))
        } else {
            newGuidePosition = guide.position.applyZoomLevel(1/state.zoomLevel)
        }
        state.update(guide: PathElement.Guide(type: guide.type, position: newGuidePosition))
        return .none
    case let .hoverChanged(isHovered):
        state.isHovered = isHovered
        return .none
    case .remove:
        return .none
    case .transform:
        return .none
    }
}
