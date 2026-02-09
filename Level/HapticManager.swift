import UIKit
import AVFoundation

final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var wasLevel = false
    private var wasPitchLevel = false
    private var wasRollLevel = false
    
    // Sound settings
    private static let soundEnabledKey = "com.level.sound.enabled"
    var isSoundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.soundEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.soundEnabledKey) }
    }
    
    // Audio engine for tone generation
    private var audioEngine: AVAudioEngine?
    private var tonePlayer: AVAudioPlayerNode?
    private var beepTimer: Timer?
    private var currentAngle: Double = 0.5 // Combined angle from level
    
    // Tone settings
    private let sampleRate: Double = 44100
    private let beepDuration: Double = 0.1 // Duration of each beep

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        notificationGenerator.prepare()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        audioEngine = AVAudioEngine()
        tonePlayer = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = tonePlayer else { return }
        
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func generateToneBuffer(frequency: Double) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * beepDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        let data = buffer.floatChannelData![0]
        let amplitude: Float = 0.3
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            // Apply envelope to avoid clicks
            let envelope: Float
            let attackFrames = Int(sampleRate * 0.01)
            let releaseFrames = Int(sampleRate * 0.01)
            
            if frame < attackFrames {
                envelope = Float(frame) / Float(attackFrames)
            } else if frame > Int(frameCount) - releaseFrames {
                envelope = Float(Int(frameCount) - frame) / Float(releaseFrames)
            } else {
                envelope = 1.0
            }
            
            data[frame] = amplitude * envelope * sin(Float(2.0 * .pi * frequency * time))
        }
        
        return buffer
    }
    
    private func playTone(frequency: Double) {
        guard isSoundEnabled,
              let player = tonePlayer,
              let buffer = generateToneBuffer(frequency: frequency) else { return }
        
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
    
    private let soundThreshold: Double = 2.0 // Start beeping at 2 degree radius
    private let perfectLevelThreshold: Double = 0.1 // Threshold for "perfect" level (double beep)
    private let toneFrequency: Double = 880 // Fixed tone frequency (A5)
    private let perfectToneFrequency: Double = 1320 // Higher tone for perfect level (E6)
    
    private func beepIntervalForAngle(_ angle: Double) -> Double {
        // Map angle from 0-1 degrees to beep interval
        // At threshold (1°) = slowest beeping (0.8 seconds)
        // Near perfect (0.1°) = fastest beeping (0.2 seconds)
        let clampedAngle = min(max(angle, perfectLevelThreshold), soundThreshold)
        let normalizedAngle = (clampedAngle - perfectLevelThreshold) / (soundThreshold - perfectLevelThreshold)
        
        let minInterval: Double = 0.2  // Fastest beeping
        let maxInterval: Double = 0.8  // Slowest beeping
        
        return minInterval + (normalizedAngle * (maxInterval - minInterval))
    }
    
    private func playBeep() {
        playTone(frequency: toneFrequency)
    }
    
    private func playDoubleBeep() {
        playTone(frequency: perfectToneFrequency)
        // Schedule second beep after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.playTone(frequency: self?.perfectToneFrequency ?? 1320)
        }
    }
    
    private func scheduleNextBeep() {
        guard isSoundEnabled else { return }
        
        let isPerfectLevel = currentAngle < perfectLevelThreshold
        let interval = isPerfectLevel ? 1.0 : beepIntervalForAngle(currentAngle)
        
        beepTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self, self.isSoundEnabled else { return }
            
            if self.currentAngle < self.perfectLevelThreshold {
                self.playDoubleBeep()
            } else {
                self.playBeep()
            }
            
            // Schedule next beep
            self.scheduleNextBeep()
        }
    }
    
    private func startBeeping() {
        guard isSoundEnabled, beepTimer == nil else { return }
        
        // Play immediately
        if currentAngle < perfectLevelThreshold {
            playDoubleBeep()
        } else {
            playBeep()
        }
        
        // Schedule next beep
        scheduleNextBeep()
    }
    
    private func stopBeeping() {
        beepTimer?.invalidate()
        beepTimer = nil
    }

    private var wasInSoundRange = false
    private var wasPitchInSoundRange = false
    private var wasRollInSoundRange = false
    
    // Track current axis angles for surface mode
    private var currentPitchAngle: Double = 1.0
    private var currentRollAngle: Double = 1.0
    
    enum LevelMode {
        case bubble
        case surface
    }
    
    func checkLevel(pitch: Double, roll: Double, threshold: Double = 0.5, mode: LevelMode = .bubble) {
        // Calculate combined angle (distance from perfect level)
        currentAngle = sqrt(pitch * pitch + roll * roll)
        currentPitchAngle = abs(pitch)
        currentRollAngle = abs(roll)
        
        let isPitchLevel = abs(pitch) < threshold
        let isRollLevel = abs(roll) < threshold
        let isLevel = isPitchLevel && isRollLevel
        
        // Sound thresholds
        let isInSoundRange = currentAngle < soundThreshold
        let isPitchInSoundRange = currentPitchAngle < soundThreshold
        let isRollInSoundRange = currentRollAngle < soundThreshold

        // Handle sound based on mode
        if isSoundEnabled {
            if mode == .bubble {
                // Bubble mode: beep when combined angle is in range
                if isInSoundRange && !wasInSoundRange {
                    startBeeping()
                } else if !isInSoundRange && wasInSoundRange {
                    stopBeeping()
                }
            } else {
                // Surface mode: beep when either pitch OR roll is in range
                let eitherInRange = isPitchInSoundRange || isRollInSoundRange
                let wasEitherInRange = wasPitchInSoundRange || wasRollInSoundRange
                
                if eitherInRange && !wasEitherInRange {
                    startBeeping()
                } else if !eitherInRange && wasEitherInRange {
                    stopBeeping()
                }
                
                // Update current angle to use the closer axis for beep frequency
                if isPitchInSoundRange && isRollInSoundRange {
                    currentAngle = min(currentPitchAngle, currentRollAngle)
                } else if isPitchInSoundRange {
                    currentAngle = currentPitchAngle
                } else if isRollInSoundRange {
                    currentAngle = currentRollAngle
                }
            }
        }
        
        // Handle haptics (0.5 degree threshold)
        if !isSoundEnabled {
            if isLevel && !wasLevel {
                notificationGenerator.notificationOccurred(.success)
            } else if !isLevel && wasLevel {
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
        }

        wasLevel = isLevel
        wasPitchLevel = isPitchLevel
        wasRollLevel = isRollLevel
        wasInSoundRange = isInSoundRange
        wasPitchInSoundRange = isPitchInSoundRange
        wasRollInSoundRange = isRollInSoundRange
    }

    func tapFeedback() {
        impactMedium.impactOccurred()
    }
}
