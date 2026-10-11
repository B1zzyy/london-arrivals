import SwiftUI

public struct TfLLine: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var modeName: String
    public var statusSeverityDescription: String?
    public var reason: String?

    public init(id: String, name: String, modeName: String, statusSeverityDescription: String? = nil, reason: String? = nil) {
        self.id = id
        self.name = name
        self.modeName = modeName
        self.statusSeverityDescription = statusSeverityDescription
        self.reason = reason
    }

    /// Color representing the line according to official TfL and National Rail brand guides
    public var lineColor: Color {
        switch id.lowercased() {
        // Tube lines
        case "bakerloo": return Color(red: 0.70, green: 0.40, blue: 0.13)
        case "central": return Color(red: 0.89, green: 0.15, blue: 0.13)
        case "circle": return Color(red: 1.00, green: 0.82, blue: 0.00)
        case "district": return Color(red: 0.00, green: 0.49, blue: 0.24)
        case "hammersmith-city": return Color(red: 0.96, green: 0.59, blue: 0.66)
        case "jubilee": return Color(red: 0.53, green: 0.56, blue: 0.60)
        case "metropolitan": return Color(red: 0.52, green: 0.10, blue: 0.35)
        case "northern": return Color(red: 0.10, green: 0.10, blue: 0.10)
        case "piccadilly": return Color(red: 0.00, green: 0.10, blue: 0.63)
        case "victoria": return Color(red: 0.00, green: 0.63, blue: 0.89)
        case "waterloo-city": return Color(red: 0.47, green: 0.80, blue: 0.72)
        // Elizabeth line & DLR
        case "elizabeth": return Color(red: 0.42, green: 0.22, blue: 0.62)
        case "dlr": return Color(red: 0.00, green: 0.68, blue: 0.71)
        // Overground lines
        case "lioness", "mildmay", "windrush", "weaver", "suffragette", "liberty", "london-overground":
            return Color(red: 0.94, green: 0.45, blue: 0.00)
        // National Rail services
        case "great-northern": return Color(red: 0.00, green: 0.38, blue: 0.67) // Great Northern Navy/Blue
        case "thameslink": return Color(red: 0.85, green: 0.10, blue: 0.38)
        case "southeastern": return Color(red: 0.10, green: 0.45, blue: 0.75)
        case "southern": return Color(red: 0.52, green: 0.75, blue: 0.18)
        case "south-western-railway": return Color(red: 0.88, green: 0.20, blue: 0.25)
        case "avanti-west-coast": return Color(red: 0.00, green: 0.34, blue: 0.34)
        case "lner": return Color(red: 0.78, green: 0.05, blue: 0.10)
        default:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        }
    }

    /// Curated London lines list - TfL supported modes only (Tube, Elizabeth line, Overground, DLR)
    /// Note: National Rail lines removed as TfL API does not provide reliable real-time data for them
    public static var curatedLondonLines: [TfLLine] {
        [
            // Elizabeth line
            TfLLine(id: "elizabeth", name: "Elizabeth line", modeName: "elizabeth-line"),

            // Underground
            TfLLine(id: "northern", name: "Northern", modeName: "tube"),
            TfLLine(id: "victoria", name: "Victoria", modeName: "tube"),
            TfLLine(id: "central", name: "Central", modeName: "tube"),
            TfLLine(id: "piccadilly", name: "Piccadilly", modeName: "tube"),
            TfLLine(id: "jubilee", name: "Jubilee", modeName: "tube"),
            TfLLine(id: "district", name: "District", modeName: "tube"),
            TfLLine(id: "circle", name: "Circle", modeName: "tube"),
            TfLLine(id: "metropolitan", name: "Metropolitan", modeName: "tube"),
            TfLLine(id: "bakerloo", name: "Bakerloo", modeName: "tube"),
            TfLLine(id: "hammersmith-city", name: "Hammersmith & City", modeName: "tube"),
            TfLLine(id: "waterloo-city", name: "Waterloo & City", modeName: "tube"),

            // DLR
            TfLLine(id: "dlr", name: "DLR", modeName: "dlr"),

            // Overground
            TfLLine(id: "windrush", name: "Windrush line", modeName: "overground"),
            TfLLine(id: "lioness", name: "Lioness line", modeName: "overground"),
            TfLLine(id: "mildmay", name: "Mildmay line", modeName: "overground"),
            TfLLine(id: "weaver", name: "Weaver line", modeName: "overground"),
            TfLLine(id: "suffragette", name: "Suffragette line", modeName: "overground"),
            TfLLine(id: "liberty", name: "Liberty line", modeName: "overground")
        ]
    }
}
