import Foundation

public struct TileDivider: Equatable, Sendable {
    public enum Axis: Equatable, Sendable {
        case horizontal
        case vertical
    }

    /// Vertical dividers move along x. Horizontal dividers move along y.
    /// `start` and `end` are the span of the seam on the other axis.
    public var axis: Axis
    public var position: Double
    public var start: Double
    public var end: Double

    public init(axis: Axis, position: Double, start: Double, end: Double) {
        self.axis = axis
        self.position = position
        self.start = start
        self.end = end
    }
}

/// Seams where two tiles meet. Adjacent seams on the same line become one divider,
/// so dragging between a large tile and a stack resizes the whole stack.
public func tileDividers(in frames: [UnitRect]) -> [TileDivider] {
    let tolerance = 0.004
    var vertical: [Seam] = []
    var horizontal: [Seam] = []

    for left in frames {
        for right in frames {
            if abs(left.maxX - right.minX) <= tolerance {
                let start = max(left.minY, right.minY)
                let end = min(left.maxY, right.maxY)
                if end - start > tolerance {
                    vertical.append(Seam(position: left.maxX, start: start, end: end))
                }
            }
            if abs(left.maxY - right.minY) <= tolerance {
                let start = max(left.minX, right.minX)
                let end = min(left.maxX, right.maxX)
                if end - start > tolerance {
                    horizontal.append(Seam(position: left.maxY, start: start, end: end))
                }
            }
        }
    }

    return merge(vertical, axis: .vertical, tolerance: tolerance)
        + merge(horizontal, axis: .horizontal, tolerance: tolerance)
}

public enum TileEdge: String, CaseIterable, Equatable, Hashable, Sendable {
    case top
    case bottom
    case left
    case right
}

/// The shared seam on one side of `frames[index]`, when a neighbor actually meets that side.
public func sharedDivider(in frames: [UnitRect], at index: Int, edge: TileEdge) -> TileDivider? {
    guard frames.indices.contains(index) else { return nil }
    let tile = frames[index]
    let tolerance = 0.004
    return tileDividers(in: frames).first { divider in
        switch edge {
        case .left:
            return divider.axis == .vertical
                && abs(divider.position - tile.minX) <= tolerance
                && tile.shares(divider, tolerance: tolerance)
        case .right:
            return divider.axis == .vertical
                && abs(divider.position - tile.maxX) <= tolerance
                && tile.shares(divider, tolerance: tolerance)
        case .top:
            return divider.axis == .horizontal
                && abs(divider.position - tile.minY) <= tolerance
                && tile.shares(divider, tolerance: tolerance)
        case .bottom:
            return divider.axis == .horizontal
                && abs(divider.position - tile.maxY) <= tolerance
                && tile.shares(divider, tolerance: tolerance)
        }
    }
}

/// Drags one edge of `frames[index]`. Neighbors stay put unless this window covers
/// them, in which case each covered window shrinks out of the overlap down to `minimum`.
public func resizeTileEdge(
    _ frames: [UnitRect],
    at index: Int,
    edge: TileEdge,
    to position: Double,
    minimum: Double = 0.12
) -> [UnitRect] {
    guard frames.indices.contains(index) else { return frames }
    var next = frames
    next[index] = frames[index].moving(edge, to: position, minimum: minimum)
    return revealCoveredWindows(next, covering: index, minimum: minimum)
}

public func cornerSharesAnEdge(in frames: [UnitRect], at index: Int, corner: TileCorner) -> Bool {
    let edges: [TileEdge]
    switch corner {
    case .topLeft: edges = [.top, .left]
    case .topRight: edges = [.top, .right]
    case .bottomLeft: edges = [.bottom, .left]
    case .bottomRight: edges = [.bottom, .right]
    }
    return edges.contains { sharedDivider(in: frames, at: index, edge: $0) != nil }
}

public enum TileCorner: String, CaseIterable, Equatable, Hashable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

