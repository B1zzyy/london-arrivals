import SwiftUI

/// Text-free TfL-inspired roundel used to identify a transport mode in the station list.
struct TransportModeRoundel: View {
    let mode: TransportMode

    var body: some View {
        ZStack {
            Circle()
                .stroke(mode.brandColor, lineWidth: 4)
                .frame(width: 24, height: 24)
            Rectangle()
                .fill(Color(red: 0.0, green: 0.18, blue: 0.46))
                .frame(width: 32, height: 8)
                .overlay {
                    Rectangle()
                        .strokeBorder(.white, lineWidth: 1)
                }
        }
        .frame(width: 36, height: 32)
        .accessibilityLabel(mode.displayName)
        .accessibilityAddTraits(.isImage)
    }
}
