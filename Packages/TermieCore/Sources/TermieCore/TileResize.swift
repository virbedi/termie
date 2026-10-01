import Foundation

extension UnitRect {
    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
}

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
    fileprivate func shares(_ divider: TileDivider, tolerance: Double) -> Bool {
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