/// Drags one corner of `frames[index]` to `(x, y)` in unit space.
/// Only that window changes; neighbors stay where they are.
public func resizeTileCorner(
    _ frames: [UnitRect],
    at index: Int,
    corner: TileCorner,
    toX x: Double,
    toY y: Double,
    minimum: Double = 0.12
) -> [UnitRect] {
    guard frames.indices.contains(index) else { return frames }
    let horizontal: TileEdge
    let vertical: TileEdge
    switch corner {
    case .topLeft:
        horizontal = .left
        vertical = .top
    case .topRight:
        horizontal = .right
        vertical = .top
    case .bottomLeft:
        horizontal = .left
        vertical = .bottom
    case .bottomRight:
        horizontal = .right
        vertical = .bottom
    }
    var next = frames
    let moved = frames[index]
        .moving(horizontal, to: x, minimum: minimum)
        .moving(vertical, to: y, minimum: minimum)
    next[index] = moved
    return revealCoveredWindows(next, covering: index, minimum: minimum)
}

/// Shrinks every window that `frames[covering]` overlaps so it stays visible.
/// A covered window never goes below `minimum` on either side. If it cannot
/// get out of the way without going smaller than that, the covering window
/// stops at the covered window's minimum footprint.
public func revealCoveredWindows(
    _ frames: [UnitRect],
    covering index: Int,
    minimum: Double
) -> [UnitRect] {
    guard frames.indices.contains(index) else { return frames }
    var next = frames
    var cover = frames[index]
    for other in frames.indices where other != index {
        next[other] = frames[other].retreating(from: cover, minimum: minimum)
    }
    for other in frames.indices where other != index {
        cover = cover.yielding(to: next[other], minimum: minimum)
    }
    next[index] = cover
    return next
}

/// The smaller window draws above a larger one when they still overlap,
/// so a window at the minimum size is not lost underneath.
public func drawsAboveOverlappingWindows(_ frames: [UnitRect], index: Int) -> Bool {
    guard frames.indices.contains(index) else { return false }
    let tile = frames[index]
    return frames.enumerated().contains { otherIndex, other in
        guard otherIndex != index, tile.intersects(other) else { return false }
        if tile.area < other.area - 0.000_001 { return true }
        return abs(tile.area - other.area) <= 0.000_001 && index > otherIndex
    }
}

/// Moves every tile edge that lies on `divider` to `position`.
/// Neither side of the seam may shrink below `minimum`.
public func resizeTiles(
    _ frames: [UnitRect],
    divider: TileDivider,
    to position: Double,
    minimum: Double = 0.12
) -> [UnitRect] {
    let tolerance = 0.004
    var lowerBound = 0.0
    var upperBound = 1.0
    var participants = 0

    for frame in frames where frame.shares(divider, tolerance: tolerance) {
        participants += 1
        switch divider.axis {
        case .vertical:
            if abs(frame.maxX - divider.position) <= tolerance {
                lowerBound = max(lowerBound, frame.minX + minimum)
            }
            if abs(frame.minX - divider.position) <= tolerance {
                upperBound = min(upperBound, frame.maxX - minimum)
            }
        case .horizontal:
            if abs(frame.maxY - divider.position) <= tolerance {
                lowerBound = max(lowerBound, frame.minY + minimum)
            }
            if abs(frame.minY - divider.position) <= tolerance {
                upperBound = min(upperBound, frame.maxY - minimum)
            }
        }
    }

    guard participants > 0, lowerBound <= upperBound else { return frames }
    let clamped = min(max(position, lowerBound), upperBound)

    return frames.map { frame in
        guard frame.shares(divider, tolerance: tolerance) else { return frame }
        var next = frame
        switch divider.axis {
        case .vertical:
            if abs(frame.maxX - divider.position) <= tolerance {
                next.width = clamped - frame.minX
            }
            if abs(frame.minX - divider.position) <= tolerance {
                next.width = frame.maxX - clamped
                next.x = clamped
            }
        case .horizontal:
            if abs(frame.maxY - divider.position) <= tolerance {
                next.height = clamped - frame.minY
            }
            if abs(frame.minY - divider.position) <= tolerance {
                next.height = frame.maxY - clamped
                next.y = clamped
            }
        }
        return next
    }
}

private struct Seam {
    var position: Double
    var start: Double
    var end: Double
}

