import SwiftUI

public struct DotMatrixText: View {
    public var text: String
    public var size: CGFloat
    public var weight: Font.Weight
    public var theme: BoardTheme
    public var tracking: CGFloat
    public var isGlowing: Bool

    public init(
        _ text: String,
        size: CGFloat = 14,
        weight: Font.Weight = .bold,
        theme: BoardTheme = .undergroundAmber,
        tracking: CGFloat = 1.0,
        isGlowing: Bool = true
    ) {
        self.text = text
        self.size = size
        self.weight = weight
        self.theme = theme
        self.tracking = tracking
        self.isGlowing = isGlowing
    }

    public var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .monospaced))
            .tracking(tracking)
            .foregroundColor(theme.ledColor)
            .shadow(color: isGlowing ? theme.glowColor : .clear, radius: 2, x: 0, y: 0)
            .shadow(color: isGlowing ? theme.glowColor.opacity(0.4) : .clear, radius: 4, x: 0, y: 0)
    }
}
