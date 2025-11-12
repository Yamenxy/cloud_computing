# Cloud Computing - Firebase Cloud Messaging Project

A Flutter mobile application implementing Firebase Cloud Messaging (FCM) with Firestore database integration and Firebase Hosting for notifications history.

## 📋 Project Overview

This project consists of three main tasks:

### Task 1: Social Groups Database
- Simple form to collect social media group name and type
- Store multiple group entries in Firestore
- Display stored groups in a list view

### Task 2: Firebase Cloud Messaging (FCM)
- Receive cloud messages in foreground and background
- Handle topic subscription via data message with key `subscribeToTopic`
- Handle topic unsubscription via data message with key `unsubscribeToTopic`
- Store all received messages in Firestore

### Task 3: Notifications History Web Page
- Fetch and display all stored notifications from Firestore
- Show both notification and data payloads
- Host the page using Firebase Hosting

---

## 🚀 Setup Instructions

### Prerequisites

1. **Flutter SDK** (3.35.7 or later)
2. **Android Studio** with Android SDK
3. **Node.js and npm** (for Firebase CLI)
4. **Firebase Account**

### 1. Clone the Repository

```bash
git clone https://github.com/Yamenxy/cloud_computing.git
cd cloud_computing
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### A. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing: `cloud-comuting-ccc74`

#### B. Configure Android App
1. In Firebase Console → Project Settings → Add Android App
2. Package name: `com.example.task_1`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### C. Configure Web App (for notifications page)
1. In Firebase Console → Project Settings → Add Web App
2. App nickname: `Cloud Computing Web`
3. Copy the `firebaseConfig` object
4. Update `web/notifications.html` (around line 167) with your config

#### D. Setup Firestore Database
1. Firebase Console → Firestore Database → Create Database
2. Start in **test mode** or use these security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

#### E. Enable Cloud Messaging
1. Firebase Console → Cloud Messaging
2. Ensure Cloud Messaging API is enabled

---

## 📱 Running the App

### Check Available Devices

```bash
flutter devices
```

### Run on Android Emulator

```bash
# Launch emulator (if not running)
flutter emulators --launch Medium_Phone_API_36.1

# Run the app
flutter run -d emulator-5554
```

### Run on Physical Device

```bash
# List connected devices
adb devices

# Run on specific device
flutter run -d <device-id>
```

### Build APK

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔧 Development Commands

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

### Hot Reload / Hot Restart

While app is running:
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Check Flutter Environment

```bash
flutter doctor -v
```

### Update Dependencies

```bash
flutter pub upgrade
```

### Run Tests

```bash
flutter test
```

---

## 🌐 Firebase Hosting Setup

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Initialize Firebase (Already configured)

The project already has `firebase.json` and `.firebaserc` configured.

### 4. Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

### 5. Access Your Hosted Page

After deployment, your notifications page will be available at:
```
https://cloud-comuting-ccc74.web.app/notifications
```

---

## 🧪 Testing FCM

### Get FCM Token

1. Run the app on emulator/device
2. Check the console logs for: `🔑 FCM Token: ...`
3. Copy the token for testing

### Send Test Notification

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message" or "New campaign"
3. Enter notification details:
   - **Title**: "Test Notification"
   - **Text**: "This is a test message"
4. Click "Send test message"
5. Paste your FCM token
6. Click **Test**

### Send Data Message for Topic Subscription

1. Firebase Console → Cloud Messaging → New message
2. Click "Send test message"
3. Under "Additional options" → "Custom data"
4. Add key-value pair:
   - **Key**: `subscribeToTopic`
   - **Value**: `sports` (or any topic name)
5. Paste FCM token and send
6. Check app logs for: `✅ Subscribed to topic: sports`

### Send Topic Message

1. Create new message in Firebase Console
2. Select **Topic** as target
3. Enter topic name: `sports`
4. Send notification
5. App should receive it

### Send Data Message for Topic Unsubscription

1. Send test message with custom data:
   - **Key**: `unsubscribeToTopic`
   - **Value**: `sports`
2. Check logs for: `❌ Unsubscribed from topic: sports`

---

## 📂 Project Structure

```
cloud_computing/
├── android/                    # Android native code
│   ├── app/
│   │   ├── google-services.json   # Firebase Android config
│   │   └── src/main/
│   │       └── AndroidManifest.xml  # FCM permissions
├── lib/
│   └── main.dart              # Main Flutter application
├── web/
│   ├── index.html             # Flutter web app
│   └── notifications.html     # Notifications history page
├── firebase.json              # Firebase Hosting config
├── .firebaserc                # Firebase project config
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.5.0          # Firebase initialization
  cloud_firestore: ^5.4.4        # Firestore database
  firebase_messaging: ^15.1.3    # Cloud Messaging
  firebase_analytics: ^11.3.3    # Analytics (optional)
  cupertino_icons: ^1.0.8        # iOS icons
```

---

## 🎯 App Features

### Main Screen
- Form to add social media groups (name & type)
- Submit button to save to Firestore
- Notifications icon (🔔) to view message history
- Groups list icon (📋) to view stored groups

### Notifications History Page
- Real-time display of all FCM messages
- Statistics dashboard (Total, Today)
- Expandable cards showing:
  - Notification title and body
  - Data payload (JSON format)
  - Timestamp with smart formatting
- Beautiful purple gradient UI

### View Groups Page
- List of all stored social media groups
- Real-time updates from Firestore

---

## 🔐 Firebase Console URLs

- **Project Console**: https://console.firebase.google.com/project/cloud-comuting-ccc74
- **Firestore Database**: https://console.firebase.google.com/project/cloud-comuting-ccc74/firestore
- **Cloud Messaging**: https://console.firebase.google.com/project/cloud-comuting-ccc74/messaging
- **Hosting**: https://console.firebase.google.com/project/cloud-comuting-ccc74/hosting

---

## 🐛 Troubleshooting

### Issue: "Flutter not found"
```bash
# Add Flutter to PATH (Windows PowerShell)
$env:Path += ";C:\src\flutter\bin"

# Verify
flutter --version
```

### Issue: "Google Services plugin not found"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: "Firebase initialization failed"
- Ensure `google-services.json` is in `android/app/`
- Check package name matches: `com.example.task_1`
- Rebuild the app

### Issue: "No notifications appearing"
- Check Firestore security rules allow read/write
- Verify FCM token is correct
- Check app logs for errors

### Issue: "Firebase Hosting deployment failed"
```bash
# Re-login
firebase logout
firebase login

# Deploy again
firebase deploy --only hosting
```

---

## 📱 App Screenshots

### Features:
- ✅ Add social media groups
- ✅ View stored groups
- ✅ Receive FCM notifications (foreground & background)
- ✅ View notifications history
- ✅ Subscribe/unsubscribe to topics
- ✅ Store messages in Firestore
- ✅ Web-based notifications dashboard

---

## 👨‍💻 Development Team

- **Developer**: Ahmed
- **Project**: Cloud Computing - Firebase Integration
- **Date**: November 2025

---

## 📄 License

This project is created for educational purposes as part of a Cloud Computing course.

---

## 🆘 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase Console for errors
3. Check Flutter logs: `flutter logs`
4. Review app console output

---

## 🎓 Learning Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
