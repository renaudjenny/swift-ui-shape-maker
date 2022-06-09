import SwiftUI
import IdentifiedCollections

struct PathElement: Equatable, Identifiable {
    enum PathElementType: Equatable {
        case move
        case line
        case quadCurve(control: CGPoint)
        case curve(control1: CGPoint, control2: CGPoint)
    }

    var id: UUID
    var type: PathElementType
    var segment: Segment
    var isHovered = false
    var isTransformable = true

    mutating func update(guide: Guide) {
        switch (type, guide.type) {
        case (.move, .to):
            segment.endPoint = guide.position
        case (.line, .to):
            segment.endPoint = guide.position
        case (.quadCurve, .to):
            segment.endPoint = guide.position
        case (.quadCurve, .quadCurveControl):
            type = .quadCurve(control: guide.position)
        case (.curve, .to):
            segment.endPoint = guide.position
        case let (.curve(_, control2), .curveControl1):
            type = .curve(control1: guide.position, control2: control2)
        case let (.curve(control1, _), .curveControl2):
            type = .curve(control1: control1, control2: guide.position)
        default: break
        }
    }
}

extension PathElement {
    var code: String {
        switch type {
        case .move:
            return """
            path.move(
                to: \(pointForCode(segment.endPoint))
            )
            """
        case .line:
            return """
            path.addLine(
                to: \(pointForCode(segment.endPoint))
            )
            """
        case let .quadCurve(control):
            return """
            path.addQuadCurve(
                to: \(pointForCode(segment.endPoint)),
                control: \(pointForCode(control))
            )
            """
        case let .curve(control1, control2):
            return """
            path.addCurve(
                to: \(pointForCode(segment.endPoint)),
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

extension CGPoint {
    func applyZoomLevel(_ zoomLevel: CGFloat) -> CGPoint {
        applying(CGAffineTransform(scaleX: zoomLevel, y: zoomLevel))
    }
}

struct Segment: Equatable {
    var startPoint: CGPoint
    var endPoint: CGPoint
}

extension Segment {
    var initialQuadCurveControl: CGPoint { CGPoint(
        x: (endPoint.x + startPoint.x) / 2 - 20,
        y: (endPoint.y + startPoint.y) / 2 - 20
    ) }

    var initialCurveControls: (CGPoint, CGPoint) {
        let x = (endPoint.x + startPoint.x) / 2
        let y = (endPoint.y + startPoint.y) / 2
        let control1 = CGPoint(x: (startPoint.x + x) / 2 - 20, y: (startPoint.y + y) / 2 - 20)
        let control2 = CGPoint(x: (x + endPoint.x) / 2 + 20, y: (y + endPoint.y) / 2 + 20)
        return (control1, control2)
    }
}
