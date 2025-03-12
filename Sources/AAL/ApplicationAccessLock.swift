import LocalAuthentication
import UIKit

public final class AppLockManager {
    public static let shared = AppLockManager()
    private var isLocked = true
    public var onAuthenticationSuccess: (() -> Void)?
    private var lockWindow: UIWindow?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    public func authenticateUser(completion: @escaping (Bool) -> Void,
        onFailure: @escaping () -> Void
    ) {
        guard isLocked else {
            completion(true)
            return
        }

        DispatchQueue.main.async {
            self.showLockScreen() // Show blurred lock screen
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
                    // If the user cancels, show the lock screen with retry
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
            if self.lockWindow == nil {
                self.lockWindow = UIWindow(frame: UIScreen.main.bounds)
            }

            guard let lockWindow = self.lockWindow else { return }

            let lockVC = UIViewController()
            lockVC.view.backgroundColor = .clear

            //  Add Blur Effect
            let blurEffect = UIBlurEffect(style: .light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = lockVC.view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            lockVC.view.addSubview(blurView)

            lockWindow.rootViewController = lockVC
            lockWindow.windowLevel = .alert + 1
            lockWindow.makeKeyAndVisible()
        }
    }

    private func showLockScreenWithRetry() {
        DispatchQueue.main.async {
            if self.lockWindow == nil {
                self.lockWindow = UIWindow(frame: UIScreen.main.bounds)
            }

            guard let lockWindow = self.lockWindow else { return }

            let lockVC = UIViewController()
            lockVC.view.backgroundColor = .clear

            // Add Blur Effect
            let blurEffect = UIBlurEffect(style: .light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = lockVC.view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            lockVC.view.addSubview(blurView)

            // Create and Style Retry Button
            let retryButton = UIButton(type: .system)
            retryButton.setTitle("Retry Authentication", for: .normal)
            retryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            retryButton.backgroundColor = .systemBlue
            retryButton.setTitleColor(.white, for: .normal)
            retryButton.layer.cornerRadius = 25
            retryButton.clipsToBounds = true
            retryButton.translatesAutoresizingMaskIntoConstraints = false

            lockVC.view.addSubview(retryButton)

            // Center Retry Button Properly
            NSLayoutConstraint.activate([
                retryButton.centerXAnchor.constraint(equalTo: lockVC.view.centerXAnchor),
                retryButton.centerYAnchor.constraint(equalTo: lockVC.view.centerYAnchor),
                retryButton.widthAnchor.constraint(equalToConstant: 250),
                retryButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            retryButton.addTarget(self, action: #selector(self.retryAuthentication), for: .touchUpInside)

            lockWindow.rootViewController = lockVC
            lockWindow.windowLevel = .alert + 1
            lockWindow.makeKeyAndVisible()
        }
    }

    @objc private func retryAuthentication() {
        authenticateUser(completion: { _ in }, onFailure: {})
    }

    private func removeLockScreen() {
        DispatchQueue.main.async {
            self.lockWindow?.isHidden = true
            self.lockWindow = nil
        }
    }
}
