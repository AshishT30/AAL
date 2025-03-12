import LocalAuthentication
import UIKit

public final class AppLockManager {
    public static let shared = AppLockManager()
    private var isLocked = true
    var onAuthenticationSuccess: (() -> Void)?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    public func authenticateUser(
        completion: @escaping (Bool) -> Void,
        onFailure: @escaping () -> Void
    ) {
        guard isLocked else {
            completion(true)
            return
        }

        DispatchQueue.main.async {
            self.showLockScreen() // ✅ Show lock screen if app is locked
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                self.openSettingsAndHandleFailure(onFailure)
            }
            return
        }

        context.localizedFallbackTitle = "Enter Passcode"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    self.removeLockScreen() // ✅ Remove lock screen after success
                    self.onAuthenticationSuccess?() // ✅ Notify authentication success
                    completion(true)
                } else {
                    self.isLocked = true
                    onFailure()
                }
            }
        }
    }

    @objc private func applicationWillEnterForeground() {
        authenticateUser(
            completion: { _ in },
            onFailure: { }
        )
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

    private func removeLockScreen() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                let homeVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                window.rootViewController = homeVC
                window.makeKeyAndVisible()
            }
        }
    }
}
