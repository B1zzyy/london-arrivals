import Foundation

public struct TfLStopPoint: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var commonName: String
    public var modes: [String]
    public var lines: [String]
    public var lat: Double?
    public var lon: Double?

    public init(id: String, commonName: String, modes: [String] = [], lines: [String] = [], lat: Double? = nil, lon: Double? = nil) {
        self.id = id
        self.commonName = commonName
        self.modes = modes
        self.lines = lines
        self.lat = lat
        self.lon = lon
    }

    /// Clean station name without suffixes
    public var cleanName: String {
        var name = commonName
        name = name.replacingOccurrences(of: " Underground Station", with: "")
        name = name.replacingOccurrences(of: " Rail Station", with: "")
        name = name.replacingOccurrences(of: " DLR Station", with: "")
        name = name.replacingOccurrences(of: " Station", with: "")
        return name.trimmingCharacters(in: .whitespaces)
    }

    /// Curated list of popular London transport hubs (Tube, Elizabeth line, Overground, DLR)
    /// National Rail stations removed as TfL API doesn't provide reliable real-time data for them
    public static var popularLondonStations: [TfLStopPoint] {
        [
            // Tube stations
            TfLStopPoint(id: "940GZZLUODS", commonName: "Old Street Underground Station", modes: ["tube"], lines: ["northern"]),
            TfLStopPoint(id: "940GZZLUMGT", commonName: "Moorgate Underground Station", modes: ["tube"], lines: ["circle", "hammersmith-city", "metropolitan", "northern"]),
            TfLStopPoint(id: "940GZZLUHBN", commonName: "Highbury & Islington Underground Station", modes: ["tube"], lines: ["victoria"]),
            TfLStopPoint(id: "940GZZLUKSX", commonName: "King's Cross St. Pancras Underground Station", modes: ["tube"], lines: ["circle", "hammersmith-city", "metropolitan", "northern", "piccadilly", "victoria"]),
            TfLStopPoint(id: "940GZZLULNB", commonName: "London Bridge Underground Station", modes: ["tube"], lines: ["jubilee", "northern"]),
            TfLStopPoint(id: "HUBBAN", commonName: "Bank", modes: ["tube", "dlr"], lines: ["central", "dlr", "northern", "waterloo-city"]),
            TfLStopPoint(id: "940GZZLUWLO", commonName: "Waterloo Underground Station", modes: ["tube"], lines: ["bakerloo", "jubilee", "northern", "waterloo-city"]),
            TfLStopPoint(id: "940GZZLUOXC", commonName: "Oxford Circus Underground Station", modes: ["tube"], lines: ["bakerloo", "central", "victoria"]),
            TfLStopPoint(id: "940GZZLUVCT", commonName: "Victoria Underground Station", modes: ["tube"], lines: ["district", "victoria", "circle"]),
            TfLStopPoint(id: "940GZZLUFPK", commonName: "Finsbury Park Underground Station", modes: ["tube"], lines: ["piccadilly", "victoria"]),
            
            // Elizabeth line & major interchanges
            TfLStopPoint(id: "HUBPAD", commonName: "Paddington", modes: ["national-rail", "elizabeth-line", "tube"], lines: ["elizabeth"]),
            TfLStopPoint(id: "HUBSRA", commonName: "Stratford", modes: ["national-rail", "elizabeth-line", "overground", "dlr"], lines: ["elizabeth", "mildmay", "windrush", "weaver", "dlr"]),
            
            // Overground stations
            TfLStopPoint(id: "910GHGHI", commonName: "Highbury & Islington Rail Station", modes: ["national-rail", "overground"], lines: ["mildmay", "windrush", "weaver"])
        ]
    }
}
