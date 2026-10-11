import Foundation

/// Service to fetch real-time National Rail arrivals from Network Rail's RTPPM feed
/// Requires OpenRailData credentials from https://www.openraildata.com/
public final class NetworkRailService: @unchecked Sendable {
    public static let shared = NetworkRailService()
    
    private let session: URLSession
    private let baseURL = "https://api.realtime.nationalrail.co.uk/api"
    private let userDefaults = UserDefaults(suiteName: "group.com.antigravity.londonarrivals") ?? UserDefaults.standard
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 12
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Stored Credentials
    private var networkRailUsername: String? {
        userDefaults.string(forKey: "nr_username")?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var networkRailPassword: String? {
        userDefaults.string(forKey: "nr_password")?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var hasCredentials: Bool {
        (networkRailUsername?.isEmpty == false) && (networkRailPassword?.isEmpty == false)
    }
    
    // MARK: - Store/Update Credentials
    public func setCredentials(username: String, password: String) {
        userDefaults.set(username.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "nr_username")
        userDefaults.set(password.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "nr_password")
    }
    
    public func clearCredentials() {
        userDefaults.removeObject(forKey: "nr_username")
        userDefaults.removeObject(forKey: "nr_password")
    }
    
    // MARK: - Fetch Station Departures (National Rail)
    /// Fetches real-time departure board for a station using CRS code
    /// CRS codes: FPK = Finsbury Park, MGT = Moorgate Rail, etc.
    public func fetchStationBoard(crs: String) async -> StationBoard? {
        guard hasCredentials,
              let username = networkRailUsername,
              let password = networkRailPassword else {
            return nil
        }
        
        let cleanCRS = crs.uppercased()
        guard var comps = URLComponents(string: "\(baseURL)/api/trains/station/\(cleanCRS)/departures") else {
            return nil
        }
        
        // Add authentication
        let credentials = "\(username):\(password)"
        guard let credData = credentials.data(using: .utf8) else { return nil }
        let credB64 = credData.base64EncodedString()
        
        var request = URLRequest(url: comps.url!)
        request.setValue("Basic \(credB64)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            
            if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return parseStationBoard(dict: jsonDict)
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: - Parse Station Board
    private func parseStationBoard(dict: [String: Any]) -> StationBoard? {
        guard let generatedAt = dict["generatedAt"] as? String else {
            return nil
        }
        
        var services: [DepartureService] = []
        
        if let departures = dict["trainServices"] as? [[String: Any]] {
            services = departures.compactMap { parseService(dict: $0) }
        }
        
        return StationBoard(
            generatedAt: generatedAt,
            services: services
        )
    }
    
    private func parseService(dict: [String: Any]) -> DepartureService? {
        guard let trainID = dict["trainID"] as? String,
              let destination = dict["destination"] as? String,
              let scheduledTime = dict["std"] as? String else {
            return nil
        }
        
        let actualTime = (dict["etd"] as? String) ?? "On time"
        let platform = dict["platform"] as? String
        let operatorName = dict["operator"] as? String
        let currentLocation = dict["currentLocation"] as? String
        
        return DepartureService(
            trainID: trainID,
            destination: destination,
            scheduledTime: scheduledTime,
            actualTime: actualTime,
            platform: platform,
            operator: operatorName,
            currentLocation: currentLocation
        )
    }
    
    // MARK: - Convert to ArrivalPrediction
    /// Converts Network Rail departure data to ArrivalPrediction format for the app
    public func convertToArrivals(board: StationBoard, originStation: String, lineId: String, lineName: String, destinationFilter: String? = nil) -> [ArrivalPrediction] {
        var predictions: [ArrivalPrediction] = []
        let now = Date()
        
        for service in board.services {
            // Parse scheduled time
            let scheduledMinutes = timeStringToMinutes(service.scheduledTime)
            let actualMinutes = timeStringToMinutes(service.actualTime)
            
            // Calculate time to station (use actual if available, else scheduled)
            let minutesUntilArrival = actualMinutes
            let timeToStation = max(0, minutesUntilArrival * 60)
            
            // Filter by destination if specified
            if let destFilter = destinationFilter, !destFilter.isEmpty {
                let filterLower = destFilter.lowercased()
                if !service.destination.lowercased().contains(filterLower) {
                    continue
                }
            }
            
            let prediction = ArrivalPrediction(
                id: service.trainID,
                lineId: lineId,
                lineName: lineName,
                destinationName: service.destination,
                platformName: service.platform ?? "Platform -",
                stationName: originStation,
                timeToStation: timeToStation,
                expectedArrival: now.addingTimeInterval(TimeInterval(timeToStation)),
                towards: service.destination,
                currentLocation: service.currentLocation,
                modeName: "national-rail"
            )
            
            predictions.append(prediction)
        }
        
        // Sort by time to station
        predictions.sort { $0.timeToStation < $1.timeToStation }
        
        return predictions
    }
    
    // MARK: - Time Parsing
    private func timeStringToMinutes(_ timeStr: String) -> Int {
        let clean = timeStr.trimmingCharacters(in: .whitespaces).lowercased()
        
        if clean.contains("on time") || clean.contains("due") {
            return 0
        }
        
        if clean.contains("cancelled") {
            return 999 // Put cancelled trains at the end
        }
        
        if clean.contains("delayed") {
            return 120 // Estimate 2 hours for delayed
        }
        
        // Try to parse "HH:MM" format
        let components = clean.split(separator: ":").compactMap { Int($0) }
        if components.count == 2 {
            let hour = components[0]
            let minute = components[1]
            
            // Convert to minutes from now
            let calendar = Calendar.current
            let now = Date()
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            
            let currentTotalMinutes = currentHour * 60 + currentMinute
            let scheduledTotalMinutes = hour * 60 + minute
            
            var minutesUntil = scheduledTotalMinutes - currentTotalMinutes
            
            // Handle overnight times (if scheduled time is earlier, it's tomorrow)
            if minutesUntil < -60 {
                minutesUntil += 24 * 60
            }
            
            return max(0, minutesUntil)
        }
        
        return 0
    }
}

// MARK: - Models
public struct StationBoard: Codable {
    public let generatedAt: String
    public let services: [DepartureService]
}

public struct DepartureService: Codable {
    public let trainID: String
    public let destination: String
    public let scheduledTime: String // "HH:MM"
    public let actualTime: String    // "HH:MM" or "On time" or "Delayed"
    public let platform: String?
    public let `operator`: String?
    public let currentLocation: String?
}
