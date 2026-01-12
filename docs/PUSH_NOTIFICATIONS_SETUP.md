# Push Notifications Setup Guide

This guide covers the complete setup for push notifications in GymGo Mobile using Firebase Cloud Messaging (FCM).

## Prerequisites

1. **Firebase Project** - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. **Flutter Firebase CLI** - Install with `dart pub global activate flutterfire_cli`

## 1. Firebase Project Setup

### Create Firebase Project

1. Go to Firebase Console
2. Click "Add project"
3. Name it "GymGo" (or your preferred name)
4. Enable Google Analytics if desired
5. Create the project

### Configure FlutterFire

Run in your project directory:

```bash
flutterfire configure --project=your-firebase-project-id
```

This will:
- Create `lib/firebase_options.dart`
- Add `google-services.json` for Android
- Add `GoogleService-Info.plist` for iOS

Then update `main.dart` to use these options:

```dart
import 'firebase_options.dart';

void main() async {
  // ...
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ...
}
```

## 2. Android Configuration

### AndroidManifest.xml

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Required for notifications on Android 13+ -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <!-- Optional: For receiving messages when app is in background -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>

    <application
        android:label="GymGo"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- FCM Default Notification Channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="classes" />

        <!-- FCM Default Notification Icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />

        <!-- FCM Default Notification Color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />

        <!-- ... existing activity and other elements ... -->

    </application>
</manifest>
```

### Notification Color (Optional)

Create `android/app/src/main/res/values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#CDFF00</color>
</resources>
```

### Build Gradle

Ensure `android/build.gradle` has:

```gradle
buildscript {
    dependencies {
        // ... other dependencies
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Ensure `android/app/build.gradle` has:

```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34  // or higher
        // ...
    }
}
```

## 3. iOS Configuration

### Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- For flutter_local_notifications -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### Enable Push Notifications Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Signing & Capabilities
3. Click "+ Capability"
4. Add "Push Notifications"
5. Add "Background Modes" and check:
   - Remote notifications
   - Background fetch

### AppDelegate.swift

Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()

    // Register for push notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle token refresh
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
```

### Podfile

Add to `ios/Podfile`:

```ruby
platform :ios, '12.0'

# Firebase pods with static framework linkage
pod 'FirebaseMessaging', :modular_headers => true
```

Then run:

```bash
cd ios && pod install && cd ..
```

## 4. Backend Setup

### Database Schema

Create `push_tokens` table in Supabase:

```sql
CREATE TABLE push_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  device_id TEXT,
  app_version TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, platform)
);

-- Index for efficient querying
CREATE INDEX idx_push_tokens_org ON push_tokens(organization_id) WHERE is_active = true;
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);

-- RLS Policies
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own tokens"
  ON push_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Firebase Admin SDK (Backend)

For sending notifications from your backend, use Firebase Admin SDK:

```javascript
// Node.js example
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send to topic (recommended for gym-wide broadcasts)
async function sendClassCreatedNotification(gymId, classData) {
  const message = {
    topic: `gym_${gymId}`,
    notification: {
      title: 'Nueva clase disponible',
      body: `${classData.name} a las ${classData.time}. ¡Reserva ahora!`
    },
    data: {
      type: 'class_created',
      classId: classData.id,
      gymId: gymId,
      title: classData.name,
      startTime: classData.startTime
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'classes'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1
        }
      }
    }
  };

  return admin.messaging().send(message);
}
```

### Supabase Edge Function Example

```typescript
// supabase/functions/send-class-notification/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

serve(async (req) => {
  const { gymId, classData } = await req.json()

  // Use Firebase Admin SDK or HTTP v1 API
  const response = await fetch(
    'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          topic: `gym_${gymId}`,
          notification: {
            title: 'Nueva clase disponible',
            body: `${classData.name} - ¡Reserva ahora!`,
          },
          data: {
            type: 'class_created',
            classId: classData.id,
            gymId: gymId,
            title: classData.name,
            startTime: classData.startTime,
          },
        },
      }),
    }
  )

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

## 5. Testing

### Firebase Console Test

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter:
   - Title: "Nueva clase disponible"
   - Body: "Crossfit a las 6:00 AM. ¡Reserva ahora!"
4. Click "Send test message"
5. Enter your device's FCM token (from app logs)
6. Send

### Using FCM HTTP API

```bash
curl -X POST \
  'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": {
      "topic": "gym_YOUR_GYM_ID",
      "notification": {
        "title": "Nueva clase disponible",
        "body": "Crossfit a las 6:00 AM. ¡Reserva ahora!"
      },
      "data": {
        "type": "class_created",
        "classId": "uuid-here",
        "gymId": "gym-uuid",
        "title": "Crossfit",
        "startTime": "2026-01-16T06:00:00Z"
      }
    }
  }'
