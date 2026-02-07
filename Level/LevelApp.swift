import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    private var orientationObserver: NSObjectProtocol?

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Lock to portrait on both iPhone and iPad
        // We handle rotation manually by rotating text to stay upright
        // while keeping level indicators fixed
        return .portrait
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
            self.orientationObserver = nil
        }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

}

@main
struct LevelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel: LevelViewModel

    init() {
        // Determine demo mode from launch arguments / environment, with sensible defaults
        let arguments = ProcessInfo.processInfo.arguments
        let env = ProcessInfo.processInfo.environment

        // Command-line overrides
        let forceDemo = arguments.contains("--demo") || env["DEMO_MODE"] == "1"
        let forceReal = arguments.contains("--real") || env["DEMO_MODE"] == "0"

        // Default mode: demo in Simulator, real on device
        let defaultMode: MotionManager.Mode = MotionManager.defaultMode

        let selectedMode: MotionManager.Mode
        if forceDemo { selectedMode = .demo }
        else if forceReal { selectedMode = .real }
        else { selectedMode = defaultMode }

        // Build the view model with the chosen motion mode
        _viewModel = StateObject(wrappedValue: LevelViewModel(motionMode: selectedMode))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
