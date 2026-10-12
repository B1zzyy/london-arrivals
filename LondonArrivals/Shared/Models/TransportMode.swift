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
        case .tube: return Color(red: 0.89, green: 0.13, blue: 0.10) // #e32019
        case .elizabethLine: return Color(red: 0.47, green: 0.24, blue: 0.74) // #773ebc
        case .overground: return Color(red: 0.93, green: 0.49, blue: 0.07) // #ee7d12
        case .dlr: return Color(red: 0.0, green: 0.64, blue: 0.67) // #00a3aa
        }
    }
}
