import SwiftUI
import WidgetKit

public struct WidgetGalleryView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var predictions: [ArrivalPrediction] = []
    @State private var isLoading: Bool = true

    public init(storage: CommuteStorage = CommuteStorage.shared) {
        self.storage = storage
    }

    private var primaryCommute: FavouriteCommute? {
        storage.primaryCommute
    }

    private var entry: CommuteEntry? {
        guard let commute = primaryCommute else { return nil }
        return CommuteEntry(
            date: Date(),
            commute: commute,
            predictions: predictions,
            statusMessage: predictions.isEmpty ? (isLoading ? "FETCHING ARRIVALS" : "NO LIVE ARRIVALS") : ""
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add a Live Arrivals Widget")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("First save at least one commute in Favourites. Then add London Arrivals from the iPhone Home Screen widget gallery. Long-press the widget and choose Edit Widget to select the saved board it should display. If you leave Board unselected, it follows the app's primary board.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // 1. Medium Widget (Flagship 3-row London Platform Display)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Medium Widget (Platform Indicator)")
                                .font(.headline)
                            Spacer()
                            Text("Iconic 3-Row DMI")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)

                        if let entry {
                            MediumWidgetBoardView(entry: entry)
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.5), radius: 10, y: 5)
                                .padding(.horizontal)
                        } else {
                            noPrimaryCommuteView
                        }
                    }

                    // 2. Small Widget (Compact Next Train Board)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Small Widget (Next Train)")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack {
                            if let entry {
                                SmallWidgetBoardView(entry: entry)
                                    .frame(width: 160, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.5), radius: 10, y: 5)
                            } else {
                                noPrimaryCommuteView.frame(width: 160, height: 160)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("High-Impact Hero")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Features big amber LED countdown minutes with destination and second-train queue.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // 3. Lock Screen Widget (Rectangular)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lock Screen Widget (Accessory Rectangular)")
                            .font(.headline)
                            .padding(.horizontal)

                        if let entry {
                            RectangularLockScreenView(entry: entry)
                                .padding(12)
                                .frame(width: 160, height: 70)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .padding(.horizontal)
                        } else {
                            noPrimaryCommuteView
                        }
                    }

                    // 4. Large Widget (Full Station Departure Board)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Widget (Full Station Departures)")
                            .font(.headline)
                            .padding(.horizontal)

                        if let entry {
                            LargeWidgetBoardView(entry: entry)
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.5), radius: 10, y: 5)
                                .padding(.horizontal)
                        } else {
                            noPrimaryCommuteView
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Widget Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        loadArrivals()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                loadArrivals()
            }
        }
    }

    private var noPrimaryCommuteView: some View {
        ContentUnavailableView(
            "Save a commute first",
            systemImage: "rectangle.and.waveform",
            description: Text("Add a board in Favourites. It will then appear in the Home Screen widget's Edit Widget board picker.")
        )
        .padding()
    }

    private func loadArrivals() {
        storage.load()
        guard let commute = primaryCommute else {
            self.predictions = []
            self.isLoading = false
            return
        }
        isLoading = true
        Task {
            let res = await TfLService.shared.fetchArrivals(for: commute)
            await MainActor.run {
                if self.primaryCommute?.id == commute.id {
                    self.predictions = res
                    if !res.isEmpty { ArrivalCache.save(res, for: commute) }
                }
                self.isLoading = false
            }
        }
    }
}
