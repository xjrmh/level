import SwiftUI

struct CalibrationView: View {
    @ObservedObject var viewModel: LevelViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSoundEnabled: Bool = HapticManager.shared.isSoundEnabled

    private var backgroundColor: Color {
        viewModel.isLevel ? Color.levelBright : Color.black
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                // Dark overlay mask for calibration UI
                Color.black.opacity(0.3).ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Icon
                    Image(systemName: "level")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))

                    VStack(spacing: 16) {
                        Text("Calibrate Level")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text("Place your device on a known level surface, then tap calibrate. This compensates for any sensor offset.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 40)
                    }

                    // Current readings
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            readingBox(label: "Pitch", value: viewModel.motionManager.pitch)
                            readingBox(label: "Roll", value: viewModel.motionManager.roll)
                        }

                        if viewModel.isCalibrated {
                            HStack(spacing: 40) {
                                readingBox(label: "Adj. Pitch", value: viewModel.pitch)
                                readingBox(label: "Adj. Roll", value: viewModel.roll)
                            }
                        }
                    }
                    .padding(.vertical, 20)

                    Spacer()

                    // Sound toggle
                    HStack {
                        Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(isSoundEnabled ? .green : .secondary)
                            .frame(width: 24)
                        
                        Text("Sound when level")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isSoundEnabled)
                            .labelsHidden()
                            .tint(.green)
                            .onChange(of: isSoundEnabled) { _, newValue in
                                HapticManager.shared.isSoundEnabled = newValue
                                HapticManager.shared.tapFeedback()
                            }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

                    // Actions
                    VStack(spacing: 16) {
                        Button(action: {
                            viewModel.calibrate()
                        }) {
                            Text("Calibrate")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if viewModel.isCalibrated {
                            Button(action: {
                                viewModel.resetCalibration()
                            }) {
                                Text("Reset Calibration")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 56)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLevel)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.tapFeedback()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private func readingBox(label: String, value: Double) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            Text(String(format: "%.1f", value))
                .font(.system(size: 24, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(width: 120)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CalibrationView(viewModel: LevelViewModel())
}
