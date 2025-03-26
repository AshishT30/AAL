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
    private var lockWindow: UIWindow?
    private var lastBackgroundTime: Date?
    private let lockTimeInterval: TimeInterval = 30 // Lock after 30 seconds
    public var customPopupView: UIView?
    private var wasAuthenticatingWhenBackgrounded = false
    private var didInterruptAuthentication = false

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

    
    //Check if Biometrics or Passcode is set up
        public func isBiometricOrPasscodeSetup() -> Bool {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                return true //Face ID, Touch ID, or Passcode is enabled
            } else {
                return false //None are set up
            }
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
        
        //Check if Biometrics or Passcode is enabled before locking
        if !isBiometricOrPasscodeSetup() {
            print("Skipping lock screen, no biometrics or passcode is set.")
            isLocked = false
            onAuthenticationSuccess?()
            completion(true)
            return
        }
        
        wasAuthenticatingWhenBackgrounded = true // Track authentication start
        didInterruptAuthentication = false
        
        DispatchQueue.main.async {
            self.showLockScreen() // Show blurred lock screen
        }
        
        let context = LAContext()
        var error: NSError?
        
        context.localizedFallbackTitle = "Enter Passcode"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, authError in
            DispatchQueue.main.async {
                self.wasAuthenticatingWhenBackgrounded = false // Reset flag after authentication
                if success {
                    self.isLocked = false
                    self.removeLockScreen() // Remove lock screen after success
                    self.onAuthenticationSuccess?()
                    completion(true)
                } else if let error = authError as? LAError, error.code == .userCancel {
                    // If the user cancels, show the lock screen with retry
                    self.didInterruptAuthentication = true
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
            if wasAuthenticatingWhenBackgrounded {
                didInterruptAuthentication = true
        }
    }
    
    @objc public func applicationWillEnterForeground() {
        DispatchQueue.main.async {
            if self.isLocked && self.didInterruptAuthentication {
                self.showLockScreenWithRetry() // Show retry only if user backgrounded during authentication
            }
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
    
    public func showLockScreenWithRetry() {
        DispatchQueue.main.async {
            if self.lockWindow == nil {
                self.lockWindow = UIWindow(frame: UIScreen.main.bounds)
            }
            
            guard let lockWindow = self.lockWindow else { return }
            
            let lockVC = UIViewController()
            lockVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            // Use the custom popup if provided, else use a default one
            if let customPopup = self.customPopupView {
                lockVC.view.addSubview(customPopup)
                
                customPopup.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    customPopup.centerXAnchor.constraint(equalTo: lockVC.view.centerXAnchor),
                    customPopup.centerYAnchor.constraint(equalTo: lockVC.view.centerYAnchor),
                    customPopup.widthAnchor.constraint(equalToConstant: 300),
                    customPopup.heightAnchor.constraint(equalToConstant: 250)
                ])
            } else {
                let defaultPopup = CustomPopupView(
                    title: "App is Locked",
                    message: "Please unlock to continue.",
                    buttonTitle: "Unlock",
                    image: "lock",
                    buttonColor: "#105866"
                )
                defaultPopup.onButtonTap = { [weak self] in
                    self?.retryAuthentication()
                }
                lockVC.view.addSubview(defaultPopup)
                
                defaultPopup.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    defaultPopup.centerXAnchor.constraint(equalTo: lockVC.view.centerXAnchor),
                    defaultPopup.centerYAnchor.constraint(equalTo: lockVC.view.centerYAnchor),
                    defaultPopup.widthAnchor.constraint(equalToConstant: 300),
                    defaultPopup.heightAnchor.constraint(equalToConstant: 250)
                ])
            }
            
            lockWindow.rootViewController = lockVC
            lockWindow.windowLevel = .alert + 1
            lockWindow.makeKeyAndVisible()
        }
    }

    @objc public func retryAuthentication() {
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
