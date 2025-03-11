import LocalAuthentication
import UIKit

public final class AppLockManager {
    
    public static let shared = AppLockManager()
    private var isLocked = true // Ensure app remains locked properly

    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

    }

    public func authenticateUser(
            completion: @escaping (Bool) -> Void,
            onFailure: @escaping () -> Void
        ) {
            if isLocked {
                DispatchQueue.main.async {
                    self.showLockScreen()
                }
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
                        self.isLocked = false
                        self.safeCompletion(completion, with: true)
                    } else {
                        self.isLocked = true
                        self.safeCompletion(completion, with: false)
                        onFailure()
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
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(settingsURL) else { return }
                UIApplication.shared.open(settingsURL)
                onFailure()
            }
        }

        private func showLockScreen() {
            DispatchQueue.main.async {
                if let window = UIApplication.shared.windows.first {
                    let lockViewController = UIViewController()
                    lockViewController.view.backgroundColor = .black
                    window.rootViewController = lockViewController
                    window.makeKeyAndVisible()
                }
            }
        }

        @objc private func applicationWillEnterForeground() {
            if isLocked {
                authenticateUser(completion: { _ in }, onFailure: {})
            }
        }
    }
