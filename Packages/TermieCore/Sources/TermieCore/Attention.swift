import Foundation

public enum SessionPresence: Equatable, Sendable {
    case running
    case exited(Int32)
}
