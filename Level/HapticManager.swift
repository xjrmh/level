import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var wasLevel = false

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        notificationGenerator.prepare()
    }

    func checkLevel(pitch: Double, roll: Double, threshold: Double = 0.5) {
        let isLevel = abs(pitch) <= threshold && abs(roll) <= threshold

        if isLevel && !wasLevel {
            notificationGenerator.notificationOccurred(.success)
        } else if !isLevel && wasLevel {
            impactLight.impactOccurred()
        }

        wasLevel = isLevel
    }

    func tapFeedback() {
        impactMedium.impactOccurred()
    }
}
