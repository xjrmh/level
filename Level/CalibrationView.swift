import SwiftUI

struct CalibrationView: View {
    @ObservedObject var viewModel: LevelViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
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

            Text(String(format: "%.2f\u{00B0}", value))
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
