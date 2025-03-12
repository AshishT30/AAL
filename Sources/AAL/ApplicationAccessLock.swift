import LocalAuthentication
import UIKit

public final class AppLockManager {
    public static let shared = AppLockManager()
    private var isLocked = true
    public var onAuthenticationSuccess: (() -> Void)?
    private var lockViewController: UIViewController?

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
            self.showLockScreen() // Show blurred lock screen first
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
                    self.removeLockScreen() // Remove lock screen after success
                    self.onAuthenticationSuccess?()
                    completion(true)
                } else if let error = authError as? LAError, error.code == .userCancel {
                    // If the user cancels, show the lock screen again with retry option
                    self.showLockScreenWithRetry()
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
                let lockVC = UIViewController()
                lockVC.view.backgroundColor = .clear

                // Add Blur Effect
                let blurEffect = UIBlurEffect(style: .dark)
                let blurView = UIVisualEffectView(effect: blurEffect)
                blurView.frame = lockVC.view.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                lockVC.view.addSubview(blurView)

                window.rootViewController = lockVC
                window.makeKeyAndVisible()
                
                self.lockViewController = lockVC
            }
        }
    }

    private func showLockScreenWithRetry() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                let lockVC = UIViewController()
                lockVC.view.backgroundColor = .clear

                // Add Blur Effect
                let blurEffect = UIBlurEffect(style: .dark)
                let blurView = UIVisualEffectView(effect: blurEffect)
                blurView.frame = lockVC.view.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                lockVC.view.addSubview(blurView)

                // Create Retry Button
                let retryButton = UIButton(type: .system)
                retryButton.setTitle("Retry Authentication", for: .normal)
                retryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
                retryButton.backgroundColor = .systemBlue
                retryButton.setTitleColor(.white, for: .normal)
                retryButton.layer.cornerRadius = 25
                retryButton.clipsToBounds = true
                retryButton.frame = CGRect(x: 50, y: 0, width: 250, height: 50)

                retryButton.center = lockVC.view.center
                retryButton.addTarget(self, action: #selector(self.retryAuthentication), for: .touchUpInside)

                lockVC.view.addSubview(retryButton)
                window.rootViewController = lockVC
                window.makeKeyAndVisible()
                
                self.lockViewController = lockVC
            }
        }
    }

    @objc private func retryAuthentication() {
        authenticateUser(completion: { _ in }, onFailure: {})
    }

    private func removeLockScreen() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                let homeVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                window.rootViewController = homeVC
                window.makeKeyAndVisible()
                self.lockViewController = nil
            }
        }
    }
}
