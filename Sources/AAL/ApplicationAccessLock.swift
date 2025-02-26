import LocalAuthentication
import UIKit

public final class AppLockManager {
    public static let shared = AppLockManager()
    private init() {}

    public func authenticateUser(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.showBlankScreen()
        }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                self.safeCompletion(completion, with: false)
                self.openSettingsAndTerminateApp()
            }
            return
        }
        
        context.localizedFallbackTitle = "Enter Passcode"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.safeCompletion(completion, with: true)
                } else {
                    if let error = authError as? LAError {
                        switch error.code {
                        case .userCancel, .appCancel, .systemCancel:
                            self.terminateApp()
                        case .passcodeNotSet:
                            self.openSettingsAndTerminateApp()
                        default:
                            self.terminateApp()
                        }
                    }
                    self.safeCompletion(completion, with: false)
                }
            }
        }
    }

    private func safeCompletion(_ completion: @escaping (Bool) -> Void, with result: Bool) {
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func openSettingsAndTerminateApp() {
        DispatchQueue.main.async {
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
                self.terminateApp()
            }
        }
    }

    private func showBlankScreen() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                let blankViewController = UIViewController()
                blankViewController.view.backgroundColor = .black
                window.rootViewController = blankViewController
                window.makeKeyAndVisible()
            }
        }
    }

    private func terminateApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0)
        }
    }
}
