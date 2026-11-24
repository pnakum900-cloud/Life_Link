# Life-Link

A Flutter-based blood donation management application that connects
people who need blood with eligible donors and provides administrators
with tools to manage blood requests and donation activity.

## Overview

Life-Link is a college project built with **Flutter** and **Firebase**.
It provides separate experiences for regular users, donors, and
administrators.

## Main Features

### User

-   Register and sign in using Firebase Authentication.
-   Create blood requests and track their approval and donation status.
-   Search for available donors by blood group.
-   View alerts and notifications related to requests and donations.
-   Manage profile details and profile picture.

### Donor

-   Maintain donor profile information, including blood group and
    availability.
-   View compatible blood requests.
-   Accept an eligible request when available.
-   Receive updates about request and donation activity.

### Administrator

-   Review, approve, reject, and republish blood requests.
-   Manage users and donor profiles.
-   Review donation completion requests.
-   Verify or reject donation records.
-   View dashboard information and administrative alerts.

> Feature availability and permissions depend on the current application
> implementation and Firebase security rules.

## Technology Stack

-   **Frontend:** Flutter / Dart
-   **Authentication:** Firebase Authentication
-   **Database:** Cloud Firestore
-   **Platforms:** Android and other Flutter platforms configured in the
    project

## Project Structure

``` text
lib/
├── Bokul/
├── Manob/
├── Pratik/
├── main.dart
└── firebase_options.dart
```

Other important project files and directories may include:

``` text
android/
assets/
functions/
ios/
test/
web/
windows/
pubspec.yaml
firebase.json
firestore.rules
firestore.indexes.json
```

The exact folders present can vary depending on the checked-out Git
branch.

## Requirements

-   Flutter SDK
-   Dart SDK (included with Flutter)
-   Android Studio or Visual Studio Code
-   Git
-   A Firebase project configured for the application

Check your Flutter installation:

``` bash
flutter doctor
```

## Setup and Run

### 1. Clone the repository

Replace ` https://github.com/pnakum900-cloud/Life_Link ` with your GitHub repository URL.

``` bash
git clone https://github.com/pnakum900-cloud/Life_Link
cd <repository-folder>
```

### 2. Select a branch

``` bash
git branch -a
git checkout main
```

Choose the branch containing the code you want to run.

### 3. Install dependencies

``` bash
flutter pub get
```

### 4. Configure Firebase

The application uses Firebase configuration files. Ensure the
configuration matches the Firebase project you are authorized to use.

Common configuration files include:

-   `lib/firebase_options.dart`
-   `android/app/google-services.json` for Android, when required by the
    project setup
-   Platform-specific Firebase configuration for other platforms being
    built

To configure a local checkout with FlutterFire CLI:

``` bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-project-id>
```

Do not commit service-account private keys, SMTP passwords, Admin SDK
credentials, access tokens, or other private credentials.

### 5. Run the application

``` bash
flutter run
```

List available devices:

``` bash
flutter devices
```

## Firebase Configuration

Life-Link uses Firebase Authentication and Cloud Firestore.

Before testing, verify that:

1.  The correct Firebase project is selected.
2.  Firebase Authentication has the required sign-in method enabled.
3.  Cloud Firestore is created and configured.
4.  Deployed Firestore rules match the application's current data model.
5.  Required Firestore indexes have finished building.

Important Firebase files:

-   `firebase.json` --- Firebase CLI configuration.
-   `firestore.rules` --- Firestore security rules.
-   `firestore.indexes.json` --- Firestore index definitions.
-   `lib/firebase_options.dart` --- FlutterFire client configuration.

Deploy rules and indexes only if you have permission to update the
target Firebase project:

``` bash
firebase deploy --only firestore:rules,firestore:indexes
```

Review the rules and target project before deploying.

## Useful Development Commands

``` bash
# Install dependencies
flutter pub get

# Analyze the project
flutter analyze

# Run tests
flutter test

# Clean generated build files
flutter clean

# Run the app
flutter run
```

## Git Branches

The repository may use separate branches for team contributions:

-   `Manab`
-   `Bokul`
-   `Pratik`
-   `main`

Check the actual branch names with:

``` bash
git branch -a
```

Use `main` for the integrated version when the team has merged and
tested the required contributions.

## Security Notes

-   Never commit Firebase Admin SDK service-account JSON files or
    private keys.
-   Never commit SMTP app passwords, API tokens, or `.env` files
    containing secrets.
-   Keep Firestore rules restrictive and enforce authorization on the
    Firebase side, not only in the Flutter UI.
-   Do not rely on hiding buttons or screens as an access-control
    mechanism.
-   Restrict Firebase API keys where appropriate and configure Firebase
    App Check when suitable.
-   Use test accounts when testing account deletion or other destructive
    operations.

## Testing

Run automated tests:

``` bash
flutter test
```

Also test with separate regular-user, donor, and administrator accounts.
Verify request creation, administrative approval, donor acceptance,
donation completion, notifications, and profile-picture visibility.

## Contributors

This project is organized around the following team branches:

-   Manab
-   Bokul
-   Pratik

Add contributor names and responsibilities here if required for your
college submission.

## License

No license has been specified. Add a `LICENSE` file and update this
section if the project is published under a particular open-source
license.
