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
    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
    public var area: Double { width * height }

    public func intersects(_ other: UnitRect, tolerance: Double = 0.004) -> Bool {
        let overlapW = min(maxX, other.maxX) - max(minX, other.minX)
        let overlapH = min(maxY, other.maxY) - max(minY, other.minY)
        return overlapW > tolerance && overlapH > tolerance
    }

    public func contains(_ point: CanvasPoint) -> Bool {
        point.x >= minX && point.x < maxX && point.y >= minY && point.y < maxY
    }

    func distanceSquared(to point: CanvasPoint) -> Double {
        let dx = max(minX - point.x, 0, point.x - maxX)
        let dy = max(minY - point.y, 0, point.y - maxY)
        return dx * dx + dy * dy
    }
}

public struct CanvasPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
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

/// Slot the window should occupy when dropped at `point`.
/// A point inside a frame selects that frame. Otherwise the nearest frame wins.
/// `moving` is unused for hit testing so the window can land on the slot it already holds.
public func canvasDropSlot(frames: [UnitRect], at point: CanvasPoint, moving: Int) -> Int {
    guard !frames.isEmpty else { return 0 }
    let clamped = CanvasPoint(
        x: min(max(point.x, 0), nextDownFromOne),
        y: min(max(point.y, 0), nextDownFromOne)
    )
    if let hit = frames.firstIndex(where: { $0.contains(clamped) }) {
        return hit
    }
    return frames.indices.min {
        frames[$0].distanceSquared(to: clamped) < frames[$1].distanceSquared(to: clamped)
    } ?? min(max(moving, 0), frames.count - 1)
}

/// Puts `moving` into `slot` among the visible ids. The others shift into the
/// gap so the reading order matches where the window was dropped.
public func reorderOccupyingSlot<ID: Hashable>(
    all: [ID],
    hidden: Set<ID>,
    moving: ID,
    toSlot slot: Int
) -> [ID] {
    guard all.contains(moving), !hidden.contains(moving) else { return all }
    var visible = all.filter { !hidden.contains($0) }
    guard let from = visible.firstIndex(of: moving) else { return all }
    let clamped = min(max(slot, 0), visible.count - 1)
    guard clamped != from else { return all }
    let item = visible.remove(at: from)
    visible.insert(item, at: min(clamped, visible.count))

    var next = visible.makeIterator()
    return all.map { id in
        if hidden.contains(id) { return id }
        return next.next() ?? id
    }
}

private let nextDownFromOne = 0.999_999
