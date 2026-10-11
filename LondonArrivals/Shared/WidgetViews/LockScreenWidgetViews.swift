import SwiftUI
import WidgetKit

public struct RectangularLockScreenView: View {
    public var entry: CommuteEntry

    public init(entry: CommuteEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(entry.commute.theme.ledColor)
                    .frame(width: 4, height: 4)
                Text("\(entry.commute.originStationName) · \(entry.commute.lineName)".uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .lineLimit(1)
            }

            if let first = entry.predictions.first {
                HStack(alignment: .firstTextBaseline) {
                    Text(first.matrixDestination)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text(first.matrixCountdown)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                }
            } else {
                Text(entry.statusMessage.isEmpty ? "NO ARRIVALS" : entry.statusMessage)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .lineLimit(1)
            }

            if entry.predictions.count > 1 {
                let second = entry.predictions[1]
                Text("2nd: \(second.cleanDestination) (\(second.dmiCountdown))")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

public struct InlineLockScreenView: View {
    public var entry: CommuteEntry

    public init(entry: CommuteEntry) {
        self.entry = entry
    }

    public var body: some View {
        if let first = entry.predictions.first {
            Text("🚆 \(entry.commute.originStationName) · \(entry.commute.lineName): \(first.dmiCountdown)")
        } else {
            Text("🚆 \(entry.commute.originStationName) · \(entry.commute.lineName)")
        }
    }
}

public struct CircularLockScreenView: View {
    public var entry: CommuteEntry

    public init(entry: CommuteEntry) {
        self.entry = entry
    }

    public var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let first = entry.predictions.first {
                VStack(spacing: 0) {
                    Text("\(first.minutesUntilArrival)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                    Text("MIN")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                }
            } else {
                Text("--")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
        }
    }
}
