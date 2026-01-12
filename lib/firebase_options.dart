// File generated manually based on Firebase configuration
// FlutterFire CLI failed due to missing xcodeproj gem

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYmv4Cj8M5pz3q8Nh4z_umN8Rmh5wQjqc',
    appId: '1:76038488450:android:7139f878abf48566c30f9b',
    messagingSenderId: '76038488450',
    projectId: 'gymgo-e8098',
    storageBucket: 'gymgo-e8098.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDS8z9lVcjrp_0fddHV15mS9jyJ4tKoXvk',
    appId: '1:76038488450:ios:2f84c1ad37fb7b1ec30f9b',
    messagingSenderId: '76038488450',
    projectId: 'gymgo-e8098',
    storageBucket: 'gymgo-e8098.firebasestorage.app',
    iosBundleId: 'com.gymgo.gymgoMobile',
  );
}
