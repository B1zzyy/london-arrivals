import SwiftUI

public struct ContentView: View {
    @StateObject private var storage = CommuteStorage.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            LiveBoardDetailView(storage: storage)
                .tabItem {
                    Label("Live Board", systemImage: "rectangle.and.waveform")
                }
                .tag(0)

            CommutesListView(storage: storage)
                .tabItem {
                    Label("Favourites", systemImage: "bookmark.fill")
                }
                .tag(1)

            AccountView(storage: storage)
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .tint(storage.primaryCommute?.theme.ledColor ?? .orange)
    }
}

private struct AccountView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var selectedCommuteId: UUID?
    @State private var showingSettings = false

    private var selectedCommute: FavouriteCommute? {
        guard let selectedCommuteId else { return nil }
        return storage.commutes.first { $0.id == selectedCommuteId }
    }

    var body: some View {
        NavigationStack {
            List {
                if storage.commutes.isEmpty {
                    ContentUnavailableView(
                        "No boards yet",
                        systemImage: "rectangle.and.waveform",
                        description: Text("Add a board from the Live Board tab to customize its theme.")
                    )
                } else {
                    Section("Choose a board") {
                        ForEach(storage.commutes) { commute in
                            Button {
                                selectedCommuteId = commute.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(commute.originStationName)
                                            .foregroundStyle(.primary)
                                        Text("\(commute.lineName) · \((commute.directionFilters ?? commute.directionFilter.map { [$0] } ?? []).joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if selectedCommuteId == commute.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(commute.theme.ledColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let commute = selectedCommute {
                        Section("Themes") {
                            ForEach(BoardTheme.allCases) { theme in
                                Button {
                                    var updated = commute
                                    updated.theme = theme
                                    storage.updateCommute(updated)
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(theme.ledColor)
                                            .frame(width: 14, height: 14)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.displayName)
                                                .foregroundStyle(.primary)
                                            Text(theme.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if commute.theme == theme {
                                            Image(systemName: "checkmark")
                                                .fontWeight(.semibold)
                                                .foregroundStyle(theme.ledColor)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("App Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Account")
            .onAppear {
                if selectedCommuteId == nil {
                    selectedCommuteId = storage.primaryCommuteId ?? storage.commutes.first?.id
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
