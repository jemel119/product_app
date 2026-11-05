# In-Class Activity 13 — Firebase Authentication

**Student:** Jeremy Henry-Atohengbe  
**Course:** CSC 4360/6360: Mobile App Development  
**Track:** Graduate  

## Overview

This Flutter project extends my In-Class 12 Firebase application with
email/password authentication.

The authentication flow includes registration, sign-in, profile email
display, sign-out, and password updates. Firebase authentication state
determines whether the app displays the authentication screen or profile.

The original Firestore product-management code remains in `main.dart`,
including CRUD operations, name search, and price filtering. The current
authentication flow opens the profile; it does not provide navigation
to the product page.

## Implemented Features

- Registration with email, password, and password confirmation.
- Sign-in using Firebase Authentication.
- Email validation and a six-character password baseline.
- Firebase enforcement of the project's configured password policy.
- Loading feedback and disabled controls during authentication requests.
- Helpful authentication errors without displaying raw exceptions.
- Generic credential errors that avoid revealing account registration.
- Auth-state routing through a stable authentication stream.
- Profile display of the signed-in user's email.
- Sign-out through AuthService.
- Password updates with confirmation.
- Reauthentication and retry when Firebase requires a recent login.
- Password fields that obscure input.
- No application code that logs or stores passwords.
- Session restoration using Firebase's native authentication persistence.

## Main Files

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Initializes Firebase, starts AuthGate, and retains the original product-management code |
| `lib/firebase_options.dart` | Generated Firebase platform configuration |
| `lib/auth_service.dart` | Registration, sign-in, sign-out, current-user access, auth-state stream, and password operations |
| `lib/authentication_screen.dart` | Registration and sign-in forms, validation, loading, and error feedback |
| `lib/auth_gate.dart` | Selects the signed-in or signed-out interface |
| `lib/profile_screen.dart` | Profile email, sign-out, password update, and recent-login recovery |
| `android/app/src/main/AndroidManifest.xml` | Android configuration and release internet permission |

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.
- Android SDK and a compatible Java installation.
- Firebase CLI and FlutterFire CLI.
- A Firebase project with Email/Password authentication enabled.
- An Android phone or emulator for final APK verification.
- Internet access for Firebase authentication requests.

## Firebase Setup

1. Open Firebase Console and select the intended Firebase project.
2. Open Authentication and enable Email/Password under Sign-in method.
3. Sign in to the Firebase CLI:

   ```powershell
   firebase login