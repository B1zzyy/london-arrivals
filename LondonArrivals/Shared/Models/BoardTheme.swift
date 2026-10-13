import SwiftUI

public enum BoardTheme: String, CaseIterable, Codable, Identifiable {
    case undergroundAmber = "undergroundAmber"
    case nationalRailGold = "nationalRailGold"
    case vintageGreen = "vintageGreen"
    case matrixWhite = "matrixWhite"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .undergroundAmber: return "Underground Amber"
        case .nationalRailGold: return "National Rail Yellow"
        case .vintageGreen: return "Vintage Emerald"
        case .matrixWhite: return "Modern OLED White"
        }
    }

    public var subtitle: String {
        switch self {
        case .undergroundAmber: return "Classic London Underground platform LED"
        case .nationalRailGold: return "Iconic British mainline departure screen"
        case .vintageGreen: return "Retro 1980s London vacuum fluorescent display"
        case .matrixWhite: return "High-contrast dot-matrix display"
        }
    }

    /// Primary lit LED color
    public var ledColor: Color {
        switch self {
        case .undergroundAmber:
            return Color(red: 1.0, green: 0.62, blue: 0.05) // Rich Tube amber
        case .nationalRailGold:
            return Color(red: 1.0, green: 0.82, blue: 0.12) // National Rail yellow
        case .vintageGreen:
            return Color(red: 0.04, green: 0.87, blue: 0.78) // Flurescent #0adec8
        case .matrixWhite:
            return Color(red: 0.94, green: 0.96, blue: 1.0) // Ice white
        }
    }

    /// Glow bloom color behind lit LEDs
    public var glowColor: Color {
        switch self {
        case .undergroundAmber:
            return Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.65)
        case .nationalRailGold:
            return Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.6)
        case .vintageGreen:
            return Color(red: 0.04, green: 0.87, blue: 0.78).opacity(0.6)
        case .matrixWhite:
            return Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.5)
        }
    }

    /// Faint unlit LED dot color in the matrix grid
    public var unlitDotColor: Color {
        switch self {
        case .undergroundAmber:
            return Color(red: 0.15, green: 0.09, blue: 0.02)
        case .nationalRailGold:
            return Color(red: 0.14, green: 0.12, blue: 0.02)
        case .vintageGreen:
            return Color(red: 0.04, green: 0.87, blue: 0.78).opacity(0.08)
        case .matrixWhite:
            return Color(red: 0.10, green: 0.12, blue: 0.15)
        }
    }

    /// Pitch black screen housing background
    public var screenBackground: Color {
        Color(red: 0.04, green: 0.04, blue: 0.05)
    }

    /// Outer industrial enclosure bezel
    public var casingColor: Color {
        Color(red: 0.11, green: 0.12, blue: 0.14)
    }

    /// Inner border bevel
    public var bezelBorderColor: Color {
        Color(red: 0.22, green: 0.24, blue: 0.27)
    }

    /// Screw rivets in corners
    public var screwColor: Color {
        Color(red: 0.45, green: 0.48, blue: 0.52)
    }
}
