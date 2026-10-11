import WidgetKit
import SwiftUI

struct LondonArrivalsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: CommuteWidgetTimelineProvider.Entry

    var body: some View {
        let _ = NSLog("[LA-DIAG][WidgetView] rendered bundle=%@ family=%@ station=%@ predictions=%ld status=%@",
                      Bundle.main.bundleIdentifier ?? "unknown",
                      String(describing: family),
                      entry.commute.originStationName,
                      entry.predictions.count,
                      entry.statusMessage)
        switch family {
        case .systemSmall:
            SmallWidgetBoardView(entry: entry)
        case .systemMedium:
            MediumWidgetBoardView(entry: entry)
        case .systemLarge:
            LargeWidgetBoardView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        default:
            MediumWidgetBoardView(entry: entry)
        }
    }
}

public struct LondonArrivalsWidget: Widget {
    public let kind: String = "LondonArrivalsWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        let _ = NSLog("[LA-DIAG][Widget] configuration evaluated bundle=%@ kind=%@", Bundle.main.bundleIdentifier ?? "unknown", kind)
        return AppIntentConfiguration(
            kind: kind,
            intent: SelectCommuteIntent.self,
            provider: CommuteWidgetTimelineProvider()
        ) { entry in
            LondonArrivalsWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    entry.commute.theme.screenBackground
                }
        }
        .configurationDisplayName("London Arrivals Board")
        .description("Live London Underground & National Rail arrivals board widget.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}
