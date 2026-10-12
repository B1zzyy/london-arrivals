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
            List {
                ForEach(storage.commutes) { commute in
                    CommuteRowCard(
                        commute: commute,
                        onSelect: { selectedCommuteForDetail = commute }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete { offsets in
                    storage.deleteCommute(at: offsets)
                }
            }
            .listStyle(.insetGrouped)
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TransportModeRoundel(mode: commute.mode)
                        .scaleEffect(0.7)
                        .frame(width: 28, height: 28)

                    Text(commute.originStationName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Line Badge
                    Text(commute.lineName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(commute.theme.ledColor.opacity(0.15))
                        .foregroundColor(commute.theme.ledColor)
                        .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Toward: \(destinationText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 26)
            }
            .padding(.vertical, 8)
        }
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
