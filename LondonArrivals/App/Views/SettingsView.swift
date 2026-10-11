import SwiftUI
import WidgetKit

public struct SettingsView: View {
    @AppStorage("tfl_app_key", store: UserDefaults(suiteName: "group.com.antigravity.londonarrivals"))
    private var appKey: String = ""

    @State private var showingTestAlert: Bool = false
    @State private var syncStatus: String = "Synchronized"

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Section: Widget Setup Guide
                Section(header: Text("iOS Widget Setup")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.dashed.inset.filled")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("London Arrivals on Home Screen")
                                .font(.headline)
                        }

                        Text("1. Long press any empty space on your iOS Home Screen.\n2. Tap the '+' button in the top corner.\n3. Search for 'London Arrivals' or 'Arrivals Board'.\n4. Choose Small, Medium (iconic 3-row London platform board), or Large.\n5. Tap 'Add Widget' to place your live arrivals board!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Button("Reload Widget Timelines") {
                        WidgetCenter.shared.reloadAllTimelines()
                        syncStatus = "Timelines reloaded!"
                    }
                }

                // Section: TfL API Configuration
                Section(header: Text("TfL Unified API"), footer: Text("The app works out of the box using public TfL Unified API endpoints. If you have a registered TfL Unified API app_key, you can optionally paste it here for higher rate limits.")) {
                    SecureField("TfL App Key (Optional)", text: $appKey)
                }

                // Section: Audio Platform Announcements
                Section(header: Text("Platform Announcements")) {
                    Button {
                        AudioAnnouncer.shared.speak(text: "The next train on platform 1 is the Great Northern service to Moorgate, arriving in 2 minutes.")
                    } label: {
                        Label("Test London Platform Voice", systemImage: "speaker.wave.3.fill")
                    }
                }

                // Section: Design Heritage
                Section(header: Text("Design Heritage")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("London Platform Indicator (DMI)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Recreated to match the iconic Dot Matrix Indicators (DMIs) found on the London Underground, Overground, and Network Rail platforms across Greater London.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
