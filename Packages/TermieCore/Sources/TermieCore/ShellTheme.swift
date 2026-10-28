import Foundation

/// Per-shell appearance. Tiles keep their own color so a grid can mix them.
/// App chrome follows only the global default, not the focused tile.
public enum ShellTheme: String, CaseIterable, Codable, Sendable, Equatable {
    case dark
    case light
    case blue
    case gray
    case green

    public var title: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .blue: "Deep Blue"
        case .gray: "Gray"
        case .green: "Deep Green"
        }
    }

    public var next: ShellTheme {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .dark }
        return all[all.index(after: index) == all.endIndex ? all.startIndex : all.index(after: index)]
    }

    public var nextTitle: String { next.title }

    /// Only Light uses a light interface. The rest stay on a dark chrome.
    public var prefersLightInterface: Bool { self == .light }

    /// Color used on the tile swatch so terminals can be told apart at a glance.
    public var swatch: ThemeColor {
        switch self {
        case .dark: ThemeColor(red: 0.18, green: 0.20, blue: 0.22)
        case .light: ThemeColor(red: 0.90, green: 0.90, blue: 0.88)
        case .blue: ThemeColor(red: 0.12, green: 0.28, blue: 0.55)
        case .gray: ThemeColor(red: 0.45, green: 0.46, blue: 0.48)
        case .green: ThemeColor(red: 0.10, green: 0.38, blue: 0.24)
        }
    }

    public mutating func cycle() {
        self = next
    }
}

public struct ThemeColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}
