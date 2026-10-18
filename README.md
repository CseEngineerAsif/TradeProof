# TradeProof (Flutter + Dart + Firebase)

Tech stack (proposal onujayi): Flutter, Dart, Firebase Authentication, Cloud Firestore,
Firebase Storage, Cloud Functions (optional), VS Code, Git/GitHub, Figma UI.

## 1. Chalanor shohoj niyom (Demo Mode, Firebase lagbe na)
Prerequisite: Flutter SDK (flutter.dev/install), Android Studio ba VS Code + Flutter extension.

```bash
cd tradeproof
flutter create . --org com.tradeproof --project-name tradeproof   # android/ ios/ folder banay, lib/ ke chhoy na
flutter pub get
flutter run                                                         # phone ba emulator connect kore
```
Login page e "Demo mode: quick access" theke 4 ta role e dhukte parben.

### Android e ekbar korte hobe
`android/app/build.gradle` (ba `build.gradle.kts`) e `minSdk` 23 kore din (Firebase er jonno):
`minSdk = 23` (ba `minSdkVersion 23`). Tarpor `flutter run`.

### iOS e image picker er jonno
`ios/Runner/Info.plist` e add korun:
```xml
<key>NSPhotoLibraryUsageDescription</key><string>Upload work photos for verification.</string>
```

## 2. Real Firebase backend chalu korte
```bash
npm i -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure          # project select/create; lib/firebase_options.dart overwrite kore
```
Firebase Console e: Authentication > Email/Password enable, Firestore Database create, Storage enable.
Tarpor rules deploy:
```bash
firebase deploy --only firestore:rules,storage
```
`flutterfire configure` er por app automatically Firebase mode e jabe (Profile tab e "Mode: Firebase" dekhabe).
Notun database khali thake: prothome Employer/Trainer account diye job, assessment add korun,
ar Tradesperson register korle se workers list e ashbe.

### Optional: Cloud Functions (Blaze plan lagbe)
```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

## Project structure
```
lib/main.dart          app entry, Firebase-or-Demo selection, auth gate
lib/services.dart      Repo (FirebaseRepo + DemoRepo), credential SHA-256 seal
lib/ui.dart            theme + shared widgets
lib/auth.dart          Splash, Login, Register
lib/screens.dart       Tradesperson / Employer / Client / Trainer screens
firestore.rules  storage.rules  firebase.json  functions/
```
## Features by role
- Tradesperson: portfolio (+photo upload), credentials with seal, safety certificates + expiry alert, jobs + apply, skill gap.
- Employer: dashboard, worker search, post jobs, shortlist/decline.
- Client: find workers, profile, request quote, multi-category reviews.
- Trainer: assessments (start/pass/fail), evidence approve/reject, issue sealed credentials.

## Ja ekhono nei
Messages tab, QR credential verification, push notifications, multilingual support, real licensing-system integration.
