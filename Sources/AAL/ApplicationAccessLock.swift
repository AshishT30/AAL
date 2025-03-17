import LocalAuthentication
import UIKit

public final class AppLockManager {
    
    /*
     1.shared: Ensures AppLockManager is globally accessible with a single instance.
     2.isLocked: Keeps track of whether the app is currently locked.
     3.onAuthenticationSuccess: A closure that runs when authentication succeeds.
     4.lockWindow: A separate window to display the lock screen with a blur effect.
     */
    
    public static let shared = AppLockManager()
    private var isLocked = true
    public var onAuthenticationSuccess: (() -> Void)?
    public var lockWindow: UIWindow?
    private var lastBackgroundTime: Date?
    private let lockTimeInterval: TimeInterval = 30 // Lock after 30 seconds

    /*
    1.NotificationCenter observes willEnterForegroundNotification to detect when the app comes from the background.
    2.When triggered, applicationWillEnterForeground() will attempt authentication.
    */
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /*
    1.If the app is already unlocked, authentication is skipped.
    2.Otherwise, a blurred lock screen is shown.
    3.LAContext checks if Face ID, Touch ID, or Passcode is available.
    4.If biometrics are unavailable, the user is directed to Settings.
    5.If authentication succeeds:
        a.The lock screen is removed.
        b.isLocked is set to false.
        c.The app proceeds normally.
    6.If the user cancels authentication, a retry button appears.
    7.If authentication fails, the app stays locked.
     */
    
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
            return
        }
    }

    /*
       1.Calls authenticateUser() every time the app comes from the background.
       2.Ensures security without disrupting user flow.
     */
    
    @objc private func applicationDidEnterBackground() {
        lastBackgroundTime = Date() // Save background entry time
    }
    
    @objc public func applicationWillEnterForeground() {
        guard let lastBackgroundTime = lastBackgroundTime else {
            return // No timestamp, ignore
        }
        
        let elapsedTime = Date().timeIntervalSince(lastBackgroundTime)
        
        if elapsedTime >= lockTimeInterval {
            // If app was inactive for more than 30 seconds, require authentication
            DispatchQueue.main.async {
                self.isLocked = true
                self.authenticateUser(completion: { _ in }, onFailure: {})
            }
        }
    }

    
    /*
     1.If the device does not have Face ID or Touch ID, users are redirected to Settings.
     2.Ensures users are informed that authentication must be enabled manually.
     */

    private func openSettingsAndHandleFailure(_ onFailure: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsURL) else { return }
            UIApplication.shared.open(settingsURL)
            onFailure()
        }
    }

    /*
     1.Creates a blur effect on the entire screen.
     2.Uses UIWindow to overlay the screen above all content.
     3.Prevents users from interacting with the app until authentication succeeds.
     */
    
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

    /*
    1.If authentication is canceled, a retry button is shown.
    2.Users can try again without restarting the app.
    */
    
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

    //Once authentication succeeds, the lock screen disappears.
    private func removeLockScreen() {
        DispatchQueue.main.async {
            self.lockWindow?.isHidden = true
            self.lockWindow = nil
        }
    }
}
