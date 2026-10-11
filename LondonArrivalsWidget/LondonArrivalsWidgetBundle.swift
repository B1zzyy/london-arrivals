import WidgetKit
import SwiftUI

@main
struct LondonArrivalsWidgetBundle: WidgetBundle {
    init() {
        NSLog("[LA-DIAG][WidgetBundle] extension launched bundle=%@", Bundle.main.bundleIdentifier ?? "unknown")
    }

    var body: some Widget {
        let _ = NSLog("[LA-DIAG][WidgetBundle] building widget configuration")
        LondonArrivalsWidget()
    }
}
