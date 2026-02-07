import SwiftUI

struct AngleDisplayView: View {
    let angle: Double
    let label: String
    let color: Color
    let isLarge: Bool

    init(angle: Double, label: String = "", color: Color = .white, isLarge: Bool = false) {
        self.angle = angle
        self.label = label
        self.color = color
        self.isLarge = isLarge
    }

    private var formattedAngle: String {
        String(format: "%.1f", abs(angle))
    }

    var body: some View {
        VStack(spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedAngle)
                    .font(.system(size: isLarge ? 72 : 40, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .contentTransition(.numericText())

                Text("\u{00B0}")
                    .font(.system(size: isLarge ? 36 : 22, weight: .thin, design: .rounded))
                    .foregroundStyle(color.opacity(0.8))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            AngleDisplayView(angle: 3.45, label: "Pitch", color: .white, isLarge: true)
            AngleDisplayView(angle: 1.23, label: "Roll", color: .green)
        }
    }
}
