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
        VStack(spacing: 16) {
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
                            selectedTheme = theme
                        }
                        .id(theme)
                    }
                }
                .padding(.horizontal, 28)
            }
            .frame(height: 230)
            .listRowInsets(EdgeInsets())

            // Confirm Button
            Button {
                var updated = commute
                updated.theme = selectedTheme
                storage.updateCommute(updated)
            } label: {
                Text(commute.theme == selectedTheme ? "Selected Theme" : "Confirm Theme Selection")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(commute.theme == selectedTheme ? Color.secondary.opacity(0.2) : commute.theme.ledColor)
                    .foregroundStyle(commute.theme == selectedTheme ? Color.primary : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(commute.theme == selectedTheme)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
        .onChange(of: commute.theme) { newTheme in
            selectedTheme = newTheme
        }
    }
}

private struct AccountView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var showingSettings = false

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
                    Section("Themes") {
                        ThemeCarouselView(commute: primaryCommute, storage: storage)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
