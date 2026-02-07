import CoreMotion
import Combine
import UIKit

final class MotionManager: ObservableObject {
    enum Mode {
        case real
        case demo
    }

    // Default mode: demo in Simulator, real on device (can be overridden at runtime)
    static var defaultMode: Mode = {
        #if targetEnvironment(simulator)
        return .demo
        #else
        return .real
        #endif
    }()

    private let mode: Mode

    // Demo timer state
    private var demoTimer: DispatchSourceTimer?
    private var demoStartDate = Date()

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let demoQueue = DispatchQueue(label: "com.level.motion.demo")

    // Raw angles in degrees
    @Published var pitch: Double = 0.0  // Forward/backward tilt
    @Published var roll: Double = 0.0   // Left/right tilt
    @Published var yaw: Double = 0.0
    
    // Device orientation derived from gravity (works even when interface is locked)
    @Published var deviceOrientation: UIDeviceOrientation = .portrait

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
    private var lastOrientation: UIDeviceOrientation = .portrait

    // Update interval: 100Hz for high accuracy
    private let updateInterval: TimeInterval = 1.0 / 100.0

    var isAvailable: Bool {
        switch mode {
        case .demo:
            return true
        case .real:
            return motionManager.isDeviceMotionAvailable
        }
    }

    init(mode: Mode = MotionManager.defaultMode) {
        self.mode = mode
        queue.name = "com.level.motion"
        queue.maxConcurrentOperationCount = 1
    }

    func start() {
        switch mode {
        case .real:
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
                
                // Derive device orientation from gravity
                let gravity = motion.gravity
                let newOrientation = self.orientationFromGravity(gravity)

                DispatchQueue.main.async {
                    self.pitch = roundedPitch
                    self.roll = roundedRoll
                    if self.deviceOrientation != newOrientation {
                        self.deviceOrientation = newOrientation
                        self.lastOrientation = newOrientation
                    }
                }
            }

        case .demo:
            // Simulate smooth changing pitch/roll using sine/cosine waves
            demoStartDate = Date()

            let timer = DispatchSource.makeTimerSource(queue: demoQueue)
            timer.schedule(deadline: DispatchTime.now(), repeating: updateInterval)
            timer.setEventHandler { [weak self] in
                guard let self = self else { return }
                let t = Date().timeIntervalSince(self.demoStartDate)

                // Generate demo angles in degrees (±5°)
                let rawPitch = sin(t * 0.7) * 5.0
                let rawRoll  = cos(t * 0.9) * 5.0

                // Apply the same low-pass filter for consistency with real mode
                self.filteredPitch = self.filteredPitch + self.filterFactor * (rawPitch - self.filteredPitch)
                self.filteredRoll  = self.filteredRoll  + self.filterFactor * (rawRoll  - self.filteredRoll)

                let roundedPitch = (self.filteredPitch * 100).rounded() / 100
                let roundedRoll  = (self.filteredRoll  * 100).rounded() / 100

                DispatchQueue.main.async {
                    self.pitch = roundedPitch
                    self.roll  = roundedRoll
                }
            }
            demoTimer = timer
            timer.resume()
        }
    }

    func stop() {
        switch mode {
        case .real:
            motionManager.stopDeviceMotionUpdates()
        case .demo:
            demoTimer?.cancel()
            demoTimer = nil
        }
    }

    func calibrate() {
        pitchOffset = pitch
        rollOffset = roll
    }

    func resetCalibration() {
        pitchOffset = 0.0
        rollOffset = 0.0
    }
    
    /// Derives device orientation from gravity vector with a 3° hysteresis to avoid rapid flips.
    /// This works even when the interface orientation is locked.
    private func orientationFromGravity(_ gravity: CMAcceleration) -> UIDeviceOrientation {
        let faceThreshold = 0.85
        if gravity.z < -faceThreshold || gravity.z > faceThreshold {
            return lastOrientation
        }

        let hysteresis = sin(1.5 * .pi / 180.0)
        let absX = abs(gravity.x)
        let absY = abs(gravity.y)

        if absX > absY + hysteresis {
            return gravity.x < 0 ? .landscapeLeft : .landscapeRight
        }

        if absY > absX + hysteresis {
            return gravity.y < 0 ? .portrait : .portraitUpsideDown
        }

        return lastOrientation
    }
}

