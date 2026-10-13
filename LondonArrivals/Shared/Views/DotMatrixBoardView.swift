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
                    MarqueeHeaderView(
                        title: headerTitle.uppercased(),
                        statusText: statusInHeader ? (statusText ?? "GOOD SERVICE").uppercased() : nil,
                        theme: theme,
                        fontSize: fontSize
                    )
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

/// Marquee header view that scrolls left-to-right only if text exceeds available width
struct MarqueeHeaderView: View {
    let title: String
    let statusText: String?
    let theme: BoardTheme
    let fontSize: CGFloat

    @State private var animate = false

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Measuring text width via hidden background text or estimation
                    MarqueeInnerView(title: title, theme: theme, fontSize: fontSize)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                .clipped()
            }
            .frame(height: max(14, fontSize))

            if let status = statusText {
                DotMatrixText(
                    status,
                    size: max(9, fontSize - 3),
                    weight: .medium,
                    theme: theme,
                    tracking: 0.6
                )
                .lineLimit(1)
                .layoutPriority(1)
            }
        }
    }
}

struct MarqueeInnerView: View {
    let title: String
    let theme: BoardTheme
    let fontSize: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack(alignment: .leading) {
                DotMatrixText(
                    title,
                    size: max(10, fontSize - 2),
                    weight: .semibold,
                    theme: theme,
                    tracking: 1.2
                )
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    GeometryReader { textProxy in
                        Color.clear.onAppear {
                            textWidth = textProxy.size.width
                            containerWidth = w
                            checkAnimation()
                        }
                        .onChange(of: textProxy.size.width) { _, newW in
                            textWidth = newW
                            checkAnimation()
                        }
                    }
                )
                .offset(x: offset)
            }
            .onChange(of: w) { _, newC in
                containerWidth = newC
                checkAnimation()
            }
        }
    }

    private func checkAnimation() {
        guard textWidth > containerWidth, containerWidth > 0 else {
            offset = 0
            isAnimating = false
            return
        }
        if !isAnimating {
            isAnimating = true
            startMarquee()
        }
    }

    private func startMarquee() {
        let distance = textWidth - containerWidth + 20
        let duration = Double(distance) * 0.05 // smooth speed

        // Initial pause at start
        offset = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard isAnimating else { return }
            withAnimation(.linear(duration: duration)) {
                offset = -distance
            }
            // Pause at end then reset
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.5) {
                guard isAnimating else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isAnimating {
                        startMarquee()
                    }
                }
            }
        }
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
