# Workout App

A mobile application that makes recording workouts easy while offering the ability to download workout plans and collaborate with others.

## 📱 Overview

Workout App is a Flutter-based mobile application designed to simplify workout tracking and planning. Users can download pre-made workout plans from the internet in JSON format, and join workouts shared by others using invite codes or QR codes. However, there is one default plan already included in the app

## ✨ Features

- **Custom Workout Creation**: Record and track your personal workout routines
- **Workout Plan Import**: Download and parse workout plans in JSON format
- **Social Workout Sharing**: Join others' workouts via invite codes or QR scanning
- **Cloud Synchronization**: Store your workout data securely in Firebase
- **Cross-Platform**: Built with Flutter for both Android and iOS compatibility

## 🛠️ Technologies

- **Frontend**: Flutter & Dart
- **Backend & Database**: Firebase
- **Platform**: Android (iOS compatible)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- [Android Studio](https://developer.android.com/studio)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Account](https://firebase.google.com/)

## ⚙️ Installation

1. Clone the repository
   ```
   git clone https://github.com/your-username/workout-app.git
   ```

2. Navigate to the project directory
   ```
   cd workout-app
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Connect your Firebase project
   - Create a new Firebase project
   - Add your Android app to the Firebase project
   - Download the `google-services.json` file
   - Place it in the `android/app` directory

5. Run the app
   ```
   flutter run
   ```

## 🔍 Usage

### Recording a Workout
1. On Workout history page, click the "+" button to start recording a workout
2. Select which type of workout you want to start, solo or collaborative or competitve
3. Then select workout plan
4. It will navigate to workout recording page 

### Importing Workout Plans
1. Download a workout plan in JSON format
2. In the app, go to download button on top right corner
3. Enter the URL of JSON file 
4. The app will parse and show you the details of plan and you will get option for saving the workout or discarding it

### Joining Others' Workouts
- **Via Invite Code**:
  1. Request an invite code from a friend
  2. Navigate to "Join Workout" page
  3. Enter the invite code and you can see the woorkout that your friend started

- **Via QR Code**:
  1. Ask your friend to generate a QR code in their app
  2. Navigate to "Join Workout"
  3. Use the QR scanner to scan their code

## 📊 Firebase Setup

To properly set up the Firebase backend:

1. Create a new Firebase project
2. Enable Authentication (Email/Password)
3. Set up Firestore Database with appropriate security rules
4. Configure Firebase Storage for workout plan files

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/your-username/workout-app/issues).

## 📞 Contact

Your Name - Krushikesh Thotange

Project Link: https://github.com/krushi-11/Workout-App
