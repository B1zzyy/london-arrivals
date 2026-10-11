import Foundation

public struct FavouriteCommute: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var mode: TransportMode
    public var lineId: String
    public var lineName: String
    public var originStationId: String
    public var originStationName: String
    public var destinationFilter: String?
    public var platformFilter: String?
    public var directionFilter: String?
    public var directionFilters: [String]?
    public var theme: BoardTheme
    public var isPrimaryWidget: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        mode: TransportMode,
        lineId: String,
        lineName: String,
        originStationId: String,
        originStationName: String,
        destinationFilter: String? = nil,
        platformFilter: String? = nil,
        directionFilter: String? = nil,
        directionFilters: [String]? = nil,
        theme: BoardTheme = .undergroundAmber,
        isPrimaryWidget: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.mode = mode
        self.lineId = lineId
        self.lineName = lineName
        self.originStationId = originStationId
        self.originStationName = originStationName
        self.destinationFilter = destinationFilter
        self.platformFilter = platformFilter
        self.directionFilter = directionFilter
        self.directionFilters = directionFilters ?? directionFilter.map { [$0] }
        self.theme = theme
        self.isPrimaryWidget = isPrimaryWidget
        self.createdAt = createdAt
    }

    /// No default commutes - user adds their own
    public static var defaults: [FavouriteCommute] {
        []
    }
}
