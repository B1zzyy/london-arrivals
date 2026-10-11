import WidgetKit
import Foundation

public struct CommuteEntry: TimelineEntry {
    public let date: Date
    public let commute: FavouriteCommute
    public let predictions: [ArrivalPrediction]
    public let statusMessage: String

    public init(date: Date, commute: FavouriteCommute, predictions: [ArrivalPrediction], statusMessage: String = "") {
        self.date = date
        self.commute = commute
        self.predictions = predictions
        self.statusMessage = statusMessage
    }
}

public struct CommuteWidgetTimelineProvider: AppIntentTimelineProvider {
    public typealias Entry = CommuteEntry
    public typealias Intent = SelectCommuteIntent

    public func placeholder(in context: Context) -> CommuteEntry {
        let storage = CommuteStorage.shared
        storage.load()
        guard let commute = storage.primaryCommute else {
            return CommuteEntry(date: Date(), commute: emptyCommute, predictions: [], statusMessage: "ADD COMMUTE IN APP")
        }
        return CommuteEntry(date: Date(), commute: commute, predictions: [], statusMessage: "LOADING ARRIVALS")
    }

    public func snapshot(for configuration: SelectCommuteIntent, in context: Context) async -> CommuteEntry {
        await makeEntry(for: configuration)
    }

    func diagnosticEntry(for configuration: SelectCommuteIntent) async -> CommuteEntry {
        await makeEntry(for: configuration)
    }

    public func timeline(for configuration: SelectCommuteIntent, in context: Context) async -> Timeline<CommuteEntry> {
        let entry = await makeEntry(for: configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
    }

    func diagnosticStoredCommute(for configuration: SelectCommuteIntent) -> FavouriteCommute? {
        let storage = CommuteStorage.shared
        storage.load()
        let configuredId = configuration.commute.flatMap { UUID(uuidString: $0.id) }
        return configuredId.flatMap { id in storage.commutes.first(where: { $0.id == id }) }
            ?? storage.primaryCommute
    }

    private func makeEntry(for configuration: SelectCommuteIntent) async -> CommuteEntry {
        let storage = CommuteStorage.shared
        storage.load()
        let commute = diagnosticStoredCommute(for: configuration)
        guard let commute else {
            return CommuteEntry(date: Date(), commute: emptyCommute, predictions: [], statusMessage: "ADD COMMUTE IN APP")
        }
        let cached = ArrivalCache.load(for: commute)
        let live = await TfLService.shared.fetchArrivals(for: commute)
        let refreshedCache = ArrivalCache.load(for: commute)
        let predictions = live.isEmpty ? (refreshedCache.isEmpty ? cached : refreshedCache) : live
        return CommuteEntry(date: Date(), commute: commute, predictions: predictions,
                            statusMessage: predictions.isEmpty ? "NO LIVE ARRIVALS" : "")
    }

    private var emptyCommute: FavouriteCommute {
        FavouriteCommute(title: "Add a commute", mode: .tube, lineId: "", lineName: "",
                         originStationId: "", originStationName: "No station")
    }
}
