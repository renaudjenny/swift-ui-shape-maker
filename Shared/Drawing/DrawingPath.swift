import ComposableArchitecture
import SwiftUI

struct DrawingPath: View {
    let store: Store<DrawingState, Never>

    var body: some View {
        WithViewStore(store) { viewStore in
            DrawingShape(pathElements: viewStore.pathElements.elements, zoomLevel: viewStore.zoomLevel).stroke()
        }
    }
}

private struct DrawingShape: Shape {
    let pathElements: [PathElement]
    let zoomLevel: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        pathElements.forEach {
            switch $0.type {
            case .move:
                path.move(to: $0.segment.endPoint.applyZoomLevel(zoomLevel))
            case .line:
                path.addLine(to: $0.segment.endPoint.applyZoomLevel(zoomLevel))
            case let .quadCurve(control):
                path.addQuadCurve(
                    to: $0.segment.endPoint.applyZoomLevel(zoomLevel),
                    control: control.applyZoomLevel(zoomLevel)
                )
            case let .curve(control1, control2):
                path.addCurve(
                    to: $0.segment.endPoint.applyZoomLevel(zoomLevel),
                    control1: control1.applyZoomLevel(zoomLevel),
                    control2: control2.applyZoomLevel(zoomLevel)
                )
            }
        }
        return path
    }
}
