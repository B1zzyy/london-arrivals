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
        // Tube lines (with custom hexes)
        case "bakerloo": return Color(red: 137.0/255.0, green: 78.0/255.0, blue: 36.0/255.0)
        case "central": return Color(red: 220.0/255.0, green: 36.0/255.0, blue: 31.0/255.0)
        case "circle": return Color(red: 255.0/255.0, green: 206.0/255.0, blue: 0.0/255.0)
        case "district": return Color(red: 0.0/255.0, green: 114.0/255.0, blue: 41.0/255.0)
        case "hammersmith-city", "hammersmith & city": return Color(red: 215.0/255.0, green: 153.0/255.0, blue: 175.0/255.0)
        case "jubilee": return Color(red: 134.0/255.0, green: 143.0/255.0, blue: 152.0/255.0)
        case "metropolitan", "metropolitian": return Color(red: 117.0/255.0, green: 16.0/255.0, blue: 86.0/255.0)
        case "northern": return Color(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0)
        case "piccadilly": return Color(red: 0.0/255.0, green: 25.0/255.0, blue: 168.0/255.0)
        case "victoria", "victroia": return Color(red: 0.0/255.0, green: 160.0/255.0, blue: 226.0/255.0)
        case "waterloo-city": return Color(red: 71.0/255.0, green: 204.0/255.0, blue: 200.0/255.0)
        case "elizabeth": return Color(red: 255.0/255.0, green: 102.0/255.0, blue: 0.0/255.0)
        case "dlr": return Color(red: 0.00, green: 0.68, blue: 0.71)
        // Overground lines
        case "lioness", "mildmay", "windrush", "weaver", "suffragette", "liberty", "london-overground":
            return Color(red: 0.94, green: 0.45, blue: 0.00)
        // National Rail services
        case "great-northern": return Color(red: 0.00, green: 0.38, blue: 0.67)
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
