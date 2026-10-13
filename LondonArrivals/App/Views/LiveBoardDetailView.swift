import SwiftUI

public struct LiveBoardDetailView: View {
    @ObservedObject var storage: CommuteStorage
    @State private var selectedCommuteId: UUID?
    @State private var predictions: [ArrivalPrediction] = []
    @State private var isLoading: Bool = false
    @State private var lastUpdated: Date?
    @State private var lineStatusText: String?
    @State private var selectedTheme: BoardTheme = .undergroundAmber
    @State private var showBezel: Bool = true
    @State private var autoRefreshTimer: Timer?
    @State private var arrivalRequestInFlight = false
    @State private var arrivalRequestId = UUID()

    public init(storage: CommuteStorage = CommuteStorage.shared) {
        self.storage = storage
    }

    private var currentCommute: FavouriteCommute? {
        if let id = selectedCommuteId, let match = storage.commutes.first(where: { $0.id == id }) {
            return match
        }
        return storage.primaryCommute
    }
    
    private var currentCommuteId: UUID? {
        currentCommute?.id
    }
    
    private var currentStationName: String {
        currentCommute?.originStationName ?? "Select a commute"
    }
    
    private var currentTheme: BoardTheme {
        currentCommute?.theme ?? .undergroundAmber
    }
    
    private var currentLineName: String {
        currentCommute?.lineName ?? ""
    }
    
    private var currentPlatformFilter: String? {
        currentCommute?.platformFilter
    }
    
    private var currentDestinationFilter: String? {
        currentCommute?.destinationFilter
    }
    
    private var boardTitle: String {
        "\(currentStationName) - \(currentLineName)"
    }
    
    private var boardPlatform: String {
        ""
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if storage.commutes.count > 1 {
                        TabView(selection: $selectedCommuteId) {
                            ForEach(storage.commutes) { commute in
                                DotMatrixBoardView(
                                    commuteTitle: "\(commute.originStationName) - \(commute.lineName)",
                                    platformName: "",
                                    predictions: commute.id == currentCommuteId ? predictions : [],
                                    theme: commute.theme,
                                    maxRows: 4,
                                    showHeader: true,
                                    showStatusTicker: true,
                                    showBezel: showBezel,
                                    statusText: lineStatusText,
                                    statusInHeader: true,
                                    fontSize: 14
                                )
                                .frame(minHeight: 220)
                                .padding(.horizontal)
                                .tag(Optional(commute.id))
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 270)

                        HStack(spacing: 7) {
                            ForEach(storage.commutes) { commute in
                                Circle()
                                    .fill(commute.id == currentCommuteId ? currentTheme.ledColor : Color.secondary.opacity(0.35))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .accessibilityLabel("Board \((storage.commutes.firstIndex(where: { $0.id == currentCommuteId }) ?? 0) + 1) of \(storage.commutes.count)")
                        .onChange(of: selectedCommuteId) { _, _ in
                            selectedTheme = currentTheme
                            lineStatusText = nil
                            predictions = currentCommute.map { ArrivalCache.load(for: $0) } ?? []
                            lastUpdated = nil
                            arrivalRequestId = UUID()
                            arrivalRequestInFlight = false
                            loadArrivals()
                            loadLineStatus()
                        }
                    } else {
                        DotMatrixBoardView(
                            commuteTitle: boardTitle,
                            platformName: boardPlatform,
                            predictions: predictions,
                            theme: selectedTheme,
                            maxRows: 4,
                            showHeader: true,
                            showStatusTicker: true,
                            showBezel: showBezel,
                            statusText: lineStatusText,
                            statusInHeader: true,
                            fontSize: 14
                        )
                        .frame(minHeight: 220)
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(currentStationName, systemImage: "mappin.and.ellipse")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let updated = lastUpdated {
                                Text("Updated \(timeAgo(updated))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            // Announce Station Chime Button
                            Button {
                                AudioAnnouncer.shared.announceBoard(
                                    station: currentStationName,
                                    predictions: predictions
                                )
                            } label: {
                                Label("Platform Chime", systemImage: "speaker.wave.3.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Spacer()

                            // Manual Refresh
                            Button {
                                loadArrivals()
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedTheme.ledColor.opacity(0.15))
                                    .foregroundColor(selectedTheme.ledColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal)
                    }

                }
                .padding(.vertical)
            }
            .navigationTitle("London Arrivals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        loadArrivals()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                selectedCommuteId = storage.primaryCommuteId ?? storage.commutes.first?.id
                selectedTheme = currentTheme
                predictions = currentCommute.map { ArrivalCache.load(for: $0) } ?? []
                loadArrivals()
                loadLineStatus()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private func loadLineStatus() {
        guard let commute = currentCommute else {
            lineStatusText = nil
            return
        }

        Task {
            let statuses = await TfLService.shared.fetchLineStatuses()
            let selectedLine = statuses.first { $0.id.caseInsensitiveCompare(commute.lineId) == .orderedSame }
            let value = selectedLine?.statusSeverityDescription
            await MainActor.run {
                self.lineStatusText = value?.isEmpty == false ? value : nil
            }
        }
    }

    private func loadArrivals() {
        guard let commute = currentCommute else {
            predictions = []
            isLoading = false
            return
        }
        guard !arrivalRequestInFlight else { return }

        let requestId = UUID()
        arrivalRequestId = requestId
        arrivalRequestInFlight = true
        isLoading = true
        Task {
            let results = await TfLService.shared.fetchArrivals(for: commute)
            await MainActor.run {
                guard self.arrivalRequestId == requestId,
                      self.currentCommute?.id == commute.id else { return }
                if !results.isEmpty {
                    self.predictions = results
                    ArrivalCache.save(results, for: commute)
                    self.lastUpdated = Date()
                } else if self.predictions.isEmpty {
                    // Avoid presenting expired cached trains as live; a later refresh retries.
                    self.predictions = ArrivalCache.load(for: commute)
                }
                self.arrivalRequestInFlight = false
                self.isLoading = false
            }
        }
    }

    private func startTimer() {
        stopTimer()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            loadArrivals()
        }
    }

    private func stopTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "just now" }
        return "\(seconds)s ago"
    }

    private func timeFormat(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
