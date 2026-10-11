import SwiftUI

public struct AddCommuteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storage: CommuteStorage

    @State private var originStation: TfLStopPoint = TfLStopPoint.popularLondonStations[0]
    @State private var selectedMode: TransportMode = .tube
    @State private var selectedLine: TfLLine = TfLLine.curatedLondonLines[1]
    @State private var selectedDirections: Set<String> = []
    @State private var availableDirections: [String] = []
    @State private var selectedTheme: BoardTheme = .undergroundAmber
    @State private var stationSearchText: String = ""
    @State private var searchResults: [TfLStopPoint] = []
    @State private var isSearchingStations = false
    @State private var isLoadingOptions = false
    @State private var showStationPicker = false

    public init(storage: CommuteStorage = CommuteStorage.shared) {
        self.storage = storage
    }

    private var filteredLines: [TfLLine] {
        let stationLines = Set(originStation.lines.map { $0.lowercased() })
        let atStation = TfLLine.curatedLondonLines.filter { stationLines.contains($0.id.lowercased()) }
        let byMode = TfLLine.curatedLondonLines.filter { $0.modeName == selectedMode.rawValue }
        return atStation.isEmpty ? byMode : atStation.filter { $0.modeName == selectedMode.rawValue }
    }

    private var previewCommute: FavouriteCommute {
        FavouriteCommute(
            title: commuteTitle,
            mode: selectedMode,
            lineId: selectedLine.id,
            lineName: selectedLine.name,
            originStationId: originStation.id,
            originStationName: originStation.cleanName,
            destinationFilter: nil,
            directionFilter: selectedDirections.sorted().first,
            directionFilters: selectedDirections.sorted(),
            theme: selectedTheme
        )
    }

    private var commuteTitle: String {
        let directions = selectedDirections.sorted()
        let direction = directions.isEmpty ? "Select direction" : directions.joined(separator: " / ")
        return "\(originStation.cleanName) · \(selectedLine.name) · \(direction)"
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("1. Choose station") {
                    Button { showStationPicker = true } label: {
                        HStack {
                            Text("Station")
                            Spacer()
                            Text(originStation.cleanName).foregroundStyle(.secondary)
                        }
                    }

                }

                Section("2. Choose transport and line") {
                    Picker("Transport", selection: $selectedMode) {
                        ForEach(TransportMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .onChange(of: selectedMode) { _, _ in
                        updateLineSelection()
                    }

                    Picker("Line", selection: $selectedLine) {
                        ForEach(filteredLines) { line in
                            Text(line.name).tag(line)
                        }
                    }
                    .onChange(of: selectedLine) { _, _ in
                        loadDirections()
                    }

                }

                Section("3. Choose directions") {
                    if isLoadingOptions {
                        ProgressView("Loading directions…")
                    } else if availableDirections.isEmpty {
                        Text("No live directions are currently available for this line at this station.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableDirections, id: \.self) { direction in
                            Button {
                                if selectedDirections.contains(direction) {
                                    selectedDirections.remove(direction)
                                } else {
                                    selectedDirections.insert(direction)
                                }
                            } label: {
                                HStack {
                                    Text(direction).foregroundStyle(.primary)
                                    Spacer()
                                    if selectedDirections.contains(direction) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                                    } else {
                                        Image(systemName: "circle").foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Board appearance") {
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(BoardTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    DotMatrixBoardView(
                        commuteTitle: previewCommute.title,
                        platformName: "",
                        predictions: [],
                        theme: selectedTheme,
                        maxRows: 3,
                        showHeader: true,
                        showStatusTicker: true,
                        showBezel: true,
                        fontSize: 12
                    )
                    .frame(minHeight: 160)
                }
            }
            .navigationTitle("Add Arrivals Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCommute()
                        dismiss()
                    }
                    .disabled(filteredLines.isEmpty || selectedDirections.isEmpty || isLoadingOptions)
                }
            }
            .sheet(isPresented: $showStationPicker) {
                NavigationStack {
                    List {
                        if isSearchingStations {
                            HStack { Spacer(); ProgressView("Searching stations…"); Spacer() }
                        } else {
                            ForEach(searchResults.isEmpty ? TfLStopPoint.popularLondonStations : searchResults) { station in
                                Button {
                                    originStation = station
                                    showStationPicker = false
                                    updateLineSelection()
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(station.cleanName).foregroundStyle(.primary)
                                        Text(station.modes.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $stationSearchText, prompt: "Search a TfL station")
                    .onChange(of: stationSearchText) { _, query in performStationSearch(query: query) }
                    .navigationTitle("Select Station")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showStationPicker = false }
                        }
                    }
                }
            }
            .onAppear { updateLineSelection() }
        }
    }

    private func updateLineSelection() {
        if !filteredLines.contains(selectedLine), let first = filteredLines.first {
            selectedLine = first
        }
        loadDirections()
    }

    private func loadDirections() {
        selectedDirections = []
        availableDirections = []
        guard !originStation.id.isEmpty, !selectedLine.id.isEmpty else { return }
        isLoadingOptions = true
        Task {
            let arrivals = await TfLService.shared.fetchArrivalsForStopPoint(stopPointId: originStation.id, lineId: selectedLine.id)
            let options = Set(arrivals.compactMap { prediction -> String? in
                let direction = prediction.towards?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return direction.isEmpty ? nil : direction
            }).sorted()
            await MainActor.run {
                availableDirections = options
                selectedDirections = Set(selectedDirections.intersection(options))
                if selectedDirections.isEmpty, let first = options.first { selectedDirections.insert(first) }
                isLoadingOptions = false
            }
        }
    }

    private func performStationSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        isSearchingStations = true
        Task {
            let results = await TfLService.shared.searchStations(query: query)
            await MainActor.run {
                searchResults = results
                isSearchingStations = false
            }
        }
    }

    private func saveCommute() {
        let commute = FavouriteCommute(
            title: commuteTitle,
            mode: selectedMode,
            lineId: selectedLine.id,
            lineName: selectedLine.name,
            originStationId: originStation.id,
            originStationName: originStation.cleanName,
            destinationFilter: nil,
            directionFilter: selectedDirections.sorted().first,
            directionFilters: selectedDirections.sorted(),
            theme: selectedTheme,
            isPrimaryWidget: storage.commutes.isEmpty
        )
        storage.addCommute(commute)
    }
}
