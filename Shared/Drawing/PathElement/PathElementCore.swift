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
}

struct PathElementEnvironement {}

let pathElementReducer = Reducer<PathElementState, PathElementAction, PathElementEnvironement> { state, action, _ in
    switch action {
    case let .update(guide):
        // TODO: test
        let newGuidePosition = inBoundsPoint(guide.position.applyZoomLevel(1/state.zoomLevel))
        state.element.update(guide: PathElement.Guide(type: guide.type, position: newGuidePosition))
        return .none
    case let .hoverChanged(isHovered):
        state.isHovered = isHovered
        return .none
    }
}

extension PathElementState: Identifiable {
    var id: PathElement.ID { element.id }
}

private func inBoundsPoint(_ point: CGPoint) -> CGPoint {
    var inBondsPoint = point
    if inBondsPoint.x < 0 {
        inBondsPoint.x = 0
    }
    if inBondsPoint.y < 0 {
        inBondsPoint.y = 0
    }
    if inBondsPoint.x > DrawingPanel.standardWidth {
        inBondsPoint.x = DrawingPanel.standardWidth
    }
    if inBondsPoint.y > DrawingPanel.standardWidth {
        inBondsPoint.y = DrawingPanel.standardWidth
    }
    return inBondsPoint
}
