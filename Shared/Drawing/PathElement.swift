import SwiftUI
import IdentifiedCollections

struct PathElement: Equatable {
    enum PathElementType: Equatable {
        case move(to: CGPoint)
        case line(to: CGPoint)
        case quadCurve(to: CGPoint, control: CGPoint)
        case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    }

    let index: Int
    private(set) var type: PathElementType

    var to: CGPoint {
        switch self.type {
        case let .move(to), let .line(to), let .quadCurve(to: to, _), let .curve(to: to, _, _):
            return to
        }
    }

    @available(*, deprecated)
    mutating func update(
        to newTo: CGPoint? = nil,
        quadCurveControl newQuadCurveControl: CGPoint? = nil,
        curveControls newCurveControls: (control1: CGPoint?, control2: CGPoint?)? = nil
    ) {
        switch type {
        case let .move(to):
            type = .move(to: newTo ?? to)
        case let .line(to):
            type = .line(to: newTo ?? to)
        case let .quadCurve(to: to, control: control):
            type = .quadCurve(to: newTo ?? to, control: newQuadCurveControl ?? control)
        case let .curve(to: to, control1: control1, control2: control2):
            type = .curve(
                to: newTo ?? to,
                control1: newCurveControls?.control1 ?? control1,
                control2: newCurveControls?.control2 ?? control2
            )
        }
    }

    mutating func update(guide: Guide) {
        switch (type, guide.type) {
        case (.move, .to):
            type = .move(to: guide.position)
        case (.line, .to):
            type = .line(to: guide.position)
        case (.quadCurve(_, let control), .to):
            type = .quadCurve(to: guide.position, control: control)
        case (.quadCurve(let to, _), .quadCurveControl):
            type = .quadCurve(to: to, control: guide.position)
        case (.curve(_, let control1, let control2), .to):
            type = .curve(to: guide.position, control1: control1, control2: control2)
        case (.curve(let to, _, let control2), .curveControl1):
            type = .curve(to: to, control1: guide.position, control2: control2)
        case (.curve(let to, let control1, _), .curveControl2):
            type = .curve(to: to, control1: control1, control2: guide.position)
        default: break
        }
    }
}

extension PathElement {
    var code: String {
        switch type {
        case let .move(to):
            return """
            path.move(
                to: \(pointForCode(to))
            )
            """
        case let .line(to):
            return """
            path.addLine(
                to: \(pointForCode(to))
            )
            """
        case let .quadCurve(to, control):
            return """
            path.addQuadCurve(
                to: \(pointForCode(to)),
                control: \(pointForCode(control))
            )
            """
        case let .curve(to, control1, control2):
            return """
            path.addCurve(
                to: \(pointForCode(to)),
                control1: \(pointForCode(control1)),
                control2: \(pointForCode(control2))
            )
            """
        }
    }

    private func pointForCode(_ point: CGPoint) -> String {
        let width = DrawingPanel.standardWidth
        let x = abs(point.x - width/2)
        let y = abs(point.y - width/2)
        let xSign = point.x > width/2 ? "+" : "-"
        let ySign = point.y < width/2 ? "-" : "+"
        return """
        CGPoint(
            x: rect.midX \(xSign) width * \(Int(x.rounded()))/\(Int(width)),
            y: rect.midY \(ySign) width * \(Int(y.rounded()))/\(Int(width))
        )
        """
    }
}

extension PathElement {
    enum GuideType: Equatable {
        case to
        case quadCurveControl
        case curveControl1
        case curveControl2
    }

    struct Guide: Equatable {
        let type: GuideType
        let position: CGPoint
    }
}

extension PathElement: Identifiable {
    var id: Int { index }
}

extension String {
    func codeFormatted(extraIndentation: Int) -> String {
        split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .reduce([]) { lines, newLine in
                if let previousLine = lines.last {
                    if previousLine.hasSuffix("{") || previousLine.hasSuffix("(") {
                        return lines + [previousLine.indentation + Self.indentation + newLine]
                    } else if newLine.trimmingCharacters(in: .whitespaces) == "}"
                        || newLine.trimmingCharacters(in: .whitespaces) == ")"
                        || newLine.trimmingCharacters(in: .whitespaces) == ")," {
                        return lines + [previousLine.indentation.dropLast(Self.indentation.count) + newLine]
                    } else {
                        return lines + [previousLine.indentation + newLine]
                    }
                }
                return [newLine]
            }
            .map { Array(repeating: Self.indentation, count: extraIndentation).joined() + $0  }
            .joined(separator: "\n")
    }

    var codeFormatted: String {
        codeFormatted(extraIndentation: 0)
    }

    private static var indentation: String { Array(repeating: " ", count: 4).joined() }

    private var indentation: String { String(prefix(while: { $0 == " " })) }
}

extension Path {
    mutating func addElement(_ element: PathElement, zoomLevel: CGFloat) {
        switch element.type {
        case let .move(to):
            move(to: to.applyZoomLevel(zoomLevel))
        case let .line(to):
            addLine(to: to.applyZoomLevel(zoomLevel))
        case let .quadCurve(to, control):
            addQuadCurve(
                to: to.applyZoomLevel(zoomLevel),
                control: control.applyZoomLevel(zoomLevel)
            )
        case let .curve(to, control1, control2):
            addCurve(
                to: to.applyZoomLevel(zoomLevel),
                control1: control1.applyZoomLevel(zoomLevel),
                control2: control2.applyZoomLevel(zoomLevel)
            )
        }
    }
}

extension CGPoint {
    func applyZoomLevel(_ zoomLevel: CGFloat) -> CGPoint {
        applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel))
    }
}

extension IdentifiedArray where ID == PathElement.ID, Element == PathElement {
    func initialQuadCurveControl(to: CGPoint) -> CGPoint {
        let lastPoint = last?.to ?? .zero
        return CGPoint(
            x: (to.x + lastPoint.x) / 2 - 20,
            y: (to.y + lastPoint.y) / 2 - 20
        )
    }

    func initialCurveControls(to: CGPoint) -> (CGPoint, CGPoint) {
        let lastPoint = last?.to ?? .zero
        let x = (to.x + lastPoint.x) / 2
        let y = (to.y + lastPoint.y) / 2
        let control1 = CGPoint(x: (lastPoint.x + x) / 2 - 20, y: (lastPoint.y + y) / 2 - 20)
        let control2 = CGPoint(x: (x + to.x) / 2 + 20, y: (y + to.y) / 2 + 20)
        return (control1, control2)
    }
}
