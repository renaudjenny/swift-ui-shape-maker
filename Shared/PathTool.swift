enum PathTool: CaseIterable, Identifiable {
    case move
    case line
    case quadCurve
    case curve

    var id: Int { hashValue }
}
