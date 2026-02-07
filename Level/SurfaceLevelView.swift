import SwiftUI

struct SurfaceLevelView: View {
    @ObservedObject var viewModel: LevelViewModel
    var textRotationAngle: Angle = .degrees(0)

    var body: some View {
        GeometryReader { geometry in
            let dividerSpacing: CGFloat = 6
            let availableHeight = geometry.size.height - dividerSpacing
            let topHeight = availableHeight * 0.66
            let bottomHeight = availableHeight - topHeight

            VStack(spacing: 0) {
                // Top - Pitch
                AxisLevelStrip(
                    angle: viewModel.pitch,
                    color: viewModel.levelColor,
                    axis: .vertical,
                    isLevel: abs(viewModel.pitch) < 0.5,
                    textRotationAngle: textRotationAngle
                )
                .frame(height: topHeight)
                .padding(.bottom, 3)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Bottom - Roll
                AxisLevelStrip(
                    angle: viewModel.roll,
                    color: viewModel.levelColor,
                    axis: .horizontal,
                    isLevel: abs(viewModel.roll) < 0.5,
                    textRotationAngle: textRotationAngle
                )
                .frame(height: bottomHeight)
                .padding(.top, 3)
            }
        }
    }
}

struct AxisLevelStrip: View {
    let angle: Double
    let color: Color
    let axis: Axis
    let isLevel: Bool
    var isCompact: Bool = false
    var textRotationAngle: Angle = .degrees(0)

    enum Axis {
        case horizontal, vertical
    }

    private var trackLength: CGFloat {
        isCompact ? 180 : 280
    }

    private var indicatorOffset: CGFloat {
        let clamped = max(-45, min(45, angle))
        let maxOffset = isCompact ? 64 : 100
        return CGFloat(clamped / 45.0) * CGFloat(maxOffset)
    }

    private var stripColor: Color {
        isLevel ? .levelBright : color
    }

    private var labelText: String {
        axis == .horizontal ? "Roll" : "Pitch"
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: isCompact ? 16 : 24) {
                // Angle display with label aligned to the left
                HStack(alignment: .center) {
                    Text(labelText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .rotationEffect(textRotationAngle)
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    AngleDisplayView(
                        angle: angle,
                        label: "",
                        color: stripColor,
                        isLarge: !isCompact
                    )
                    .rotationEffect(textRotationAngle)
                    
                    Spacer()
                    
                    // Invisible spacer to balance the label
                    Text(labelText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .padding(.trailing, 20)
                        .hidden()
                }

                // Level bar indicator
                ZStack {
                    if axis == .horizontal {
                        horizontalIndicator
                    } else {
                        verticalIndicator
                    }
                }
                .frame(width: axis == .horizontal ? trackLength : 60,
                       height: axis == .horizontal ? 60 : trackLength)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var horizontalIndicator: some View {
        ZStack {
            // Track
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.06))
                .frame(width: trackLength, height: 52)

            // Tick marks
            HStack(spacing: 0) {
                ForEach(0..<29) { i in
                    if i > 0 {
                        Spacer()
                    }
                    Rectangle()
                        .fill(Color.white.opacity(i == 14 ? 0.4 : 0.1))
                        .frame(width: i == 14 ? 2 : 1, height: i == 14 ? 30 : 15)
                }
            }
            .frame(width: trackLength - 20)

            // Center marker
            RoundedRectangle(cornerRadius: 2)
                .fill((isLevel ? Color.levelBright : stripColor).opacity(0.8))
                .frame(width: 2, height: 40)

            // Indicator bubble
            Circle()
                .fill(
                    RadialGradient(
                        colors: [stripColor, stripColor.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: stripColor.opacity(0.4), radius: 8)
                .offset(x: indicatorOffset)
                .animation(
                    .interpolatingSpring(stiffness: 200, damping: 18),
                    value: indicatorOffset
                )
        }
    }

    private var verticalIndicator: some View {
        ZStack {
            // Track
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.06))
                .frame(width: 52, height: trackLength)

            // Tick marks
            VStack(spacing: 0) {
                ForEach(0..<29) { i in
                    if i > 0 {
                        Spacer()
                    }
                    Rectangle()
                        .fill(Color.white.opacity(i == 14 ? 0.4 : 0.1))
                        .frame(width: i == 14 ? 30 : 15, height: i == 14 ? 2 : 1)
                }
            }
            .frame(height: trackLength - 20)

            // Center marker
            RoundedRectangle(cornerRadius: 2)
                .fill((isLevel ? Color.levelBright : stripColor).opacity(0.8))
                .frame(width: 40, height: 2)

            // Indicator bubble
            Circle()
                .fill(
                    RadialGradient(
                        colors: [stripColor, stripColor.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: stripColor.opacity(0.4), radius: 8)
                .offset(y: -indicatorOffset)
                .animation(
                    .interpolatingSpring(stiffness: 200, damping: 18),
                    value: indicatorOffset
                )
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SurfaceLevelView(viewModel: LevelViewModel())
    }
}
