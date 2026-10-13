import SwiftUI

public struct DotMatrixBoardView: View {
    public var commuteTitle: String
    public var platformName: String
    public var predictions: [ArrivalPrediction]
    public var theme: BoardTheme
    public var maxRows: Int
    public var showHeader: Bool
    public var showStatusTicker: Bool
    public var showBezel: Bool
    public var statusText: String?
    public var statusInHeader: Bool
    public var fontSize: CGFloat

    public init(
        commuteTitle: String,
        platformName: String,
        predictions: [ArrivalPrediction],
        theme: BoardTheme = .undergroundAmber,
        maxRows: Int = 3,
        showHeader: Bool = true,
        showStatusTicker: Bool = true,
        showBezel: Bool = true,
        statusText: String? = nil,
        statusInHeader: Bool = false,
        fontSize: CGFloat = 13
    ) {
        self.commuteTitle = commuteTitle
        self.platformName = platformName
        self.predictions = predictions
        self.theme = theme
        self.maxRows = maxRows
        self.showHeader = showHeader
        self.showStatusTicker = showStatusTicker
        self.showBezel = showBezel
        self.statusText = statusText
        self.statusInHeader = statusInHeader
        self.fontSize = fontSize
    }

    public var body: some View {
        if showBezel {
            BoardBezelView(theme: theme, showScrews: true) {
                boardContent
            }
        } else {
            boardContent
        }
    }

    private var boardContent: some View {
        ZStack {
            // Background LED dot matrix substrate
            LEDGridBackground(dotColor: theme.unlitDotColor, spacing: 5.0, dotSize: 1.5)

            VStack(alignment: .leading, spacing: statusInHeader ? 3 : 6) {
                // Top Platform Header Bar
                if showHeader {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.ledColor)
                            .frame(width: 4, height: 4)
                            .shadow(color: theme.glowColor, radius: 2)

                        DotMatrixText(
                            headerTitle.uppercased(),
                            size: max(10, fontSize - 2),
                            weight: .semibold,
                            theme: theme,
                            tracking: 1.2
                        )
                        .lineLimit(1)

                        Spacer()

                        if statusInHeader {
                            DotMatrixText(
                                (statusText ?? "GOOD SERVICE").uppercased(),
                                size: max(9, fontSize - 3),
                                weight: .medium,
                                theme: theme,
                                tracking: 0.6
                            )
                            .lineLimit(1)
                        } else {
                        }
                    }
                    .padding(.bottom, 2)

                    // Subtle separator line
                    Rectangle()
                        .fill(theme.unlitDotColor.opacity(0.8))
                        .frame(height: 1)
                        .padding(.bottom, 2)
                }

                // Departures Rows
                if predictions.isEmpty && statusText == "ADD COMMUTE" {
                    DotMatrixText("ADD A COMMUTE IN THE APP", size: fontSize, weight: .bold, theme: theme)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.vertical, 8)
                } else if predictions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            DotMatrixText("1", size: fontSize, weight: .bold, theme: theme)
                            DotMatrixText("CHECKING ARRIVALS...", size: fontSize, weight: .bold, theme: theme)
                            Spacer()
                            DotMatrixText("--", size: fontSize, weight: .bold, theme: theme)
                        }
                        HStack {
                            DotMatrixText("2", size: fontSize, weight: .bold, theme: theme)
                            DotMatrixText("PLEASE WAIT", size: fontSize, weight: .bold, theme: theme)
                            Spacer()
                            DotMatrixText("--", size: fontSize, weight: .bold, theme: theme)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    let displayRows = Array(predictions.prefix(maxRows))
                    VStack(alignment: .leading, spacing: statusInHeader ? 2 : 5) {
                        ForEach(Array(displayRows.enumerated()), id: \.element.id) { index, prediction in
                            DepartureRowView(
                                index: index + 1,
                                prediction: prediction,
                                theme: theme,
                                fontSize: fontSize
                            )
                        }
                    }
                }

                Spacer(minLength: 0)

                if showStatusTicker {
                    Rectangle()
                        .fill(theme.unlitDotColor.opacity(0.8))
                        .frame(height: 1)
                        .padding(.top, 2)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.ledColor)
                            .frame(width: 3.5, height: 3.5)
                            .shadow(color: theme.glowColor, radius: 2)

                        DotMatrixText(
                            tickerMessage.uppercased(),
                            size: max(9.5, fontSize - 3),
                            weight: .medium,
                            theme: theme,
                            tracking: 1.0
                        )
                        .lineLimit(1)

                        Spacer()
                    }
                    .padding(.top, 1)
                }
            }
            .padding(10)
        }
    }

    private var headerTitle: String {
        commuteTitle
    }

    private var tickerMessage: String {
        if let first = predictions.first, let location = first.currentLocation, !location.isEmpty {
            return location
        }
        if let first = predictions.first, first.minutesUntilArrival == 0 {
            return "TRAIN NOW STANDING AT PLATFORM"
        }
        return ""
    }

}

/// A single arrival row formatted exactly like the platform LED display
struct DepartureRowView: View {
    var index: Int
    var prediction: ArrivalPrediction
    var theme: BoardTheme
    var fontSize: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            // Position number: "1", "2", "3"
            DotMatrixText(
                "\(index)",
                size: fontSize,
                weight: .black,
                theme: theme,
                tracking: 0.5
            )
            .frame(width: fontSize * 0.9, alignment: .leading)

            // Destination
            DotMatrixText(
                prediction.matrixDestination,
                size: fontSize,
                weight: .bold,
                theme: theme,
                tracking: 0.8
            )
            .lineLimit(1)
            .truncationMode(.tail)

            Spacer(minLength: 4)

            // Show the actual platform supplied by TfL, in compact Px form.
            if !prediction.cleanPlatform.isEmpty {
                DotMatrixText(
                    prediction.shortPlatform.uppercased(),
                    size: max(9, fontSize - 2.5),
                    weight: .medium,
                    theme: theme,
                    tracking: 0.5
                )
                .padding(.horizontal, 2)
            }

            // Countdown: "DUE", "1 MIN", "5 MIN"
            DotMatrixText(
                prediction.matrixCountdown,
                size: fontSize,
                weight: .heavy,
                theme: theme,
                tracking: 0.8
            )
            .frame(minWidth: fontSize * 3.4, alignment: .trailing)
        }
    }
}
