import SwiftUI

public enum TransportMode: String, CaseIterable, Codable, Identifiable {
    case tube = "tube"
    case elizabethLine = "elizabeth-line"
    case overground = "overground"
    case dlr = "dlr"
    // Note: National Rail removed as TfL API does not provide reliable real-time data for it

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tube: return "London Underground"
        case .elizabethLine: return "Elizabeth line"
        case .overground: return "London Overground"
        case .dlr: return "DLR"
        }
    }

    public var shortName: String {
        switch self {
        case .tube: return "Underground"
        case .elizabethLine: return "Elizabeth"
        case .overground: return "Overground"
        case .dlr: return "DLR"
        }
    }

    public var iconName: String {
        switch self {
        case .tube: return "tram.fill"
        case .elizabethLine: return "tram.circle.fill"
        case .overground: return "tram"
        case .dlr: return "lightrail.fill"
        }
    }

    public var brandColor: Color {
        switch self {
        case .tube: return Color(red: 0.0, green: 0.1, blue: 0.7) // Classic Underground Blue
        case .elizabethLine: return Color(red: 0.45, green: 0.25, blue: 0.65) // Elizabeth Purple
        case .overground: return Color(red: 0.93, green: 0.45, blue: 0.05) // Overground Orange
        case .dlr: return Color(red: 0.0, green: 0.67, blue: 0.67) // DLR Teal
        }
    }
}
