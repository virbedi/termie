import Foundation

/// Per-shell appearance. Tiles keep their own theme so a grid can mix dark and light.
public enum ShellTheme: String, CaseIterable, Codable, Sendable, Equatable {
    case dark
    case light

    public mutating func toggle() {
        self = self == .dark ? .light : .dark
    }

    public var title: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        }
    }

    public var oppositeTitle: String {
        switch self {
        case .dark: "Light"
        case .light: "Dark"
        }
    }
}
