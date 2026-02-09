import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var wasLevel = false
    private var wasPitchLevel = false
    private var wasRollLevel = false

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        notificationGenerator.prepare()
    }

    func checkLevel(pitch: Double, roll: Double, threshold: Double = 0.5) {
        let isPitchLevel = abs(pitch) < threshold
        let isRollLevel = abs(roll) < threshold
        let isLevel = isPitchLevel && isRollLevel

        if isLevel && !wasLevel {
            // Both axes level - strong success feedback
            notificationGenerator.notificationOccurred(.success)
        } else if !isLevel && wasLevel {
            // Lost full level
            impactLight.impactOccurred()
        } else {
            // Check individual axes for gentle feedback
            if isPitchLevel && !wasPitchLevel {
                impactLight.impactOccurred()
            }
            if isRollLevel && !wasRollLevel {
                impactLight.impactOccurred()
            }
        }

        wasLevel = isLevel
        wasPitchLevel = isPitchLevel
        wasRollLevel = isRollLevel
    }

    func tapFeedback() {
        impactMedium.impactOccurred()
    }
}
