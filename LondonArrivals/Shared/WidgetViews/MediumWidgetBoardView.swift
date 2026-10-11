import SwiftUI
import WidgetKit

public struct MediumWidgetBoardView: View {
    public var entry: CommuteEntry

    public init(entry: CommuteEntry) {
        self.entry = entry
    }

    public var body: some View {
        DotMatrixBoardView(
            commuteTitle: "\(entry.commute.originStationName) · \(entry.commute.lineName)",
            platformName: "",
            predictions: entry.predictions,
            theme: entry.commute.theme,
            maxRows: 4,
            showHeader: true,
            showStatusTicker: true,
            showBezel: false,
            statusText: entry.statusMessage,
            statusInHeader: true,
            fontSize: 14
        )
    }
}
