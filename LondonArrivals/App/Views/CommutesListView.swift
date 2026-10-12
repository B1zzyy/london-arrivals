import SwiftUI

public struct CommutesListView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var showingAddSheet: Bool = false
    @State private var selectedCommuteForDetail: FavouriteCommute?

    public init(storage: CommuteStorage = CommuteStorage.shared) {
        self.storage = storage
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if storage.commutes.isEmpty {
                        ContentUnavailableView(
                            "No Favourites",
                            systemImage: "star.slash",
                            description: Text("Tap the + button above to add your favorite commutes.")
                        )
                        .padding(.top, 60)
                    } else {
                        ForEach(storage.commutes) { commute in
                            CommuteRowCard(
                                commute: commute,
                                onSelect: { selectedCommuteForDetail = commute }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = storage.commutes.firstIndex(where: { $0.id == commute.id }) {
                                        storage.deleteCommute(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Favourites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCommuteView(storage: storage)
            }
            .sheet(item: $selectedCommuteForDetail) { commute in
                NavigationStack {
                    SingleCommuteDetailSheet(commute: commute)
                }
            }
        }
    }
}

struct CommuteRowCard: View {
    var commute: FavouriteCommute
    var onSelect: () -> Void

    var body: some View {
        let destinationText = commute.destinationFilter ?? commute.directionFilters?.joined(separator: ", ") ?? commute.directionFilter ?? "Any"
        let lineColor = TfLLine(id: commute.lineId, name: commute.lineName, modeName: commute.mode.rawValue).lineColor

        Button(action: onSelect) {
            ZStack(alignment: .trailing) {
                // Main card content background
                Color(.secondarySystemBackground)

                // Vertically oriented line name placed gracefully inside the card on the right
                HStack(spacing: 4) {
                    Spacer()

                    Text(commute.lineName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 20)
                        .padding(.trailing, 2)
                }

                // Card details layout
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TransportModeRoundel(mode: commute.mode)
                            .scaleEffect(0.7)
                            .frame(width: 28, height: 28)

                        Text(commute.originStationName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer(minLength: 50)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Toward: \(destinationText)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 34)
                }
                .padding(14)
                .padding(.trailing, 28) // Make room for the vertical line name

                // Right-edge integrated color accent strip sharing the card's outer rounded corners perfectly
                HStack {
                    Spacer()
                    lineColor
                        .frame(width: 6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct SingleCommuteDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var commute: FavouriteCommute
    @State private var predictions: [ArrivalPrediction] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 16) {
            DotMatrixBoardView(
                commuteTitle: commute.title,
                platformName: "",
                predictions: predictions,
                theme: commute.theme,
                maxRows: 4,
                showHeader: true,
                showStatusTicker: true,
                showBezel: true,
                statusText: isLoading ? "CONNECTING TO TFL..." : "GOOD SERVICE",
                fontSize: 13
            )
            .frame(minHeight: 220)
            .padding()

            Button {
                AudioAnnouncer.shared.announceBoard(station: commute.originStationName, predictions: predictions)
            } label: {
                Label("Platform Announcement", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle(commute.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            predictions = await TfLService.shared.fetchArrivals(for: commute)
            isLoading = false
        }
    }
}
