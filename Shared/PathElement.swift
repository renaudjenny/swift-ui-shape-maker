import SwiftUI

enum PathElement {
    case move(to: CGPoint)
    case line(to: CGPoint)
    case quadCurve(to: CGPoint, control: CGPoint)
    case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)

    var to: CGPoint {
        switch self {
        case let .move(to), let .line(to), let .quadCurve(to: to, _), let .curve(to: to, _, _):
            return to
        }
    }

    mutating func update(
        to newTo: CGPoint? = nil,
        quadCurveControl newQuadCurveControl: CGPoint? = nil,
        curveControls newCurveControls: (control1: CGPoint?, control2: CGPoint?)? = nil
    ) {
        switch self {
        case let .move(to):
            self = .move(to: newTo ?? to)
        case let .line(to):
            self = .line(to: newTo ?? to)
        case let .quadCurve(to: to, control: control):
            self = .quadCurve(to: newTo ?? to, control: newQuadCurveControl ?? control)
        case let .curve(to: to, control1: control1, control2: control2):
            self = .curve(
                to: newTo ?? to,
                control1: newCurveControls?.control1 ?? control1,
                control2: newCurveControls?.control2 ?? control2
            )
        }
    }
}

extension PathElement {
    var code: String {
        switch self {
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
        let x = abs(point.x - 400) * 10/8
        let y = abs(point.y - 400) * 10/8
        let xSign = point.x > 400 ? "+" : "-"
        let ySign = point.y < 400 ? "-" : "+"
        return """
        CGPoint(
            x: rect.midX \(xSign) width * \(Int(x.rounded()))/1000,
            y: rect.midY \(ySign) width * \(Int(y.rounded()))/1000
        )
        """
    }
}

extension String {
    func codeFormatted(extraIndentation: Int) -> String {
        split(separator: "\n")
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
    mutating func addElement(_ element: PathElement) {
        switch element {
        case let .move(to):
            move(to: to)
        case let .line(to):
            addLine(to: to)
        case let .quadCurve(to, control):
            addQuadCurve(to: to, control: control)
        case let .curve(to, control1, control2):
            addCurve(to: to, control1: control1, control2: control2)
        }
    }
}
