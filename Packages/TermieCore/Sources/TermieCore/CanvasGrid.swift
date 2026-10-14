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

    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
}

/// Column count for a nearly-square canvas of `count` equal tiles.
public func canvasColumnCount(for count: Int) -> Int {
    guard count > 0 else { return 0 }
    return Int(ceil(sqrt(Double(count))))
}

/// Equal (or nearly equal) frames in a unit square, origin at the top left.
/// Session order is reading order: left to right, then top to bottom.
/// Empty cells may remain on the last row so every occupied tile keeps the same size.
public func equalGridFrames(count: Int) -> [UnitRect] {
    guard count > 0 else { return [] }
    let columns = canvasColumnCount(for: count)
    let rows = Int(ceil(Double(count) / Double(columns)))
    let width = 1 / Double(columns)
    let height = 1 / Double(rows)
    return (0..<count).map { index in
        UnitRect(
            x: Double(index % columns) * width,
            y: Double(index / columns) * height,
            width: width,
            height: height
        )
    }
}

/// Moves `moving` among the visible identifiers, leaving hidden ones in place.
/// Pass `before: nil` to move the item after every other visible item.
public func reorderPreservingHidden<ID: Hashable>(
    all: [ID],
    hidden: Set<ID>,
    moving: ID,
    before destination: ID?
) -> [ID] {
    guard all.contains(moving), !hidden.contains(moving) else { return all }
    if let destination, destination == moving { return all }
    if let destination {
        guard all.contains(destination), !hidden.contains(destination) else { return all }
    }

    var visible = all.filter { !hidden.contains($0) }
    guard let from = visible.firstIndex(of: moving) else { return all }
    visible.remove(at: from)
    if let destination, let to = visible.firstIndex(of: destination) {
        visible.insert(moving, at: to)
    } else {
        visible.append(moving)
    }

    var next = visible.makeIterator()
    return all.map { id in
        if hidden.contains(id) { return id }
        return next.next() ?? id
    }
}
