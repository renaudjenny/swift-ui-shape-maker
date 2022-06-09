import ComposableArchitecture
import IdentifiedCollections
import SwiftUI

struct DrawingState: Equatable {
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
    case incrementZoomLevel
    case decrementZoomLevel
}

struct DrawingEnvironement {
    var uuid: () -> UUID
}

let drawingReducer = Reducer<BaseState<DrawingState>, DrawingAction, DrawingEnvironement>.combine(
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
                return Effect(
                    value: .pathElement(id: lastElementID, action: .update(guide: guide, zoomLevel: state.zoomLevel))
                )
            }

            state.isAdding = true
            let to = DrawingPanel.inBoundsPoint(to.applyZoomLevel(1/state.zoomLevel))

            guard !state.pathElements.isEmpty else {
                state.pathElements.append(PathElement(
                    id: environment.uuid(),
                    type: .move,
                    segment: Segment(startPoint: to, endPoint: to),
                    isHovered: true,
                    isTransformable: false
                ))
                return .none
            }
            let pathElement: PathElement
            let segment = Segment(startPoint: state.pathElements.last?.segment.endPoint ?? .zero, endPoint: to)
            switch state.selectedPathTool {
            case .move:
                pathElement = PathElement(id: environment.uuid(), type: .move, segment: segment, isHovered: true)
            case .line:
                pathElement = PathElement(id: environment.uuid(), type: .line, segment: segment, isHovered: true)
            case .quadCurve:
                pathElement = PathElement(
                    id: environment.uuid(),
                    type: .quadCurve( control: segment.initialQuadCurveControl),
                    segment: segment,
                    isHovered: true
                )
            case .curve:
                let (control1, control2) = segment.initialCurveControls
                pathElement = PathElement(
                    id: environment.uuid(),
                    type: .curve(control1: control1, control2: control2),
                    segment: segment,
                    isHovered: true
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
            return .none
        case .incrementZoomLevel:
            return Effect(value: .zoomLevelChanged(min(state.zoomLevel + 0.1, 4)))
        case .decrementZoomLevel:
            return Effect(value: .zoomLevelChanged(max(state.zoomLevel - 0.1, 0.1)))
        case let .pathElement(id, action: .update(guide, _)):
            guard
                guide.type == .to,
                let index = state.pathElements.index(id: id),
                let nextElementID = state.pathElements[safe: index + 1]?.id
            else { return .none }
            var amendedPathElement = state.pathElements[id: nextElementID]
            let newStartPoint = DrawingPanel.inBoundsPoint(guide.position.applyZoomLevel(1/state.zoomLevel))
            amendedPathElement?.segment.startPoint = newStartPoint
            state.pathElements[id: nextElementID] = amendedPathElement
            return .none
        case .pathElement:
            return .none
        }
    }
)
