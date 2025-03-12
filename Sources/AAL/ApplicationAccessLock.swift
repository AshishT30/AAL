import LocalAuthentication
import UIKit

public final class AppLockManager {
    
    public static let shared = AppLockManager()
    private var isAppInBackground = false
    private var isAuthenticationInProgress = false
    private var originalRootViewController: UIViewController? // Store main screen
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidEnterBackground() {
        isAppInBackground = true
    }
    
    @objc private func handleAppWillEnterForeground() {
        isAppInBackground = false
        showBlankScreen() // Lock the screen first
        
        authenticateUser { success in
            if success {
                self.restoreOriginalScreen() // Unlock and restore home screen
            }
        }
    }
    
    public func authenticateUser(completion: @escaping (Bool) -> Void) {
        guard !isAuthenticationInProgress else { return }
        isAuthenticationInProgress = true
        
        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode" // Allows passcode input
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                self.safeCompletion(completion, with: true)
                self.isAuthenticationInProgress = false
            }
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                self.isAuthenticationInProgress = false
                if success {
                    self.safeCompletion(completion, with: true)
                    self.restoreOriginalScreen() // Restore main screen after success
                } else {
                    self.showBlankScreen() // Keep screen locked on failure
                }
            }
        }
    }
    
    private func safeCompletion(_ completion: @escaping (Bool) -> Void, with result: Bool) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    private func showBlankScreen() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first else { return }
            if self.originalRootViewController == nil {
                self.originalRootViewController = window.rootViewController
            }
            let blankViewController = UIViewController()
            blankViewController.view.backgroundColor = .black
            window.rootViewController = blankViewController
            window.makeKeyAndVisible()
        }
    }
    
    private func restoreOriginalScreen() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first else { return }
            if let originalVC = self.originalRootViewController {
                window.rootViewController = originalVC
                window.makeKeyAndVisible()
                self.originalRootViewController = nil // Reset for next time
            }
        }
    }
}
