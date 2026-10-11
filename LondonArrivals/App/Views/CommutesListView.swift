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
                Section(header: Text("Active Widget Commute")) {
                    if let primary = storage.commutes.first(where: { $0.id == storage.primaryCommuteId }) ?? storage.commutes.first {
                        CommuteRowCard(
                            commute: primary,
                            isPrimary: true,
                            onSetPrimary: { storage.setPrimaryCommute(id: primary.id) },
                            onSelect: { selectedCommuteForDetail = primary }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                }

                Section(header: Text("All Saved Commutes (\(storage.commutes.count))")) {
                    ForEach(storage.commutes) { commute in
                        CommuteRowCard(
                            commute: commute,
                            isPrimary: commute.id == storage.primaryCommuteId,
                            onSetPrimary: { storage.setPrimaryCommute(id: commute.id) },
                            onSelect: { selectedCommuteForDetail = commute }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                    .onDelete { offsets in
                        storage.deleteCommute(at: offsets)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My London Commutes")
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
    var isPrimary: Bool
    var onSetPrimary: () -> Void
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(commute.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Image(systemName: commute.mode.iconName)
                                .font(.caption2)
                            Text("\(commute.originStationName) → \(commute.destinationFilter ?? "Any")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        onSetPrimary()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isPrimary ? "star.fill" : "star")
                                .font(.caption)
                            Text(isPrimary ? "Widget" : "Set Widget")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isPrimary ? commute.theme.ledColor.opacity(0.2) : Color(.systemGray5))
                        .foregroundColor(isPrimary ? commute.theme.ledColor : .secondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    // Line pill
                    Text(commute.lineName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())

                    // Platform pill
                    if let plat = commute.platformFilter {
                        Text(plat)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Theme dot
                    HStack(spacing: 4) {
                        Circle()
                            .fill(commute.theme.ledColor)
                            .frame(width: 8, height: 8)
                        Text(commute.theme.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
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
