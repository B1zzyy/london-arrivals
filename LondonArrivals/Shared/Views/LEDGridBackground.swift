import SwiftUI

/// Draws an authentic LED dot-matrix grid surface where unlit circular pixels are subtly visible
public struct LEDGridBackground: View {
    public var dotColor: Color
    public var spacing: CGFloat = 6.0
    public var dotSize: CGFloat = 1.8

    public init(dotColor: Color, spacing: CGFloat = 6.0, dotSize: CGFloat = 1.8) {
        self.dotColor = dotColor
        self.spacing = spacing
        self.dotSize = dotSize
    }

    public var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1

            for col in 0..<cols {
                for row in 0..<rows {
                    let x = CGFloat(col) * spacing + (spacing / 2)
                    let y = CGFloat(row) * spacing + (spacing / 2)
                    let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
