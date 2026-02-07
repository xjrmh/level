import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Lock to portrait - we handle rotation manually by rotating text
        return .portrait
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
