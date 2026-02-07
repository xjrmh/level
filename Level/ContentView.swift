import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LevelViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if isIPad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .fullScreenCover(isPresented: $viewModel.showCalibration) {
            CalibrationView(viewModel: viewModel)
        }
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // Main content
            if viewModel.currentMode == .bubble {
                bubbleModeContent
            } else {
                surfaceModeContent
            }
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbar
                .padding(.horizontal, 32)
                .padding(.top, 12)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left: Bubble view
                    VStack(spacing: 20) {
                        BubbleLevelView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Angle readings below bubble
                        HStack(spacing: 24) {
                            AngleDisplayView(
                                angle: viewModel.pitch,
                                label: "Pitch",
                                color: viewModel.levelColor
                            )
                            AngleDisplayView(
                                angle: viewModel.roll,
                                label: "Roll",
                                color: viewModel.levelColor
                            )
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(width: geometry.size.width / 2)

                    Divider()
                        .background(Color.white.opacity(0.15))

                    // Right: Surface level strips
                    SurfaceLevelView(viewModel: viewModel)
                        .frame(width: geometry.size.width / 2)
                }
            }
        }
    }

    // MARK: - Shared Components

    private var toolbar: some View {
        HStack {
            // Calibration button
            Button(action: { viewModel.showCalibration = true }) {
                Image(systemName: viewModel.isCalibrated ? "scope" : "circle.dotted")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(viewModel.isCalibrated ? .green : .white.opacity(0.7))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Level status indicator
            if viewModel.isLevel {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("LEVEL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundStyle(.green)
                }
                .transition(.opacity.combined(with: .scale))
            }

            Spacer()

            // Mode toggle (iPhone only)
            if !isIPad {
                Button(action: { viewModel.toggleMode() }) {
                    Image(systemName: viewModel.currentMode == .bubble ? "square.split.1x2" : "circle.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLevel)
    }

    // MARK: - iPhone Mode Views

    private var bubbleModeContent: some View {
        VStack(spacing: 0) {
            BubbleLevelView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Angle readings
            HStack(spacing: 24) {
                AngleDisplayView(
                    angle: viewModel.pitch,
                    label: "Pitch",
                    color: viewModel.levelColor
                )
                AngleDisplayView(
                    angle: viewModel.roll,
                    label: "Roll",
                    color: viewModel.levelColor
                )
            }
            .padding(.bottom, 40)
        }
    }

    private var surfaceModeContent: some View {
        SurfaceLevelView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
