import SwiftUI

struct BubbleLevelView: View {
    @ObservedObject var viewModel: LevelViewModel

    private let maxOffset: CGFloat = 120
    private let bubbleSize: CGFloat = 60
    private let ringSize: CGFloat = 180

    private var bubbleOffset: CGSize {
        let clampedRoll = max(-45, min(45, viewModel.roll))
        let clampedPitch = max(-45, min(45, viewModel.pitch))

        let x = CGFloat(clampedRoll / 45.0) * maxOffset
        let y = CGFloat(-clampedPitch / 45.0) * maxOffset

        return CGSize(width: x, height: y)
    }

    private var ringColor: Color {
        viewModel.isLevel ? .levelBright : .white.opacity(0.3)
    }

    private var bubbleColor: Color {
        viewModel.levelColor
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let scale = size / 400

            ZStack {
                // Crosshair lines
                CrosshairLines(scale: scale)

                // Concentric reference rings
                ForEach([280, 220, 160], id: \.self) { diameter in
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: CGFloat(diameter) * scale, height: CGFloat(diameter) * scale)
                }

                // Center target ring
                Circle()
                    .stroke(ringColor, lineWidth: 2 * scale)
                    .frame(width: ringSize * scale, height: ringSize * scale)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLevel)

                // Level dot at center (shows when level)
                Circle()
                    .fill(viewModel.isLevel ? Color.levelBright.opacity(0.28) : .clear)
                    .frame(width: ringSize * scale, height: ringSize * scale)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLevel)

                // Bubble
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                bubbleColor.opacity(0.9),
                                bubbleColor.opacity(0.6)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: bubbleSize * scale / 2
                        )
                    )
                    .frame(width: bubbleSize * scale, height: bubbleSize * scale)
                    .shadow(color: bubbleColor.opacity(0.5), radius: 10 * scale)
                    .offset(
                        x: bubbleOffset.width * scale,
                        y: bubbleOffset.height * scale
                    )
                    .animation(
                        .interpolatingSpring(stiffness: 200, damping: 18),
                        value: bubbleOffset
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct CrosshairLines: View {
    let scale: CGFloat

    var body: some View {
        // Horizontal line
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 300 * scale, height: 1)

        // Vertical line
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 300 * scale)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BubbleLevelView(viewModel: LevelViewModel())
    }
}
