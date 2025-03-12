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
        let context = LAContext()
        var error: NSError?
        
        // If Face ID / Passcode is NOT set, allow access
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            debugPrint("Biometrics/Passcode not set. Allowing access.")
            dismissLockScreen() // ✅ Ensure lock screen is removed
            completion(true) // Let user in
            return
        }
        
        context.localizedFallbackTitle = "Enter Passcode"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    self.dismissLockScreen() // ✅ Ensure lock screen is removed
                    completion(true)
                } else {
                    self.isLocked = true
                    self.dismissLockScreen() // ✅ Ensure lock screen is removed even if authentication fails
                    completion(false)
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
                lockViewController.modalPresentationStyle = .fullScreen
                lockViewController.view.tag = 999 // Add a tag to identify it later
                
                window.rootViewController?.present(lockViewController, animated: false, completion: nil)
            }
        }
    }
    
    private func dismissLockScreen() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                if let presentedVC = window.rootViewController?.presentedViewController,
                   presentedVC.view.tag == 999 {
                    presentedVC.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        if isLocked {
            authenticateUser(completion: { success in
                if success {
                    self.dismissLockScreen() // ✅ Ensure blank screen is removed
                }
            }, onFailure: {})
        }
    }
}
