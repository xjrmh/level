import SwiftUI
import Combine

enum LevelMode: String, CaseIterable {
    case bubble = "Bubble"
    case surface = "Surface"
}

final class LevelViewModel: ObservableObject {
    @Published var motionManager: MotionManager
    @Published var currentMode: LevelMode = .surface
    @Published var isCalibrated = false
    @Published var showCalibration = false

    init(motionMode: MotionManager.Mode = MotionManager.defaultMode) {
        self.motionManager = MotionManager(mode: motionMode)
    }

    // Convenience init retained for previews/tests that may expect the no-arg initializer
    convenience init() {
        self.init(motionMode: MotionManager.defaultMode)
    }

    private var cancellables = Set<AnyCancellable>()

    var pitch: Double { motionManager.calibratedPitch }
    var roll: Double { motionManager.calibratedRoll }

    var isLevel: Bool {
        abs(pitch) < 0.5 && abs(roll) < 0.5
    }

    var levelColor: Color {
        if abs(pitch) < 0.5 && abs(roll) < 0.5 {
            return .levelBright
        } else if abs(pitch) < 2.0 && abs(roll) < 2.0 {
            return .yellow
        }
        return .white
    }

    // Surface angle: angle of the device surface from horizontal
    var surfaceAngle: Double {
        let p = pitch
        let r = roll
        return sqrt(p * p + r * r)
    }

    func start() {
        motionManager.start()
        motionManager.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
                if let self = self {
                    HapticManager.shared.checkLevel(
                        pitch: self.pitch,
                        roll: self.roll
                    )
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        motionManager.stop()
        cancellables.removeAll()
    }

    func calibrate() {
        motionManager.calibrate()
        isCalibrated = true
        HapticManager.shared.tapFeedback()
    }

    func resetCalibration() {
        motionManager.resetCalibration()
        isCalibrated = false
        HapticManager.shared.tapFeedback()
    }

    func toggleMode() {
        HapticManager.shared.tapFeedback()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMode = currentMode == .bubble ? .surface : .bubble
        }
    }
}
