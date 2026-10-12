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

        Button(action: onSelect) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TransportModeRoundel(mode: commute.mode)
                            .scaleEffect(0.7)
                            .frame(width: 28, height: 28)

                        Text(commute.originStationName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()
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

                Spacer(minLength: 8)

                // Vertical accent strip with vertically oriented line name touching the accent color using official line color
                HStack(spacing: -12) {
                    Text(commute.lineName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 20)

                    TfLLine(id: commute.lineId, name: commute.lineName, modeName: commute.mode.rawValue)
                        .lineColor
                        .frame(width: 5)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 14, topTrailingRadius: 14))
                }
            }
            .background(Color(.secondarySystemBackground))
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
