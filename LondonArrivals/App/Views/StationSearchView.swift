import SwiftUI

public struct StationSearchView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var searchText: String = ""
    @State private var stations: [TfLStopPoint] = TfLStopPoint.popularLondonStations
    @State private var isSearching: Bool = false
    @State private var selectedStation: TfLStopPoint?
    @State private var stationArrivals: [ArrivalPrediction] = []
    @State private var isLoadingArrivals: Bool = false

    public init(storage: CommuteStorage = CommuteStorage.shared) {
        self.storage = storage
    }

    public var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView("Searching London stations...")
                        Spacer()
                    }
                } else {
                    Section(header: Text(searchText.isEmpty ? "Popular London Stations" : "Matching Stations")) {
                        ForEach(stations) { station in
                            Button {
                                loadStationArrivals(station: station)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(station.cleanName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        HStack(spacing: 6) {
                                            ForEach(station.modes, id: \.self) { mode in
                                                Text(mode.capitalized)
                                                    .font(.system(size: 10))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color(.systemGray5))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search e.g. Moorgate, Finsbury Park")
            .onChange(of: searchText) { _, newText in
                performSearch(query: newText)
            }
            .navigationTitle("Station Explorer")
            .sheet(item: $selectedStation) { station in
                NavigationStack {
                    VStack(spacing: 16) {
                        if isLoadingArrivals {
                            ProgressView("Fetching live arrivals...")
                                .padding()
                        } else {
                            DotMatrixBoardView(
                                commuteTitle: "\(station.cleanName) Live Board",
                                platformName: "ALL PLATFORMS",
                                predictions: stationArrivals,
                                theme: .undergroundAmber,
                                maxRows: 5,
                                showHeader: true,
                                showStatusTicker: true,
                                showBezel: true,
                                statusText: stationArrivals.isEmpty ? "NO ACTIVE ARRIVALS" : "GOOD SERVICE",
                                fontSize: 13
                            )
                            .frame(minHeight: 250)
                            .padding()

                            Button {
                                addQuickCommute(station: station)
                            } label: {
                                Label("Save as Favourite Commute", systemImage: "star.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .navigationTitle(station.cleanName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedStation = nil }
                        }
                    }
                }
            }
        }
    }

    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            stations = TfLStopPoint.popularLondonStations
            return
        }
        isSearching = true
        Task {
            let results = await TfLService.shared.searchStations(query: query)
            await MainActor.run {
                self.stations = results
                self.isSearching = false
            }
        }
    }

    private func loadStationArrivals(station: TfLStopPoint) {
        selectedStation = station
        isLoadingArrivals = true
        Task {
            let arrivals = await TfLService.shared.fetchArrivalsForStopPoint(stopPointId: station.id)
            await MainActor.run {
                self.stationArrivals = arrivals
                self.isLoadingArrivals = false
            }
        }
    }

    private func addQuickCommute(station: TfLStopPoint) {
        let firstArrival = stationArrivals.first
        let lineId = firstArrival?.lineId ?? "great-northern"
        let lineName = firstArrival?.lineName ?? "Great Northern"
        let dest = firstArrival?.cleanDestination ?? "Moorgate"

        let newCommute = FavouriteCommute(
            title: "\(lineName) from \(station.cleanName)",
            mode: .tube,
            lineId: lineId,
            lineName: lineName,
            originStationId: station.id,
            originStationName: station.cleanName,
            destinationFilter: dest,
            platformFilter: firstArrival?.cleanPlatform ?? "Platform 1",
            theme: .undergroundAmber
        )
        storage.addCommute(newCommute)
        selectedStation = nil
    }
}
