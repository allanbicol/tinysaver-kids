# Ipon Buddy — Firebase Setup Guide

## 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add Project" → name it `ipon-buddy`
3. Disable Google Analytics (not needed)
4. Click "Create project"

## 2. Enable Authentication

1. In Firebase Console → **Authentication** → **Get started**
2. Click **Email/Password** → Enable → Save

## 3. Enable Firestore

1. In Firebase Console → **Firestore Database** → **Create database**
2. Choose **Start in production mode** (rules are in `firestore.rules`)
3. Select a region close to your users
4. Deploy rules:
   ```
   firebase deploy --only firestore:rules
   ```
   Or paste `firestore.rules` contents into the Firebase Console Rules tab.

## 4. Connect Flutter to Firebase

Install FlutterFire CLI (one-time):
```bash
dart pub global activate flutterfire_cli
```

Run configuration (from project root):
```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

This generates `lib/firebase_options.dart` — **replace** the placeholder file.

## 5. Android Setup

1. In Firebase Console → Project Settings → Add Android app
2. Android package: `com.tinysaverkids.tinysaver_kids`
3. Download `google-services.json` → place in `android/app/`
4. The `build.gradle` files are already configured by FlutterFire CLI.

## 6. iOS Setup

1. In Firebase Console → Project Settings → Add iOS app
2. iOS bundle ID: `com.tinysaverkids.tinysaver_kids`
3. Download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Open `ios/Runner.xcworkspace` in Xcode → drag file if needed.

## 7. Run the app

```bash
flutter pub get
flutter run
```

## Default PIN

The default parent PIN is **1234**. Change it immediately in Parent Mode → Settings.

## Sample Data

On first sign-up, these default tasks are created automatically:
- Make my bed (2 coins)
- Brush teeth (1 coin)
- Eat vegetables (3 coins)
- Read a book (5 coins)
- Clean up toys (2 coins)

Default reward: **Toy Car** (target: 20 coins)

## Firestore Data Structure

```
users/{uid}
  name: string
  coin_balance: number
  pin_code: string
  last_activity: timestamp

  tasks/{taskId}
    title: string
    coin_reward: number
    icon_name: string
    is_active: boolean
    created_at: timestamp

  task_logs/{logId}
    task_id: string
    task_title: string
    coins_earned: number
    approved: boolean
    created_at: timestamp

  rewards/{rewardId}
    title: string
    target_coins: number
    emoji: string
    is_active: boolean
    is_redeemed: boolean
```