```

### Check FCM Token

Add temporarily to see token in logs:

```dart
final token = await NotificationService.instance.getToken();
print('FCM Token: $token');
```

## 6. Payload Contract

### Required Data Fields

| Field | Type | Description |
|-------|------|-------------|
| type | string | Notification type (class_created, class_updated, etc.) |
| classId | string | UUID of the class |
| gymId | string | UUID of the gym/organization |
| title | string | Class name |
| startTime | string | ISO 8601 datetime |

### Notification Types

| Type | Description |
|------|-------------|
| class_created | New class added to schedule |
| class_updated | Class time/details changed |
| class_cancelled | Class was cancelled |
| class_reminder | Reminder before class starts |
| booking_confirmed | User's booking was confirmed |
| booking_cancelled | User's booking was cancelled |
| announcement | General gym announcement |

## 7. Troubleshooting

### Common Issues

1. **No notifications on iOS Simulator**
   - Push notifications don't work on iOS Simulator
   - Use a physical device for testing

2. **Token is null**
   - Check Firebase is properly initialized
   - Ensure permissions are granted
   - Check network connectivity

3. **Notifications not showing in foreground**
   - This is expected behavior - we handle it with in-app banner
   - The local notification should appear in system tray

4. **Background handler not called**
   - Ensure handler is top-level function
   - Check `@pragma('vm:entry-point')` annotation

5. **Android channel not created**
   - Run app once to create channels
   - Check LogCat for errors

### Debug Logging

Enable verbose logging:

```dart
FirebaseMessaging.onMessage.listen((message) {
  print('=== FOREGROUND MESSAGE ===');
  print('ID: ${message.messageId}');
  print('Data: ${message.data}');
  print('Notification: ${message.notification?.title}');
  print('========================');
});
```

## 8. Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        PUSH NOTIFICATION FLOW                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐      ┌─────────┐      ┌──────────────────────────┐ │
│  │ Backend │ ───► │   FCM   │ ───► │     GymGo Mobile App     │ │
│  └─────────┘      └─────────┘      └──────────────────────────┘ │
│       │                                       │                  │
│       │                            ┌──────────┴──────────┐      │
│       │                            │                     │      │
│       ▼                            ▼                     ▼      │
│  ┌─────────┐              ┌─────────────┐      ┌─────────────┐  │
│  │ Topics  │              │ Foreground  │      │ Background  │  │
│  │gym_<id> │              │   Handler   │      │   Handler   │  │
│  └─────────┘              └─────────────┘      └─────────────┘  │
│                                   │                     │       │
│                                   ▼                     ▼       │
│                          ┌─────────────┐      ┌─────────────┐   │
│                          │ In-App      │      │ System      │   │
│                          │ Banner      │      │ Notification│   │
│                          │ + Local     │      │             │   │
│                          │ Notification│      │             │   │
│                          └─────────────┘      └─────────────┘   │
│                                   │                     │       │
│                                   └──────────┬──────────┘       │
│                                              │                  │
│                                              ▼                  │
│                                    ┌─────────────────┐          │
│                                    │ Notification    │          │
│                                    │ Router          │          │
│                                    │ (Navigation)    │          │
│                                    └─────────────────┘          │
│                                              │                  │
│                                              ▼                  │
│                                    ┌─────────────────┐          │
│                                    │ Classes Screen  │          │
│                                    │ (Refreshed)     │          │
│                                    └─────────────────┘          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Files Created

| File | Purpose |
|------|---------|
| `lib/main.dart` | Firebase init, background handler |
| `lib/app.dart` | In-app notification listener |
| `lib/core/config/notification_channels.dart` | Android channels config |
| `lib/core/services/notification_service.dart` | FCM + local notifications |
| `lib/core/services/notification_router.dart` | Tap navigation handler |
| `lib/core/services/push_token_repository.dart` | Token management |
| `lib/shared/providers/notification_providers.dart` | Riverpod providers |
| `lib/shared/ui/components/notification_banner.dart` | In-app alert UI |
