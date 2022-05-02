import ComposableArchitecture

struct DrawingState: Equatable {
    var pathElements: [PathElement] = []
    var isAdding = false
    var zoomLevel: Double = 1
    var selectedPathTool = PathTool.line
}

enum DrawingAction: Equatable {
    case addPathElement(to: CGPoint)
    case selectPathTool(PathTool)
    case zoomLevelChanged(Double)
}

struct DrawingEnvironement {}

let drawingReducer = Reducer<DrawingState, DrawingAction, DrawingEnvironement> { state, action, _ in
    switch action {
    case let .addPathElement(to):
        let to = to.applyZoomLevel(state.zoomLevel)

        guard !state.pathElements.isEmpty else {
            state.pathElements.append(.move(to: to))
            return .none
        }
        switch state.selectedPathTool {
        case .move: state.pathElements.append(.move(to: to))
        case .line: state.pathElements.append(.line(to: to))
        case .quadCurve:
            guard let lastPoint = state.pathElements.last?.to else {
                state.pathElements.append(.line(to: to))
                return .none
            }
            if case let .quadCurve(_, control) = state.pathElements.last {
                state.pathElements.append(.quadCurve(to: to, control: control))
                return .none
            }
            let x = (to.x + lastPoint.x) / 2
            let y = (to.y + lastPoint.y) / 2
            let control = CGPoint(x: x - 20, y: y - 20)
            state.pathElements.append(.quadCurve(to: to, control: control))
        case .curve:
            guard let lastPoint = state.pathElements.last?.to else {
                state.pathElements.append(.line(to: to))
                return .none
            }
            if case let .curve(_, control1, control2) = state.pathElements.last {
                state.pathElements.append(.curve(to: to, control1: control1, control2: control2))
                return .none
            }
            let x = (to.x + lastPoint.x) / 2
            let y = (to.y + lastPoint.y) / 2
            let control1 = CGPoint(x: (lastPoint.x + x) / 2 - 20, y: (lastPoint.y + y) / 2 - 20)
            let control2 = CGPoint(x: (x + to.x) / 2 + 20, y: (y + to.y) / 2 + 20)
            state.pathElements.append(.curve(to: to, control1: control1, control2: control2))
        }
        return .none
    case let .selectPathTool(pathTool):
        state.selectedPathTool = pathTool
        return .none
    case let .zoomLevelChanged(zoomLevel):
        state.zoomLevel = zoomLevel
        return .none
    }
}
