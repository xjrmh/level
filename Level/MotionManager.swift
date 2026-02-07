import CoreMotion
import Combine

final class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    // Raw angles in degrees
    @Published var pitch: Double = 0.0  // Forward/backward tilt
    @Published var roll: Double = 0.0   // Left/right tilt
    @Published var yaw: Double = 0.0

    // Calibration offsets
    @Published var pitchOffset: Double = 0.0
    @Published var rollOffset: Double = 0.0

    // Calibrated angles
    var calibratedPitch: Double { pitch - pitchOffset }
    var calibratedRoll: Double { roll - rollOffset }

    // Low-pass filter coefficient (smaller = smoother but more lag)
    private let filterFactor: Double = 0.15

    // Filtered values for smooth display
    private var filteredPitch: Double = 0.0
    private var filteredRoll: Double = 0.0

    // Update interval: 100Hz for high accuracy
    private let updateInterval: TimeInterval = 1.0 / 100.0

    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    init() {
        queue.name = "com.level.motion"
        queue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: queue
        ) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            let rawPitch = motion.attitude.pitch * (180.0 / .pi)
            let rawRoll = motion.attitude.roll * (180.0 / .pi)

            // Apply low-pass filter for stability while maintaining accuracy
            self.filteredPitch = self.filteredPitch + self.filterFactor * (rawPitch - self.filteredPitch)
            self.filteredRoll = self.filteredRoll + self.filterFactor * (rawRoll - self.filteredRoll)

            // Round to 0.01 degree precision
            let roundedPitch = (self.filteredPitch * 100).rounded() / 100
            let roundedRoll = (self.filteredRoll * 100).rounded() / 100

            DispatchQueue.main.async {
                self.pitch = roundedPitch
                self.roll = roundedRoll
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    func calibrate() {
        pitchOffset = pitch
        rollOffset = roll
    }

    func resetCalibration() {
        pitchOffset = 0.0
        rollOffset = 0.0
    }
}
