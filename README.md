# AAL
**AppLockManager** is responsible for handling biometric authentication **(Face ID/Touch ID/Passcode)** when the app moves from the background to the foreground. It ensures **security** while allowing a smooth user experience with a retry option if authentication fails or is canceled.

**Key Responsibilities of AppLockManager**
* **Singleton Instance** – Ensures only one instance of the lock manager is used throughout the app.
* **Foreground Lock Handling** – Listens for the app returning from the background to trigger authentication.
* **Biometric Authentication** – Uses Face ID, Touch ID, or passcode to verify the user.
* **Lock Screen UI** – Displays a blur effect when authentication is required.
* **Retry Option** – Allows the user to retry authentication if canceled.
* **App Settings Handling** – If Face ID/Passcode is not set, directs the user to device settings.
