import SwiftUI

struct SurfaceLevelView: View {
    @ObservedObject var viewModel: LevelViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            if isLandscape || isIPad {
                landscapeLayout(geometry: geometry)
            } else {
                portraitLayout(geometry: geometry)
            }
        }
    }

    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top half - Pitch
            AxisLevelStrip(
                angle: viewModel.pitch,
                color: viewModel.levelColor,
                axis: .vertical,
                isLevel: abs(viewModel.pitch) < 0.5
            )
            .frame(height: geometry.size.height / 2)

            Divider()
                .background(Color.white.opacity(0.2))

            // Bottom half - Roll
            AxisLevelStrip(
                angle: viewModel.roll,
                color: viewModel.levelColor,
                axis: .horizontal,
                isLevel: abs(viewModel.roll) < 0.5
            )
            .frame(height: geometry.size.height / 2)
        }
    }

    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left half - Roll
            AxisLevelStrip(
                angle: viewModel.roll,
                color: viewModel.levelColor,
                axis: .horizontal,
                isLevel: abs(viewModel.roll) < 0.5
            )
            .frame(width: geometry.size.width / 2)

            Divider()
                .background(Color.white.opacity(0.2))

            // Right half - Pitch
            AxisLevelStrip(
                angle: viewModel.pitch,
                color: viewModel.levelColor,
                axis: .vertical,
                isLevel: abs(viewModel.pitch) < 0.5
            )
            .frame(width: geometry.size.width / 2)
        }
    }
}

struct AxisLevelStrip: View {
    let angle: Double
    let color: Color
    let axis: Axis
    let isLevel: Bool

    enum Axis {
        case horizontal, vertical
    }

    private var indicatorOffset: CGFloat {
        let clamped = max(-45, min(45, angle))
        return CGFloat(clamped / 45.0) * 100
    }

    private var stripColor: Color {
        isLevel ? .green : color
    }

    private var backgroundColor: Color {
        isLevel ? Color.green.opacity(0.08) : Color.clear
    }

    var body: some View {
        ZStack {
            backgroundColor
                .animation(.easeInOut(duration: 0.3), value: isLevel)

            VStack(spacing: 24) {
                AngleDisplayView(
                    angle: angle,
                    label: axis == .horizontal ? "Roll" : "Pitch",
                    color: stripColor,
                    isLarge: true
                )

                // Level bar indicator
                ZStack {
                    if axis == .horizontal {
                        horizontalIndicator
                    } else {
                        verticalIndicator
                    }
                }
                .frame(width: axis == .horizontal ? 280 : 60,
                       height: axis == .horizontal ? 60 : 280)
            }
        }
    }

    private var horizontalIndicator: some View {
        ZStack {
            // Track
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.06))
                .frame(width: 280, height: 52)

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
            .frame(width: 260)

            // Center marker
            RoundedRectangle(cornerRadius: 2)
                .fill(stripColor.opacity(0.6))
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
                .frame(width: 52, height: 280)

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
            .frame(height: 260)

            // Center marker
            RoundedRectangle(cornerRadius: 2)
                .fill(stripColor.opacity(0.6))
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
