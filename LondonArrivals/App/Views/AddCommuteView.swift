import SwiftUI

public struct AddCommuteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storage: CommuteStorage

    @State private var originStation: TfLStopPoint = TfLStopPoint(id: "", commonName: "Choose a station")
    @State private var selectedMode: TransportMode = .tube
    @State private var selectedLine: TfLLine = TfLLine.curatedLondonLines[1]
    @State private var hasSelectedLine = true
    @State private var directionsRequestGeneration = 0
    @State private var selectedDirections: Set<String> = []
    @State private var availableDirections: [String] = []
    @State private var selectedTheme: BoardTheme = .undergroundAmber
    @State private var stationSearchText: String = ""
    @State private var searchResults: [TfLStopPoint] = []
    @State private var isSearchingStations = false
    @State private var remoteSearchResults: [TfLStopPoint] = []
    @State private var isLoadingOptions = false
    @State private var showStationPicker = false
    @State private var isSelectingStation = false
    @State private var stationSearchTask: Task<Void, Never>?
    @State private var stationSearchGeneration = 0

    public init(storage: CommuteStorage = CommuteStorage.shared) {
        self.storage = storage
    }

    private var stationsToDisplay: [TfLStopPoint] {
        let query = stationSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = query.isEmpty
            ? TfLStopPoint.allLondonStations
            : TfLStopPoint.allLondonStations.filter {
                $0.commonName.localizedStandardContains(query) || $0.cleanName.localizedStandardContains(query)
            } + remoteSearchResults.filter { remote in
                !TfLStopPoint.allLondonStations.contains { $0.id == remote.id }
            }
        return source.sorted {
            $0.cleanName.localizedCaseInsensitiveCompare($1.cleanName) == .orderedAscending
        }
    }

    private var stationsGroupedByInitial: [(letter: String, stations: [TfLStopPoint])] {
        let grouped = Dictionary(grouping: stationsToDisplay) { station in
            String(station.cleanName.prefix(1)).uppercased()
        }
        return grouped.keys.sorted().map { letter in
            (letter, grouped[letter] ?? [])
        }
    }

    private var availableModes: [TransportMode] {
        let stationModes = Set(originStation.modes.map { $0.lowercased() })
        return TransportMode.allCases.filter { stationModes.contains($0.rawValue.lowercased()) }
    }

    private var filteredLines: [TfLLine] {
        let stationLines = Set(originStation.lines.map { $0.lowercased() })
        // TfL returns the line itself as the only service on DLR and Elizabeth
        // stations; include that mode's canonical line even when stop-point
        // metadata omits lineGroups (common for interchange hubs).
        if selectedMode == .dlr, originStation.modes.contains(where: { $0.lowercased() == TransportMode.dlr.rawValue }) {
            return TfLLine.curatedLondonLines.filter { $0.id == "dlr" }
        }
        if selectedMode == .elizabethLine, originStation.modes.contains(where: { $0.lowercased() == TransportMode.elizabethLine.rawValue }) {
            return TfLLine.curatedLondonLines.filter { $0.id == "elizabeth" }
        }
        if selectedMode == .tube, originStation.id == "HUBBAN" {
            return TfLLine.curatedLondonLines.filter {
                ["central", "northern", "waterloo-city"].contains($0.id.lowercased())
            }
        }
        guard !stationLines.isEmpty else { return [] }
        return TfLLine.curatedLondonLines.filter {
            stationLines.contains($0.id.lowercased()) && $0.modeName == selectedMode.rawValue
        }
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
                        ForEach(availableModes) { mode in
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
                    .id("\(originStation.id)|\(selectedMode.rawValue)")
                    .disabled(filteredLines.isEmpty)
                    .onAppear {
                        NSLog("[LA-DIAG][AddCommute] line picker render station=%@ mode=%@ line=%@ choices=%@", originStation.id, selectedMode.rawValue, selectedLine.id, filteredLines.map(\.id).joined(separator: ","))
                    }
                    .onChange(of: selectedLine) { _, newLine in
                        guard filteredLines.contains(newLine), newLine.modeName == selectedMode.rawValue else {
                            NSLog("[LA-DIAG][AddCommute] picker selection ignored mode=%@ line=%@", selectedMode.rawValue, newLine.id)
                            return
                        }
                        loadDirections(for: newLine, station: originStation)
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
                    .disabled(filteredLines.isEmpty || !hasSelectedLine || selectedDirections.isEmpty || isLoadingOptions)
                }
            }
            .sheet(isPresented: $showStationPicker) {
                NavigationStack {
                    List {
                        ForEach(stationsGroupedByInitial, id: \.letter) { group in
                            Section(group.letter) {
                                ForEach(group.stations) { station in
                                    Button {
                                        guard !isSelectingStation else { return }
                                    NSLog("[LA-DIAG][AddCommute] station tap id=%@ name=%@", station.id, station.commonName)
                                    isSelectingStation = true
                                    Task { @MainActor in
                                        NSLog("[LA-DIAG][AddCommute] enrichment begin id=%@", station.id)
                                        let enrichedStation = await TfLService.shared.enrichStopPoint(station)
                                        NSLog("[LA-DIAG][AddCommute] enrichment end id=%@ modes=%@ lines=%@", enrichedStation.id, enrichedStation.modes.joined(separator: ","), enrichedStation.lines.joined(separator: ","))

                                        let modeForStation = TransportMode.allCases.first(where: { mode in
                                            enrichedStation.modes.contains { $0.lowercased() == mode.rawValue.lowercased() }
                                        })
                                        let modeID = modeForStation?.rawValue ?? selectedMode.rawValue
                                        let stationLineIDs = Set(enrichedStation.lines.map { $0.lowercased() })
                                        let matchingLines: [TfLLine]
                                        if modeID == TransportMode.dlr.rawValue, enrichedStation.modes.contains(where: { $0.lowercased() == modeID }) {
                                            matchingLines = TfLLine.curatedLondonLines.filter { $0.id == "dlr" }
                                        } else if modeID == TransportMode.elizabethLine.rawValue, enrichedStation.modes.contains(where: { $0.lowercased() == modeID }) {
                                            matchingLines = TfLLine.curatedLondonLines.filter { $0.id == "elizabeth" }
                                        } else {
                                            matchingLines = TfLLine.curatedLondonLines.filter {
                                                stationLineIDs.contains($0.id.lowercased()) && $0.modeName == modeID
                                            }
                                        }
                                        let firstLine = matchingLines.first
                                        NSLog("[LA-DIAG][AddCommute] first selection resolved id=%@ mode=%@ lineChoices=%@ selected=%@", enrichedStation.id, modeID, matchingLines.map(\.id).joined(separator: ","), firstLine?.id ?? "none")

                                        originStation = enrichedStation
                                        hasSelectedLine = firstLine != nil
                                        if let firstLine {
                                            selectedLine = firstLine
                                        }
                                        stationSearchText = ""
                                        searchResults = []
                                        selectedDirections = []
                                        availableDirections = []

                                        if let modeForStation {
                                            selectedMode = modeForStation
                                        }

                                        if let firstLine {
                                            NSLog("[LA-DIAG][AddCommute] selection committed station=%@ mode=%@ line=%@", enrichedStation.id, modeID, firstLine.id)
                                            loadDirections(for: firstLine, station: enrichedStation)
                                        } else {
                                            NSLog("[LA-DIAG][AddCommute] no curated line match station=%@ mode=%@ lineIDs=%@", enrichedStation.id, modeID, enrichedStation.lines.joined(separator: ","))
                                            updateLineSelection()
                                        }
                                        isSelectingStation = false
                                        showStationPicker = false
                                    }
                                    } label: {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(station.cleanName).foregroundStyle(.primary)
                                                Text(station.modes.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $stationSearchText, prompt: "Search a TfL station")
                    .onChange(of: stationSearchText) { _, query in scheduleStationSearch(query: query) }
                    .overlay {
                        if isSelectingStation {
                            ProgressView("Loading station…")
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .navigationTitle("Select Station")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showStationPicker = false }
                        }
                    }
                }
            }
            .onAppear { updateLineSelection() }
            .onChange(of: originStation) { _, newStation in
                NSLog("[LA-DIAG][AddCommute] originStation onChange id=%@", newStation.id)
            }
        }
    }

    private func updateLineSelection() {
        if let firstMode = availableModes.first, !availableModes.contains(selectedMode) {
            selectedMode = firstMode
        }
        guard let firstLine = filteredLines.first else {
            directionsRequestGeneration += 1
            hasSelectedLine = false
            NSLog("[LA-DIAG][AddCommute] no line options station=%@ mode=%@ stationLines=%@", originStation.id, selectedMode.rawValue, originStation.lines.joined(separator: ","))
            selectedDirections = []
            availableDirections = []
            isLoadingOptions = false
            return
        }

        let lineToSelect = filteredLines.contains(selectedLine) ? selectedLine : firstLine
        let selectionChanged = selectedLine != lineToSelect
        hasSelectedLine = true
        selectedDirections = []
        availableDirections = []
        isLoadingOptions = selectionChanged
        NSLog("[LA-DIAG][AddCommute] update selection station=%@ mode=%@ line=%@ changed=%@", originStation.id, selectedMode.rawValue, lineToSelect.id, selectionChanged ? "true" : "false")
        if selectionChanged {
            selectedLine = lineToSelect
        } else {
            loadDirections(for: lineToSelect, station: originStation)
        }
    }

    private func loadDirections() {
        loadDirections(for: selectedLine, station: originStation)
    }

    private func loadDirections(for line: TfLLine, station: TfLStopPoint) {
        selectedDirections = []
        availableDirections = []
        guard !station.id.isEmpty, !line.id.isEmpty else {
            NSLog("[LA-DIAG][AddCommute] directions skipped empty station/line")
            isLoadingOptions = false
            return
        }
        let requestedMode = selectedMode.rawValue
        guard filteredLines.contains(line), line.modeName == requestedMode else {
            NSLog("[LA-DIAG][AddCommute] directions skipped invalid picker tag mode=%@ line=%@", requestedMode, line.id)
            isLoadingOptions = false
            return
        }
        directionsRequestGeneration += 1
        let requestGeneration = directionsRequestGeneration
        isLoadingOptions = true
        NSLog("[LA-DIAG][AddCommute] directions request station=%@ mode=%@ line=%@ generation=%ld", station.id, requestedMode, line.id, requestGeneration)
        let requestID = "\(station.id)|\(requestedMode)|\(line.id)"
        Task { @MainActor in
            let arrivals = await TfLService.shared.fetchArrivalsForStopPoint(stopPointId: station.id, lineId: line.id)
            let options = Set(arrivals.compactMap { prediction -> String? in
                let towards = prediction.towards?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let destination = prediction.destinationName.trimmingCharacters(in: .whitespacesAndNewlines)
                let direction = towards.isEmpty ? destination : towards
                return direction.isEmpty ? nil : direction
            }).sorted()
            guard requestGeneration == directionsRequestGeneration,
                  originStation.id == station.id,
                  selectedLine.id == line.id,
                  selectedMode.rawValue == requestedMode else {
                NSLog("[LA-DIAG][AddCommute] stale directions ignored request=%@ currentStation=%@ currentLine=%@ currentMode=%@", requestID, originStation.id, selectedLine.id, selectedMode.rawValue)
                return
            }
            availableDirections = options
            selectedDirections = options.first.map { [$0] } ?? []
            isLoadingOptions = false
            NSLog("[LA-DIAG][AddCommute] directions complete station=%@ line=%@ arrivals=%ld options=%ld", station.id, line.id, arrivals.count, options.count)
        }
    }

    private func scheduleStationSearch(query: String) {
        stationSearchGeneration += 1
        let generation = stationSearchGeneration
        stationSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        remoteSearchResults = []
        guard !trimmed.isEmpty else {
            searchResults = []
            remoteSearchResults = []
            isSearchingStations = false
            return
        }
        remoteSearchResults = []
        let localMatches = TfLStopPoint.allLondonStations.filter {
            $0.commonName.localizedStandardContains(trimmed) || $0.cleanName.localizedStandardContains(trimmed)
        }
        guard localMatches.isEmpty else {
            isSearchingStations = false
            return
        }
        isSearchingStations = true
        stationSearchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, generation == stationSearchGeneration else { return }
            let results = await TfLService.shared.searchStations(query: trimmed)
            guard !Task.isCancelled, generation == stationSearchGeneration else { return }
            remoteSearchResults = results
            isSearchingStations = false
            NSLog("[LA-DIAG][AddCommute] search complete query=%@ resultCount=%ld", trimmed, results.count)
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
