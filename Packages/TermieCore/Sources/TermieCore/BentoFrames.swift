import Foundation

public struct UnitRect: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Frames in a unit square, origin at the top left.
/// The emphasized session gets the large cell when the layout is uneven.
public func bentoFrames(count: Int, emphasis: Int, wide: Bool) -> [UnitRect] {
    guard count > 0 else { return [] }
    if count == 1 {
        return [UnitRect(x: 0, y: 0, width: 1, height: 1)]
    }
    if count == 2 {
        if wide {
            return [
                UnitRect(x: 0, y: 0, width: 0.5, height: 1),
                UnitRect(x: 0.5, y: 0, width: 0.5, height: 1),
            ]
        }
        return [
            UnitRect(x: 0, y: 0, width: 1, height: 0.5),
            UnitRect(x: 0, y: 0.5, width: 1, height: 0.5),
        ]
    }
    if count == 3 {
        return assign(
            slots: [
                UnitRect(x: 0, y: 0, width: 0.62, height: 1),
                UnitRect(x: 0.62, y: 0, width: 0.38, height: 0.5),
                UnitRect(x: 0.62, y: 0.5, width: 0.38, height: 0.5),
            ],
            emphasis: emphasis
        )
    }
    if count == 4 {
        return assign(
            slots: [
                UnitRect(x: 0, y: 0, width: 0.62, height: 0.62),
                UnitRect(x: 0.62, y: 0, width: 0.38, height: 0.62),
                UnitRect(x: 0, y: 0.62, width: 0.62, height: 0.38),
                UnitRect(x: 0.62, y: 0.62, width: 0.38, height: 0.38),
            ],
            emphasis: emphasis
        )
    }

    let columns = Int(ceil(sqrt(Double(count))))
    let rows = Int(ceil(Double(count) / Double(columns)))
    let width = 1 / Double(columns)
    let height = 1 / Double(rows)
    return (0..<count).map { index in
        let column = index % columns
        let row = index / columns
        return UnitRect(
            x: Double(column) * width,
            y: Double(row) * height,
            width: width,
            height: height
        )
    }
}

private func assign(slots: [UnitRect], emphasis: Int) -> [UnitRect] {
    let count = slots.count
    let clamped = min(max(emphasis, 0), count - 1)
    var order = Array(0..<count)
    order.remove(at: clamped)
    order.insert(clamped, at: 0)
    var result = Array(repeating: slots[0], count: count)
    for (slot, sessionIndex) in order.enumerated() {
        result[sessionIndex] = slots[slot]
    }
    return result
}
