import Foundation
import Combine
import WidgetKit

public final class CommuteStorage: ObservableObject {
    public static let shared = CommuteStorage()

    private let storageKey = "saved_favourite_commutes"
    private let primaryKey = "primary_widget_commute_id"
    private let appGroupSuite = "group.com.antigravity.londonarrivals"
    private let testDefaults: UserDefaults?
    private let reloadWidgetTimelines: () -> Void

    private var defaults: UserDefaults? { testDefaults ?? UserDefaults(suiteName: appGroupSuite) }

    @Published public var commutes: [FavouriteCommute] = []
    @Published public private(set) var primaryCommuteId: UUID?
    private var isLoading = false

    private init() {
        testDefaults = nil
        reloadWidgetTimelines = { WidgetCenter.shared.reloadAllTimelines() }
        load()
    }

    internal init(testDefaults: UserDefaults, reloadWidgetTimelines: @escaping () -> Void = {}) {
        self.testDefaults = testDefaults
        self.reloadWidgetTimelines = reloadWidgetTimelines
        load()
    }

    public var primaryCommute: FavouriteCommute? {
        guard let defaults else { return nil }
        let savedID = defaults.string(forKey: primaryKey).flatMap(UUID.init(uuidString:))
        if let savedID, let match = commutes.first(where: { $0.id == savedID }) { return match }
        if let primaryCommuteId, let match = commutes.first(where: { $0.id == primaryCommuteId }) { return match }
        return nil
    }

    public var hasCommutes: Bool { !commutes.isEmpty }

    public func load() {
        let sharedDefaults = defaults
        let loadedData = sharedDefaults?.data(forKey: storageKey)
        let role = Bundle.main.bundleIdentifier?.hasSuffix(".widget") == true ? "extension" : "app-or-other"
        NSLog("[LA-DIAG][Storage] role=%@ bundle=%@ appGroupAvailable=%@ data=%@", role,
              Bundle.main.bundleIdentifier ?? "unknown", sharedDefaults == nil ? "false" : "true",
              loadedData == nil ? "missing" : "present")
        isLoading = true
        defer { isLoading = false }
        guard let sharedDefaults else {
            NSLog("[LA-DIAG][Storage] App Group unavailable; refusing fallback reads/writes")
            commutes = []
            primaryCommuteId = nil
            return
        }
        if let data = sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([FavouriteCommute].self, from: data) {
            commutes = decoded
        } else {
            commutes = FavouriteCommute.defaults
            if !commutes.isEmpty, let data = try? JSONEncoder().encode(commutes) { sharedDefaults.set(data, forKey: storageKey) }
        }
        let savedID = sharedDefaults.string(forKey: primaryKey).flatMap(UUID.init(uuidString:))
        let resolved = savedID.flatMap { id in commutes.contains(where: { $0.id == id }) ? id : nil }
            ?? commutes.first(where: \.isPrimaryWidget)?.id ?? commutes.first?.id
        primaryCommuteId = resolved
        for index in commutes.indices { commutes[index].isPrimaryWidget = commutes[index].id == resolved }
        if let data = try? JSONEncoder().encode(commutes) { sharedDefaults.set(data, forKey: storageKey) }
        if let resolved { sharedDefaults.set(resolved.uuidString, forKey: primaryKey) }
        else { sharedDefaults.removeObject(forKey: primaryKey) }
        sharedDefaults.synchronize()
    }

    public func save() {
        guard !isLoading else { return }
        persistPrimaryState()
        reloadWidgetTimelines()
    }

    private func persistPrimaryState() {
        guard let defaults else {
            NSLog("[LA-DIAG][Storage] persist refused: App Group suite unavailable")
            return
        }
        let chosen = primaryCommuteId.flatMap { id in commutes.first(where: { $0.id == id })?.id }
            ?? commutes.first(where: \.isPrimaryWidget)?.id ?? commutes.first?.id
        for index in commutes.indices { commutes[index].isPrimaryWidget = commutes[index].id == chosen }
        if let data = try? JSONEncoder().encode(commutes) { defaults.set(data, forKey: storageKey) }
        if let chosen { defaults.set(chosen.uuidString, forKey: primaryKey) }
        else { defaults.removeObject(forKey: primaryKey) }
        defaults.synchronize()
    }

    public func addCommute(_ commute: FavouriteCommute) {
        guard defaults != nil else {
            NSLog("[LA-DIAG][Storage] addCommute refused: App Group suite unavailable")
            return
        }
        var newCommute = commute
        let becomesPrimary = commutes.isEmpty || primaryCommuteId == nil
        newCommute.isPrimaryWidget = becomesPrimary
        commutes.append(newCommute)
        if becomesPrimary { primaryCommuteId = newCommute.id }
        save()
    }

    public func updateCommute(_ commute: FavouriteCommute) {
        if let index = commutes.firstIndex(where: { $0.id == commute.id }) { commutes[index] = commute; save() }
    }

    public func deleteCommute(id: UUID) {
        commutes.removeAll { $0.id == id }
        if primaryCommuteId == id { primaryCommuteId = commutes.first?.id }
        save()
    }

    public func deleteCommute(at offsets: IndexSet) {
        commutes.remove(atOffsets: offsets)
        if let primaryCommuteId, !commutes.contains(where: { $0.id == primaryCommuteId }) { self.primaryCommuteId = commutes.first?.id }
        save()
    }

    public func setPrimaryCommute(id: UUID) {
        guard commutes.contains(where: { $0.id == id }), let defaults else { return }
        for index in commutes.indices { commutes[index].isPrimaryWidget = commutes[index].id == id }
        if let data = try? JSONEncoder().encode(commutes) { defaults.set(data, forKey: storageKey) }
        defaults.set(id.uuidString, forKey: primaryKey)
        defaults.synchronize()
        primaryCommuteId = id
        ArrivalCache.clearAll()
        reloadWidgetTimelines()
    }
}
