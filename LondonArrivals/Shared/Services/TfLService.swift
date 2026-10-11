import Foundation

public final class TfLService: @unchecked Sendable {
    public static let shared = TfLService()

    private let session: URLSession
    private let baseURL = "https://api.tfl.gov.uk"
    private let userDefaults = UserDefaults(suiteName: "group.com.antigravity.londonarrivals") ?? UserDefaults.standard

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 15
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    private var appKey: String? {
        userDefaults.string(forKey: "tfl_app_key")?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func appendAuth(to urlComponents: inout URLComponents) {
        if let key = appKey, !key.isEmpty {
            var items = urlComponents.queryItems ?? []
            items.append(URLQueryItem(name: "app_key", value: key))
            urlComponents.queryItems = items
        }
    }

    // MARK: - Fetch Arrivals for Commute
    public func fetchArrivals(for commute: FavouriteCommute) async -> [ArrivalPrediction] {
        NSLog("[LA-DIAG][TfL] commute BEGIN id=%@ title=%@ station=%@ stationID=%@ lineID=%@", commute.id.uuidString, commute.title, commute.originStationName, commute.originStationId, commute.lineId)
        var results: [ArrivalPrediction] = []

        // Try station arrivals
        let stationArrivals = await fetchArrivalsForStopPoint(stopPointId: commute.originStationId, lineId: commute.lineId)
        NSLog("[LA-DIAG][TfL] stop-point stage id=%@ count=%ld", commute.originStationId, stationArrivals.count)
        results.append(contentsOf: stationArrivals)

        // If empty and lineId is tube or elizabeth, also try fetching by Line
        if results.isEmpty && !commute.lineId.isEmpty {
            NSLog("[LA-DIAG][TfL] stop-point empty; starting line fallback lineID=%@", commute.lineId)
            let lineArrivals = await fetchArrivalsForLine(lineId: commute.lineId, stationName: commute.originStationName)
            NSLog("[LA-DIAG][TfL] line fallback count=%ld", lineArrivals.count)
            results.append(contentsOf: lineArrivals)
        }

        // Older saved favourites can contain display labels rather than the exact
        // TfL `towards` string. Apply a direction filter only when it matches data;
        // otherwise keep real station/line arrivals rather than turning them into [] .
        let directions = (commute.directionFilters ?? commute.directionFilter.map { [$0] } ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        if !directions.isEmpty {
            let matchingDirections = results.filter { prediction in
                let towards = (prediction.towards ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return directions.contains { towards == $0 || towards.contains($0) || $0.contains(towards) }
            }
            if !matchingDirections.isEmpty { results = matchingDirections }
        }

        // Treat legacy destination/platform values as preferences, not reasons to
        // erase every live result when TfL's wording or platform metadata differs.
        if let destFilter = commute.destinationFilter?.trimmingCharacters(in: .whitespacesAndNewlines), !destFilter.isEmpty {
            let filterLower = destFilter.lowercased()
            let matchingDestinations = results.filter { pred in
                pred.destinationName.lowercased().contains(filterLower) ||
                (pred.towards?.lowercased().contains(filterLower) ?? false)
            }
            if !matchingDestinations.isEmpty { results = matchingDestinations }
        }

        if let platFilter = commute.platformFilter?.trimmingCharacters(in: .whitespacesAndNewlines), !platFilter.isEmpty {
            let platLower = platFilter.lowercased()
            let matchingPlatforms = results.filter { $0.platformName.lowercased().contains(platLower) }
            if !matchingPlatforms.isEmpty { results = matchingPlatforms }
        }

        // Sort by time to station
        results.sort { $0.timeToStation < $1.timeToStation }
        NSLog("[LA-DIAG][TfL] commute END id=%@ finalCount=%ld bundle=%@", commute.id.uuidString, results.count, Bundle.main.bundleIdentifier ?? "unknown")
        if !results.isEmpty {
            ArrivalCache.save(results, for: commute)
            NSLog("[LA-DIAG][TfL] shared cache published id=%@ count=%ld bundle=%@", commute.id.uuidString, results.count, Bundle.main.bundleIdentifier ?? "unknown")
        }
        return results
    }

    // MARK: - StopPoint Arrivals
    public func fetchArrivalsForStopPoint(stopPointId: String, lineId: String? = nil) async -> [ArrivalPrediction] {
        guard !stopPointId.isEmpty else {
            NSLog("[LA-DIAG][TfL] stop-point ABORT empty stationID")
            return []
        }

        // If ID is a HUB, expand first to children
        var idsToQuery = [stopPointId]
        if stopPointId.hasPrefix("HUB") {
            let children = await fetchHubChildren(hubId: stopPointId)
            if !children.isEmpty {
                idsToQuery = children
            }
        }

        var accumulated: [ArrivalPrediction] = []

        for id in idsToQuery {
            guard var comps = URLComponents(string: "\(baseURL)/StopPoint/\(id)/Arrivals") else { continue }
            appendAuth(to: &comps)
            guard let url = comps.url else { continue }

            do {
                NSLog("[LA-DIAG][TfL] stop-point REQUEST url=%@", url.absoluteString.replacingOccurrences(of: "app_key=[^&]+", with: "app_key=<redacted>", options: .regularExpression))
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    NSLog("[LA-DIAG][TfL] stop-point RESPONSE invalid response bytes=%ld", data.count)
                    continue
                }
                guard (200...299).contains(http.statusCode) else {
                    NSLog("[LA-DIAG][TfL] stop-point HTTP_ERROR status=%ld bytes=%ld", http.statusCode, data.count)
                    continue
                }
                NSLog("[LA-DIAG][TfL] stop-point HTTP_OK status=%ld bytes=%ld", http.statusCode, data.count)

                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let parsed = jsonArray.compactMap { parsePrediction(dict: $0) }
                    accumulated.append(contentsOf: parsed)
                }
            } catch {
                NSLog("[LA-DIAG][TfL] stop-point NETWORK_ERROR id=%@ error=%@", id, String(describing: error))
            }
        }

        if let line = lineId, !line.isEmpty {
            let lineLower = line.lowercased().replacingOccurrences(of: " ", with: "-")
            let matchingLine = accumulated.filter {
                $0.lineId.lowercased() == lineLower ||
                $0.lineName.lowercased().contains(lineLower) ||
                lineLower.contains($0.lineId.lowercased())
            }
            if !matchingLine.isEmpty { return matchingLine }
        }

        return accumulated
    }

    // MARK: - Line Arrivals
    public func fetchArrivalsForLine(lineId: String, stationName: String? = nil) async -> [ArrivalPrediction] {
        let cleanLineId = lineId.lowercased().replacingOccurrences(of: " ", with: "-")
        guard var comps = URLComponents(string: "\(baseURL)/Line/\(cleanLineId)/Arrivals") else { return [] }
        appendAuth(to: &comps)
        guard let url = comps.url else { return [] }

        do {
            NSLog("[LA-DIAG][TfL] line REQUEST url=%@", url.absoluteString.replacingOccurrences(of: "app_key=[^&]+", with: "app_key=<redacted>", options: .regularExpression))
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                NSLog("[LA-DIAG][TfL] line RESPONSE invalid response bytes=%ld", data.count)
                return []
            }
            guard (200...299).contains(http.statusCode) else {
                NSLog("[LA-DIAG][TfL] line HTTP_ERROR status=%ld bytes=%ld", http.statusCode, data.count)
                return []
            }
            NSLog("[LA-DIAG][TfL] line HTTP_OK status=%ld bytes=%ld", http.statusCode, data.count)

            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var parsed = jsonArray.compactMap { parsePrediction(dict: $0) }
                if let station = stationName, !station.isEmpty {
                    let stLower = station.lowercased()
                    let filtered = parsed.filter { $0.stationName.lowercased().contains(stLower) }
                    if !filtered.isEmpty {
                        parsed = filtered
                    }
                }
                return parsed
            }
        } catch {
            NSLog("[LA-DIAG][TfL] line NETWORK_ERROR lineID=%@ error=%@", cleanLineId, String(describing: error))
            return []
        }
        NSLog("[LA-DIAG][TfL] line EMPTY_OR_UNPARSEABLE lineID=%@", cleanLineId)
        return []
    }

    // MARK: - HUB resolution
    private func fetchHubChildren(hubId: String) async -> [String] {
        guard var comps = URLComponents(string: "\(baseURL)/StopPoint/\(hubId)") else { return [] }
        appendAuth(to: &comps)
        guard let url = comps.url else { return [] }

        do {
            let (data, _) = try await session.data(from: url)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let children = dict["children"] as? [[String: Any]] {
                return children.compactMap { $0["id"] as? String }
            }
        } catch {
            return []
        }
        return []
    }

    // MARK: - Search Stations
    public func searchStations(query: String) async -> [TfLStopPoint] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return TfLStopPoint.popularLondonStations }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        guard var comps = URLComponents(string: "\(baseURL)/StopPoint/Search/\(encoded)") else {
            return TfLStopPoint.popularLondonStations
        }
        comps.queryItems = [
            URLQueryItem(name: "modes", value: "tube,national-rail,elizabeth-line,overground,dlr")
        ]
        appendAuth(to: &comps)
        guard let url = comps.url else { return TfLStopPoint.popularLondonStations }

        do {
            let (data, _) = try await session.data(from: url)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let matches = dict["matches"] as? [[String: Any]] {
                var results: [TfLStopPoint] = []
                for match in matches {
                    guard let id = match["id"] as? String,
                          let name = match["name"] as? String else { continue }
                    let modes = (match["modes"] as? [String]) ?? []
                    let lat = match["lat"] as? Double
                    let lon = match["lon"] as? Double
                    results.append(TfLStopPoint(id: id, commonName: name, modes: modes, lines: [], lat: lat, lon: lon))
                }
                if !results.isEmpty {
                    return results
                }
            }
        } catch {
            // Return filtered popular stations on error
        }

        return TfLStopPoint.popularLondonStations.filter {
            $0.commonName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    // MARK: - Line Status
    public func fetchLineStatuses() async -> [TfLLine] {
        guard var comps = URLComponents(string: "\(baseURL)/Line/Mode/tube,elizabeth-line,overground,dlr/Status") else {
            return []
        }
        appendAuth(to: &comps)
        guard let url = comps.url else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }

            return jsonArray.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let name = dict["name"] as? String,
                      let modeName = dict["modeName"] as? String,
                      let statuses = dict["lineStatuses"] as? [[String: Any]],
                      !statuses.isEmpty else {
                    return nil
                }
                let descriptions = statuses.compactMap { $0["statusSeverityDescription"] as? String }
                guard !descriptions.isEmpty else { return nil }
                let reason = statuses.compactMap { $0["reason"] as? String }.first
                return TfLLine(
                    id: id,
                    name: name,
                    modeName: modeName,
                    statusSeverityDescription: descriptions.joined(separator: " · "),
                    reason: reason
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - JSON Parser
    private func parsePrediction(dict: [String: Any]) -> ArrivalPrediction? {
        guard let id = (dict["id"] as? String) ?? (dict["id"] as? Int).map(String.init),
              let lineId = dict["lineId"] as? String,
              let lineName = dict["lineName"] as? String,
              let destinationName = dict["destinationName"] as? String,
              let timeToStation = dict["timeToStation"] as? Int else {
            return nil
        }

        let platformName = (dict["platformName"] as? String) ?? ""
        let stationName = (dict["stationName"] as? String) ?? ""
        let towards = dict["towards"] as? String
        let currentLocation = dict["currentLocation"] as? String
        let modeName = dict["modeName"] as? String

        var expDate = Date().addingTimeInterval(TimeInterval(timeToStation))
        if let expStr = dict["expectedArrival"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: expStr) {
                expDate = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: expStr) {
                    expDate = date
                }
            }
        }

        return ArrivalPrediction(
            id: id,
            lineId: lineId,
            lineName: lineName,
            destinationName: destinationName,
            platformName: platformName,
            stationName: stationName,
            timeToStation: timeToStation,
            expectedArrival: expDate,
            towards: towards,
            currentLocation: currentLocation,
            modeName: modeName
        )
    }

}
