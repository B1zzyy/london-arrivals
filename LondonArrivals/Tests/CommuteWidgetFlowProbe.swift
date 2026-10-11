#if LA_WIDGET_FLOW_TEST
import Foundation

@testable import LondonArrivals

enum CommuteWidgetFlowProbe {
    static func run() throws {
        let suite = "group.com.antigravity.londonarrivals"
        guard let defaults = UserDefaults(suiteName: suite) else {
            throw ProbeFailure("App Group defaults suite unavailable")
        }
        defaults.removePersistentDomain(forName: suite)

        let commuteID = UUID(uuidString: "9A215778-502C-4C89-A968-09B1D05755B6")!
        let commute = FavouriteCommute(
            id: commuteID,
            title: "Deterministic test",
            mode: .tube,
            lineId: "victoria",
            lineName: "Victoria",
            originStationId: "940GZZLUKSX",
            originStationName: "King's Cross St. Pancras",
            isPrimaryWidget: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        var widgetReloads = 0
        let appStorage = CommuteStorage(testDefaults: defaults) { widgetReloads += 1 }
        appStorage.addCommute(commute)
        appStorage.setPrimaryCommute(id: commuteID)
        try require(widgetReloads >= 1, "Saving the app commute did not request a widget timeline refresh")

        let widgetDefaults = try requireValue(UserDefaults(suiteName: suite), "Widget could not open the shared defaults suite")
        widgetDefaults.synchronize()
        let encodedCommutes = try requireValue(widgetDefaults.data(forKey: "saved_favourite_commutes"), "App did not persist commute JSON")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let widgetCommutes = try decoder.decode([FavouriteCommute].self, from: encodedCommutes)
        try require(widgetCommutes.map(\.id) == [commuteID], "Widget suite did not return the app-saved commute")
        try require(widgetDefaults.string(forKey: "primary_widget_commute_id") == commuteID.uuidString, "Primary commute ID did not cross the shared suite")

        let widgetStorage = CommuteStorage(testDefaults: widgetDefaults)
        widgetStorage.load()
        try require(widgetStorage.primaryCommute?.originStationName == "King's Cross St. Pancras", "Independent widget storage selected the wrong primary station")

        let provider = CommuteWidgetTimelineProvider()
        let primarySelection = provider.diagnosticStoredCommute(for: SelectCommuteIntent())
        try require(primarySelection?.id == commuteID, "Provider did not resolve the saved primary commute")
        try require(primarySelection?.originStationName == "King's Cross St. Pancras", "Provider resolved the wrong station")

        let selectedConfiguration = SelectCommuteIntent()
        selectedConfiguration.commute = SavedCommuteEntity(
            id: commuteID.uuidString,
            title: commute.title,
            station: commute.originStationName,
            line: commute.lineName
        )
        let configuredSelection = provider.diagnosticStoredCommute(for: selectedConfiguration)
        try require(configuredSelection?.id == commuteID, "Provider did not resolve the configured commute ID")
        try require(configuredSelection?.originStationId == "940GZZLUKSX", "Configured commute selected the wrong origin station")

        defaults.removePersistentDomain(forName: suite)
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw ProbeFailure(message) }
    }

    private static func requireValue<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else { throw ProbeFailure(message) }
        return value
    }

    private struct ProbeFailure: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}
#endif
