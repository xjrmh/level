import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LevelViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    /// Returns the rotation angle in degrees to keep text upright based on device orientation
    private var textRotationAngle: Angle {
        switch deviceOrientation {
        case .landscapeLeft:
            return .degrees(90)
        case .landscapeRight:
            return .degrees(-90)
        case .portraitUpsideDown:
            return .degrees(180)
        default:
            return .degrees(0)
        }
    }

    private func axisColor(for angle: Double) -> Color {
        if abs(angle) < 0.5 {
            return .levelBright
        }
        if abs(angle) < 2.0 {
            return .yellow
        }
        return .white
    }

    private func backgroundColorForAngle(_ angle: Double) -> Color {
        let absAngle = abs(angle)
        if absAngle >= 2.0 {
            return .clear
        }
        // Exponential increase after 0.5 degrees for more dramatic effect near level
        let opacity: Double
        if absAngle <= 0.5 {
            // Linear from 0.5 opacity at 0.5° to full 0.5 opacity at 0°
            opacity = 0.5
        } else {
            // Exponential curve from 0 at 2° to ~0.5 at 0.5°
            // Using exponential: e^(-k*x) where x is angle from 0.5 to 2
            let normalizedAngle = (absAngle - 0.5) / 1.5  // 0 at 0.5°, 1 at 2°
            opacity = 0.5 * exp(-3.0 * normalizedAngle)
        }
        return Color.green.opacity(opacity)
    }

    /// Background color for bubble mode - uses combined surface angle (distance from center)
    private func bubbleModeBackgroundColor() -> Color {
        let surfaceAngle = viewModel.surfaceAngle
        if surfaceAngle >= 2.0 {
            return .clear
        }
        // Exponential increase after 0.5 degrees for more dramatic effect near level
        let opacity: Double
        if surfaceAngle <= 0.5 {
            // Full opacity at 0.5° and below
            opacity = 0.5
        } else {
            // Exponential curve from 0 at 2° to ~0.5 at 0.5°
            let normalizedAngle = (surfaceAngle - 0.5) / 1.5  // 0 at 0.5°, 1 at 2°
            opacity = 0.5 * exp(-3.0 * normalizedAngle)
        }
        return Color.green.opacity(opacity)
    }

    private func edgeHighlightOverlay(safeAreaTop: CGFloat, safeAreaBottom: CGFloat, totalHeight: CGFloat) -> some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            // Bubble mode: entire background turns green based on combined surface angle
            if viewModel.currentMode == .bubble && !isIPad {
                Rectangle()
                    .fill(bubbleModeBackgroundColor())
            } else if isLandscape {
                // Landscape: split left/right (roll on left, pitch on right)
                HStack(spacing: 0) {
                    // Left section: green when roll is close to 0
                    Rectangle()
                        .fill(backgroundColorForAngle(viewModel.roll))
                    
                    // Right section: green when pitch is close to 0
                    Rectangle()
                        .fill(backgroundColorForAngle(viewModel.pitch))
                }
            } else {
                // Portrait surface mode: split top/bottom (pitch on top, roll on bottom)
                // Calculate the toolbar height (44 for button + 8 top padding)
                let toolbarHeight: CGFloat = 52
                
                // Content area starts after safe area and toolbar
                let contentTop = safeAreaTop + toolbarHeight
                // Content area ends before bottom safe area
                let contentHeight = totalHeight - contentTop - safeAreaBottom
                
                // Match the SurfaceLevelView layout:
                // dividerSpacing = 6, availableHeight = contentHeight - 6
                // topHeight = availableHeight * 0.66
                let dividerSpacing: CGFloat = 6
                let availableHeight = contentHeight - dividerSpacing
                let topSectionHeight = availableHeight * 0.66
                
                // Position includes: safe area top + toolbar + top section + 3pt bottom padding
                let dividerPosition = contentTop + topSectionHeight + 3
                
                VStack(spacing: 0) {
                    // Top section: green when pitch is close to 0
                    Rectangle()
                        .fill(backgroundColorForAngle(viewModel.pitch))
                        .frame(height: dividerPosition)
                    
                    // Bottom section: green when roll is close to 0
                    Rectangle()
                        .fill(backgroundColorForAngle(viewModel.roll))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                edgeHighlightOverlay(
                    safeAreaTop: geometry.safeAreaInsets.top,
                    safeAreaBottom: geometry.safeAreaInsets.bottom,
                    totalHeight: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                )
                if isIPad {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.start()
            deviceOrientation = UIDevice.current.orientation
        }
        .onDisappear { viewModel.stop() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let newOrientation = UIDevice.current.orientation
            // Only update for valid orientations (ignore face up/down)
            if newOrientation.isPortrait || newOrientation.isLandscape {
                withAnimation(.easeInOut(duration: 0.3)) {
                    deviceOrientation = newOrientation
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCalibration) {
            CalibrationView(viewModel: viewModel)
        }
        .persistentSystemOverlays(.hidden)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLevel)
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
                                color: axisColor(for: viewModel.pitch)
                            )
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .rotationEffect(textRotationAngle)
                            AngleDisplayView(
                                angle: viewModel.roll,
                                label: "Roll",
                                color: axisColor(for: viewModel.roll)
                            )
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .rotationEffect(textRotationAngle)
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(width: geometry.size.width / 2)

                    Divider()
                        .background(Color.white.opacity(0.15))

                    // Right: Surface level strips
                    SurfaceLevelView(viewModel: viewModel, textRotationAngle: textRotationAngle)
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
                    .rotationEffect(textRotationAngle)
            }

            Spacer()

            // Level status indicator
            if viewModel.isLevel {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.levelBright)
                        .frame(width: 8, height: 8)
                    Text("LEVEL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundStyle(Color.levelBright)
                }
                .rotationEffect(textRotationAngle)
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
                        .rotationEffect(textRotationAngle)
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
                    color: axisColor(for: viewModel.pitch)
                )
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .rotationEffect(textRotationAngle)
                AngleDisplayView(
                    angle: viewModel.roll,
                    label: "Roll",
                    color: axisColor(for: viewModel.roll)
                )
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .rotationEffect(textRotationAngle)
            }
            .padding(.bottom, 40)
        }
    }

    private var surfaceModeContent: some View {
        SurfaceLevelView(viewModel: viewModel, textRotationAngle: textRotationAngle)
    }
}

#Preview {
    ContentView()
}
