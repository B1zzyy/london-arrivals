import SwiftUI

public struct LineStatusView: View {
    @State private var lines: [TfLLine] = []
    @State private var isLoading: Bool = true

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading London transport status...")
                        Spacer()
                    }
                } else {
                    ForEach(lines) { line in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(line.lineColor)
                                    .frame(width: 8, height: 24)

                                Text(line.name)
                                    .font(.headline)

                                Spacer()

                                StatusBadge(status: line.statusSeverityDescription ?? "Good Service")
                            }

                            if let reason = line.reason, !reason.isEmpty {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 14)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Network Status")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        loadStatus()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                loadStatus()
            }
        }
    }

    private func loadStatus() {
        isLoading = true
        Task {
            let fetched = await TfLService.shared.fetchLineStatuses()
            await MainActor.run {
                self.lines = fetched
                self.isLoading = false
            }
        }
    }
}

struct StatusBadge: View {
    var status: String

    var isGood: Bool {
        status.lowercased().contains("good")
    }

    var isSevere: Bool {
        status.lowercased().contains("severe") || status.lowercased().contains("closed")
    }

    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isGood ? Color.green.opacity(0.18) :
                isSevere ? Color.red.opacity(0.18) :
                Color.orange.opacity(0.18)
            )
            .foregroundColor(
                isGood ? Color.green :
                isSevere ? Color.red :
                Color.orange
            )
            .clipShape(Capsule())
    }
}
