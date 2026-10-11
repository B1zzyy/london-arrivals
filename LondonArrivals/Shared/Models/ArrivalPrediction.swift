import Foundation

public struct ArrivalPrediction: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var lineId: String
    public var lineName: String
    public var destinationName: String
    public var platformName: String
    public var stationName: String
    public var timeToStation: Int // Seconds
    public var expectedArrival: Date
    public var towards: String?
    public var currentLocation: String?
    public var modeName: String?

    public init(
        id: String = UUID().uuidString,
        lineId: String,
        lineName: String,
        destinationName: String,
        platformName: String = "Platform 1",
        stationName: String = "",
        timeToStation: Int,
        expectedArrival: Date = Date(),
        towards: String? = nil,
        currentLocation: String? = nil,
        modeName: String? = nil
    ) {
        self.id = id
        self.lineId = lineId
        self.lineName = lineName
        self.destinationName = destinationName
        self.platformName = platformName
        self.stationName = stationName
        self.timeToStation = timeToStation
        self.expectedArrival = expectedArrival
        self.towards = towards
        self.currentLocation = currentLocation
        self.modeName = modeName
    }

    /// Formatted destination without verbose station suffixes
    public var cleanDestination: String {
        var clean = destinationName
        clean = clean.replacingOccurrences(of: " Underground Station", with: "")
        clean = clean.replacingOccurrences(of: " Rail Station", with: "")
        clean = clean.replacingOccurrences(of: " DLR Station", with: "")
        clean = clean.replacingOccurrences(of: " Station", with: "")
        return clean.trimmingCharacters(in: .whitespaces)
    }

    /// Uppercase destination formatted for LED Dot Matrix Indicator
    public var matrixDestination: String {
        cleanDestination.uppercased()
    }

    /// Estimated minutes remaining
    public var minutesUntilArrival: Int {
        max(0, Int(round(Double(timeToStation) / 60.0)))
    }

    /// Traditional platform indicator text: "DUE", "1 min", "4 mins"
    public var dmiCountdown: String {
        if minutesUntilArrival == 0 {
            return "Due"
        } else if minutesUntilArrival == 1 {
            return "1 min"
        } else {
            return "\(minutesUntilArrival) mins"
        }
    }

    /// Uppercase for authentic dot-matrix display: "DUE", "1 MIN", "4 MINS"
    public var matrixCountdown: String {
        if minutesUntilArrival == 0 {
            return "DUE"
        } else if minutesUntilArrival == 1 {
            return "1 MIN"
        } else {
            return "\(minutesUntilArrival) MIN"
        }
    }

    /// Clean platform string, e.g. "Platform 1" from "Southbound - Platform 1".
    /// Returns empty when TfL has not supplied a platform; never invent one.
    public var cleanPlatform: String {
        if let match = platformName.range(of: "Platform \\d+", options: .regularExpression) {
            return String(platformName[match])
        }
        return platformName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Short platform number or code, e.g. "1" or "Plat 1"
    public var shortPlatform: String {
        let clean = cleanPlatform
        if clean.lowercased().starts(with: "platform ") {
            return "P" + clean.dropFirst(9)
        }
        return clean
    }

    /// Sample dummy predictions for previews only - returns empty array to force real API data
    /// Note: Fake sample data was removed as it caused confusion. Real TfL API data is used instead.
    public static func samples(destination: String = "Moorgate", line: String = "Northern") -> [ArrivalPrediction] {
        return []
    }
}
