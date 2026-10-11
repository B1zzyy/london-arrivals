import SwiftUI

@main
struct LondonArrivalsApp: App {
    init() {
        #if LA_WIDGET_FLOW_TEST
        if ProcessInfo.processInfo.arguments.contains("--run-widget-flow-probe") {
            do {
                try CommuteWidgetFlowProbe.run()
                NSLog("[LA-DIAG][FlowProbe] PASS: app saved commute read by independent widget storage and provider selection")
            } catch {
                NSLog("[LA-DIAG][FlowProbe] FAIL: %@", String(describing: error))
                fatalError("Widget flow probe failed: \\(error)")
            }
        }
        #endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
