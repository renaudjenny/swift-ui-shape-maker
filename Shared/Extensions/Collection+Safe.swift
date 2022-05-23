extension Collection where Index == Int {
    subscript(safe index: Index) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
