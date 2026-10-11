import Foundation
import WidgetKit

/// Shared last-known TfL predictions for the app and widget extension.
public enum ArrivalCache {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.antigravity.londonarrivals")
    }
    private static let keyPrefix = "arrival_cache_"
    private static let commuteStorageKey = "saved_favourite_commutes"
    private static let widgetReloadKey = "arrival_cache_last_widget_reload"
    private static let widgetReloadMinimumInterval: TimeInterval = 5 * 60
    private static var encoder: JSONEncoder { JSONEncoder() }
    private static var decoder: JSONDecoder { JSONDecoder() }

    public static func clearAll() {
        guard let defaults else { return }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func load(for commute: FavouriteCommute) -> [ArrivalPrediction] {
        NSLog("[LA-DIAG][Cache] LOAD bundle=%@ commuteID=%@", Bundle.main.bundleIdentifier ?? "unknown", commute.id.uuidString)
        guard isCurrentlySaved(commute),
              let defaults,
              let data = defaults.data(forKey: key(for: commute)),
              let predictions = try? decoder.decode([ArrivalPrediction].self, from: data) else {
            return []
        }
        NSLog("[LA-DIAG][Cache] DECODED bundle=%@ commuteID=%@ count=%ld", Bundle.main.bundleIdentifier ?? "unknown", commute.id.uuidString, predictions.count)
        return predictions.filter { $0.expectedArrival > Date() }
            .map { prediction in
                var updated = prediction
                updated.timeToStation = max(0, Int(prediction.expectedArrival.timeIntervalSinceNow))
                return updated
            }
            .sorted { $0.timeToStation < $1.timeToStation }
    }

    /// Only non-empty live responses replace the saved snapshot. An empty result may
    /// represent a transient request/filter failure, so preserve the previous board.
    /// Publish the new snapshot to WidgetKit after it is committed to the shared suite.
    public static func save(_ predictions: [ArrivalPrediction], for commute: FavouriteCommute) {
        NSLog("[LA-DIAG][Cache] SAVE requested bundle=%@ commuteID=%@ count=%ld", Bundle.main.bundleIdentifier ?? "unknown", commute.id.uuidString, predictions.count)
        guard !predictions.isEmpty,
              let defaults,
              let data = try? encoder.encode(predictions) else { return }
        defaults.set(data, forKey: key(for: commute))
        defaults.set(Date(), forKey: key(for: commute) + "_savedAt")
        defaults.synchronize()
        requestWidgetReloadIfPrimaryCommute(commute)
    }

    private static func requestWidgetReloadIfPrimaryCommute(_ commute: FavouriteCommute) {
        guard isCurrentlySaved(commute), let defaults else {
            NSLog("[LA-DIAG][Cache] reload skipped commute is not saved or app group unavailable commuteID=%@", commute.id.uuidString)
            return
        }

        // App polling can save every few seconds; respect WidgetKit's reload budget.
        let now = Date()
        let lastReload = defaults.object(forKey: widgetReloadKey) as? Date ?? .distantPast
        guard now.timeIntervalSince(lastReload) >= widgetReloadMinimumInterval else {
            NSLog("[LA-DIAG][Cache] reload throttled remainingSeconds=%.0f commuteID=%@", widgetReloadMinimumInterval - now.timeIntervalSince(lastReload), commute.id.uuidString)
            return
        }
        defaults.set(now, forKey: widgetReloadKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "LondonArrivalsWidget")
        NSLog("[LA-DIAG][Cache] requested WidgetKit timeline reload kind=LondonArrivalsWidget commuteID=%@ bundle=%@", commute.id.uuidString, Bundle.main.bundleIdentifier ?? "unknown")
    }

    private static func isCurrentlySaved(_ commute: FavouriteCommute) -> Bool {
        guard let defaults,
              let data = defaults.data(forKey: commuteStorageKey),
              let commutes = try? decoder.decode([FavouriteCommute].self, from: data) else {
            return false
        }
        return commutes.contains { $0.id == commute.id }
    }


    private static func key(for commute: FavouriteCommute) -> String {
        keyPrefix + commute.id.uuidString
    }
}
