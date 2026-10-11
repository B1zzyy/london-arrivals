import SwiftUI

public struct BoardBezelView<Content: View>: View {
    public var theme: BoardTheme
    public var content: Content
    public var showScrews: Bool
    public var cornerRadius: CGFloat

    public init(
        theme: BoardTheme = .undergroundAmber,
        showScrews: Bool = true,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.showScrews = showScrews
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // Outer casing
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            theme.casingColor.opacity(0.95),
                            Color(red: 0.08, green: 0.09, blue: 0.10)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.04),
                                    Color.black.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 4)

            // Inner screen area
            VStack(spacing: 0) {
                content
            }
            .background(theme.screenBackground)
            .clipShape(RoundedRectangle(cornerRadius: max(4, cornerRadius - 6)))
            .overlay(
                RoundedRectangle(cornerRadius: max(4, cornerRadius - 6))
                    .stroke(theme.bezelBorderColor.opacity(0.6), lineWidth: 1)
            )
            .padding(showScrews ? 8 : 4)

            // Industrial Corner Screws
            if showScrews {
                VStack {
                    HStack {
                        ScrewView(color: theme.screwColor)
                        Spacer()
                        ScrewView(color: theme.screwColor)
                    }
                    Spacer()
                    HStack {
                        ScrewView(color: theme.screwColor)
                        Spacer()
                        ScrewView(color: theme.screwColor)
                    }
                }
                .padding(4)
                .allowsHitTesting(false)
            }
        }
    }
}

/// Miniature brushed metallic hardware screw with indentation
struct ScrewView: View {
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.85),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 6, height: 6)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )

            // Screw cross slot
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 4, height: 1)
        }
    }
}
