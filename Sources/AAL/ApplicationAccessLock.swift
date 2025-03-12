import LocalAuthentication
import UIKit

public final class AppLockManager {
    
    public static let shared = AppLockManager()
    private var isAppInBackground = false
    private var isAuthenticationInProgress = false
    private var lastFailedAuthTime: Date?
    private let lockTimeThreshold: TimeInterval = 60 // 1 minute
    
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
        
        if let lastFailedTime = lastFailedAuthTime, Date().timeIntervalSince(lastFailedTime) < lockTimeThreshold {
            showBlankScreen() // Ensure lock screen remains
            return
        }
        
        authenticateUser { success in
            if !success {
                self.lastFailedAuthTime = Date()
                self.showBlankScreen() // Keep user locked out on failure
            }
        } onFailure: {
            self.lastFailedAuthTime = Date()
            self.showBlankScreen() // Keep lock screen visible on failure
        }
    }
    
    public func authenticateUser(
        completion: @escaping (Bool) -> Void,
        onFailure: @escaping () -> Void
    ) {
        guard !isAuthenticationInProgress else { return }
        isAuthenticationInProgress = true
        
        DispatchQueue.main.async {
            self.showBlankScreen()
        }
        
        let context = LAContext()
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Allow user to bypass if no passcode, Face ID, or Touch ID is set
            DispatchQueue.main.async {
                self.safeCompletion(completion, with: true)
                self.isAuthenticationInProgress = false
            }
            return
        }
        
        context.localizedFallbackTitle = "Enter Passcode"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                self.isAuthenticationInProgress = false
                if success {
                    self.safeCompletion(completion, with: true)
                } else {
                    self.lastFailedAuthTime = Date()
                    self.showBlankScreen() // Ensure lock remains after failure
                    if let error = authError as? LAError {
                        switch error.code {
                        case .userCancel, .appCancel, .systemCancel:
                            onFailure()
                        case .passcodeNotSet:
                            self.safeCompletion(completion, with: true) // Allow access if no passcode is set
                        default:
                            onFailure()
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
