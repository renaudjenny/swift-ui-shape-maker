import ComposableArchitecture
import IdentifiedCollections

struct DrawingState: Equatable {
    var pathElements: IdentifiedArrayOf<PathElement> = []
    var isAdding = false
    var zoomLevel: Double = 1
    var selectedPathTool = PathTool.line
}

enum DrawingAction: Equatable {
    case movePathElement(to: CGPoint)
    case endMove
    case updatePathElement(id: PathElement.ID, PathElement.Guide)
    case removePathElement(id: PathElement.ID)
    case selectPathTool(PathTool)
    case zoomLevelChanged(Double)
}

struct DrawingEnvironement {}

let drawingReducer = Reducer<DrawingState, DrawingAction, DrawingEnvironement> { state, action, _ in
    switch action {
    case let .movePathElement(to):
        let to = inBoundsPoint(to.applyZoomLevel(1/state.zoomLevel))

        if !state.isAdding {
            state.isAdding = true
            let index = state.pathElements.count

            guard !state.pathElements.isEmpty else {
                state.pathElements.append(PathElement(index: index, type: .move(to: to)))
                return .none
            }
            switch state.selectedPathTool {
            case .move: state.pathElements.append(PathElement(index: index, type: .move(to: to)))
            case .line: state.pathElements.append(PathElement(index: index, type: .line(to: to)))
            case .quadCurve:
                guard let lastPoint = state.pathElements.last?.to else {
                    state.pathElements.append(PathElement(index: index, type: .line(to: to)))
                    return .none
                }
                let control = state.pathElements.initialQuadCurveControl(to: to)
                state.pathElements.append(PathElement(index: index, type: .quadCurve(to: to, control: control)))
            case .curve:
                guard let lastPoint = state.pathElements.last?.to else {
                    state.pathElements.append(PathElement(index: index, type: .line(to: to)))
                    return .none
                }
                let (control1, control2) = state.pathElements.initialCurveControls(to: to)
                state.pathElements.append(PathElement(
                    index: index,
                    type: .curve(to: to, control1: control1, control2: control2)
                ))
            }
            return .none
        } else {
            let lastElementID = state.pathElements[state.pathElements.count - 1].id
            state.pathElements[id: lastElementID]?.update(guide: PathElement.Guide(type: .to, position: to))
            return .none
        }
    case .endMove:
        state.isAdding = false
        return .none
    case let .updatePathElement(id, guide):
        let newGuidePosition = inBoundsPoint(guide.position.applyZoomLevel(1/state.zoomLevel))
        state.pathElements[id: id]?.update(guide: PathElement.Guide(type: guide.type, position: newGuidePosition))
        return .none
    case let .removePathElement(id):
        state.pathElements.remove(id: id)
        return .none
    case let .selectPathTool(pathTool):
        state.selectedPathTool = pathTool
        return .none
    case let .zoomLevelChanged(zoomLevel):
        state.zoomLevel = zoomLevel
        return .none
    }
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
