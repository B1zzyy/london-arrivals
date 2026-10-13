import SwiftUI

public struct ContentView: View {
    @StateObject private var storage = CommuteStorage.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            LiveBoardDetailView(storage: storage)
                .tabItem {
                    Label("Live Board", systemImage: "tram.fill")
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

private struct ThemeCarouselView: View {
    var commute: FavouriteCommute
    @ObservedObject var storage: CommuteStorage
    @State private var selectedTheme: BoardTheme

    init(commute: FavouriteCommute, storage: CommuteStorage) {
        self.commute = commute
        self.storage = storage
        _selectedTheme = State(initialValue: commute.theme)
    }

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(BoardTheme.allCases) { theme in
                        VStack(alignment: .leading, spacing: 8) {
                            // Live DotMatrix Board Preview
                            DotMatrixBoardView(
                                commuteTitle: "Kings Cross (Victoria)",
                                platformName: "1",
                                predictions: [
                                    ArrivalPrediction(id: "1", lineId: "victoria", lineName: "Victoria", destinationName: "Brixton", platformName: "Platform 1", stationName: "Kings Cross", timeToStation: 120),
                                    ArrivalPrediction(id: "2", lineId: "victoria", lineName: "Victoria", destinationName: "Brixton", platformName: "Platform 1", stationName: "Kings Cross", timeToStation: 300),
                                    ArrivalPrediction(id: "3", lineId: "victoria", lineName: "Victoria", destinationName: "Brixton", platformName: "Platform 1", stationName: "Kings Cross", timeToStation: 540)
                                ],
                                theme: theme,
                                maxRows: 3,
                                showHeader: true,
                                showStatusTicker: true,
                                showBezel: true,
                                statusText: "GOOD SERVICE",
                                fontSize: 12
                            )
                            .drawingGroup()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(3)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(selectedTheme == theme ? theme.ledColor : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                            // Theme Info
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(theme.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(width: 310)
                        .onTapGesture {
                            if selectedTheme != theme {
                                selectedTheme = theme
                                var updated = commute
                                updated.theme = theme
                                storage.updateCommute(updated)
                            }
                        }
                        .id(theme)
                    }
                }
                .padding(.horizontal, 28)
            }
            .frame(height: 230)
        }
        .padding(.vertical, 12)
        .listRowInsets(EdgeInsets(top: 0, leading: -16, bottom: 0, trailing: -16))
        .listRowBackground(Color(.secondarySystemGroupedBackground))
        .onChange(of: commute.theme) { newTheme in
            selectedTheme = newTheme
        }
    }
}

private struct AccountView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var showingSettings = false
    @State private var themesExpanded = true
    @State private var settingsExpanded = false

    var body: some View {
        NavigationStack {
            List {
                if storage.commutes.isEmpty {
                    ContentUnavailableView(
                        "No boards yet",
                        systemImage: "tram.fill",
                        description: Text("Add a board from the Live Board tab to customize its theme.")
                    )
                } else if let primaryCommute = storage.primaryCommute {
                    Section {
                        DisclosureGroup(isExpanded: $themesExpanded) {
                            ThemeCarouselView(commute: primaryCommute, storage: storage)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        } label: {
                            Label {
                                Text("Themes")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "paintpalette")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $settingsExpanded) {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("App Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Label {
                            Text("Settings")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
