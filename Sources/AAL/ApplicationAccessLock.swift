import LocalAuthentication
import UIKit

public final class AppLockManager {
    
    public static let shared = AppLockManager()
    
    private init() {}

    public func authenticateUser(
        completion: @escaping (Bool) -> Void,
        onFailure: @escaping () -> Void) {
            
        DispatchQueue.main.async {
            self.showBlankScreen()
        }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                self.safeCompletion(completion, with: false)
                self.openSettingsAndHandleFailure(onFailure)
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
                            onFailure() // Let the app handle termination or other logic
                        case .passcodeNotSet:
                            self.openSettingsAndHandleFailure(onFailure)
                        default:
                            onFailure() // Handle other failures
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

    private func openSettingsAndHandleFailure(_ onFailure: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
                onFailure()
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
}