private func merge(_ seams: [Seam], axis: TileDivider.Axis, tolerance: Double) -> [TileDivider] {
    let sorted = seams.sorted {
        if abs($0.position - $1.position) > tolerance { return $0.position < $1.position }
        return $0.start < $1.start
    }
    var dividers: [TileDivider] = []
    for seam in sorted {
        if var last = dividers.last,
           abs(last.position - seam.position) <= tolerance,
           seam.start <= last.end + tolerance {
            last.end = max(last.end, seam.end)
            dividers[dividers.count - 1] = last
        } else {
            dividers.append(TileDivider(axis: axis, position: seam.position, start: seam.start, end: seam.end))
        }
    }
    return dividers
}

extension UnitRect {
    func retreating(from cover: UnitRect, minimum: Double) -> UnitRect {
        guard intersects(cover) else { return self }
        let overlapW = min(maxX, cover.maxX) - max(minX, cover.minX)
        let overlapH = min(maxY, cover.maxY) - max(minY, cover.minY)
        if overlapW <= overlapH {
            return retreatingHorizontally(from: cover, minimum: minimum)
        }
        return retreatingVertically(from: cover, minimum: minimum)
    }

    func yielding(to tile: UnitRect, minimum: Double) -> UnitRect {
        guard intersects(tile) else { return self }
        let overlapW = min(maxX, tile.maxX) - max(minX, tile.minX)
        let overlapH = min(maxY, tile.maxY) - max(minY, tile.minY)
        if overlapW <= overlapH {
            if midX <= tile.midX {
                return moving(.right, to: tile.minX, minimum: minimum)
            }
            return moving(.left, to: tile.maxX, minimum: minimum)
        }
        if midY <= tile.midY {
            return moving(.bottom, to: tile.minY, minimum: minimum)
        }
        return moving(.top, to: tile.maxY, minimum: minimum)
    }

    private func retreatingHorizontally(from cover: UnitRect, minimum: Double) -> UnitRect {
        if midX >= cover.midX {
            let outer = min(maxX, 1)
            let origin = min(max(cover.maxX, minX), max(outer - minimum, 0))
            var next = self
            next.x = min(max(origin, 0), 1 - minimum)
            next.width = max(minimum, outer - next.x)
            if next.maxX > 1 {
                next.x = 1 - next.width
            }
            return next
        }
        let outer = max(minX, 0)
        let edge = max(min(maxX, cover.minX), outer + minimum)
        var next = self
        next.x = outer
        next.width = min(max(minimum, edge - outer), 1 - outer)
        return next
    }

    private func retreatingVertically(from cover: UnitRect, minimum: Double) -> UnitRect {
        if midY >= cover.midY {
            let outer = min(maxY, 1)
            let origin = min(max(cover.maxY, minY), max(outer - minimum, 0))
            var next = self
            next.y = min(max(origin, 0), 1 - minimum)
            next.height = max(minimum, outer - next.y)
            if next.maxY > 1 {
                next.y = 1 - next.height
            }
            return next
        }
        let outer = max(minY, 0)
        let edge = max(min(maxY, cover.minY), outer + minimum)
        var next = self
        next.y = outer
        next.height = min(max(minimum, edge - outer), 1 - outer)
        return next
    }

    func moving(_ edge: TileEdge, to position: Double, minimum: Double) -> UnitRect {
        var next = self
        switch edge {
        case .left:
            let edgeX = min(max(position, 0), maxX - minimum)
            next.x = edgeX
            next.width = maxX - edgeX
        case .right:
            let edgeX = min(max(position, minX + minimum), 1)
            next.width = edgeX - minX
        case .top:
            let edgeY = min(max(position, 0), maxY - minimum)
            next.y = edgeY
            next.height = maxY - edgeY
        case .bottom:
            let edgeY = min(max(position, minY + minimum), 1)
            next.height = edgeY - minY
        }
        return next
    }

    public func shares(_ divider: TileDivider, tolerance: Double = 0.004) -> Bool {
        switch divider.axis {
        case .vertical:
            let onSeam = abs(maxX - divider.position) <= tolerance || abs(minX - divider.position) <= tolerance
            let overlap = min(maxY, divider.end) - max(minY, divider.start)
            return onSeam && overlap > tolerance
        case .horizontal:
            let onSeam = abs(maxY - divider.position) <= tolerance || abs(minY - divider.position) <= tolerance
            let overlap = min(maxX, divider.end) - max(minX, divider.start)
            return onSeam && overlap > tolerance
        }
    }
}
