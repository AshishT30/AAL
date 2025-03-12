import LocalAuthentication
import UIKit

public final class AppLockManager {
    
    public static let shared = AppLockManager()
    private var isLocked = true

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
        if isLocked {
            DispatchQueue.main.async {
                self.showLockScreen()
            }
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                self.handleAuthenticationFailure(error: error as? LAError)
                onFailure()
            }
            return
        }

        context.localizedFallbackTitle = "Enter Passcode"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    completion(true)
                } else {
                    self.isLocked = true
                    self.handleAuthenticationFailure(error: authError as? LAError)
                    completion(false)
                    onFailure()
                }
            }
        }
    }

    /// **🔹 Handle Different Failure Cases**
    private func handleAuthenticationFailure(error: LAError?) {
        guard let error = error else {
            showRetryOrExitAlert(message: "Authentication failed. Please try again.")
            return
        }

        switch error.code {
        case .biometryNotAvailable:
            showSettingsAlert(message: "Face ID/Touch ID is not available on this device.")
        case .biometryNotEnrolled:
            showSettingsAlert(message: "Face ID/Touch ID is not set up. Please enable it in settings.")
        case .biometryLockout:
            showSettingsAlert(message: "Face ID/Touch ID is locked due to multiple failed attempts. Use your device passcode.")
        case .userCancel:
            showRetryOrExitAlert(message: "Authentication canceled. Do you want to try again?")
        case .userFallback:
            showSettingsAlert(message: "You selected to use a passcode. Please unlock your device.")
        default:
            showRetryOrExitAlert(message: "Authentication failed. Please try again.")
        }
    }

    private func showRetryOrExitAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Authentication Failed",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { _ in
                self.authenticateUser(completion: { _ in }, onFailure: {})
            }))

            alert.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { _ in
                exit(0)
            }))

            if let topVC = UIApplication.shared.windows.first?.rootViewController {
                topVC.present(alert, animated: true)
            }
        }
    }

    private func showSettingsAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Authentication Required",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                }
            }))

            alert.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { _ in
                exit(0)
            }))

            if let topVC = UIApplication.shared.windows.first?.rootViewController {
                topVC.present(alert, animated: true)
            }
        }
    }

    @objc private func applicationWillEnterForeground() {
        if isLocked {
            authenticateUser(completion: { _ in }, onFailure: {})
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
}
