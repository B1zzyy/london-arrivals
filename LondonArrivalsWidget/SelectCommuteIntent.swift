import AppIntents
import Foundation

public struct SavedCommuteEntity: AppEntity {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Commute")
    public static var defaultQuery = SavedCommuteQuery()

    public var id: String
    public var title: String
    public var station: String
    public var line: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(station) · \(line)", subtitle: "\(title)")
    }

    public init(id: String, title: String, station: String, line: String) {
        self.id = id
        self.title = title
        self.station = station
        self.line = line
    }
}

public struct SavedCommuteQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [SavedCommuteEntity] {
        NSLog("[LA-DIAG][Picker] entities ENTER bundle=%@ requestedIDs=%@", Bundle.main.bundleIdentifier ?? "unknown", identifiers.joined(separator: ","))
        let all = loadEntities()
        let found = identifiers.compactMap { id in all.first(where: { $0.id == id }) }
        NSLog("[LA-DIAG][Picker] entities EXIT requested=%ld found=%ld", identifiers.count, found.count)
        return found
    }

    public func suggestedEntities() async throws -> [SavedCommuteEntity] {
        NSLog("[LA-DIAG][Picker] suggestedEntities ENTER bundle=%@", Bundle.main.bundleIdentifier ?? "unknown")
        let entities = loadEntities()
        NSLog("[LA-DIAG][Picker] suggestedEntities EXIT count=%ld ids=%@", entities.count, entities.map(\.id).joined(separator: ","))
        return entities
    }

    private func loadEntities() -> [SavedCommuteEntity] {
        let suite = "group.com.antigravity.londonarrivals"
        NSLog("[LA-DIAG][Picker] loadEntities bundle=%@", Bundle.main.bundleIdentifier ?? "unknown")
        let role = Bundle.main.bundleIdentifier?.hasSuffix(".widget") == true ? "extension" : "app-or-other"
        guard let defaults = UserDefaults(suiteName: suite) else {
            NSLog("[LA-DIAG][Picker] role=%@ app-group-unavailable bundle=%@", role, Bundle.main.bundleIdentifier ?? "unknown")
            return []
        }
        defaults.synchronize()
        guard let data = defaults.data(forKey: "saved_favourite_commutes") else {
            NSLog("[LA-DIAG][Picker] role=%@ no-commute-data bundle=%@", role, Bundle.main.bundleIdentifier ?? "unknown")
            return []
        }
        guard let commutes = try? JSONDecoder().decode([FavouriteCommute].self, from: data) else {
            NSLog("[LA-DIAG][Picker] role=%@ commute-data-decode-failed bytes=%ld", role, data.count)
            return []
        }
        NSLog("[LA-DIAG][Picker] role=%@ bundle=%@ suggestedCommutes=%ld", role, Bundle.main.bundleIdentifier ?? "unknown", commutes.count)
        return commutes.map {
            SavedCommuteEntity(
                id: $0.id.uuidString,
                title: $0.title,
                station: $0.originStationName,
                line: $0.lineName
            )
        }
    }
}

public struct SelectCommuteIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Choose a Commute"
    public static var description = IntentDescription("Choose which saved arrivals board this widget displays.")

    @Parameter(title: "Board")
    public var commute: SavedCommuteEntity? {
        didSet {
            NSLog("[LA-DIAG][Intent] commute changed id=%@ title=%@ station=%@", commute?.id ?? "<none>", commute?.title ?? "<none>", commute?.station ?? "<none>")
        }
    }

    public init() {
        NSLog("[LA-DIAG][Intent] initialized bundle=%@", Bundle.main.bundleIdentifier ?? "unknown")
    }
}
