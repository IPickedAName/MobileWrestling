import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIza...',
    appId: '1:123456:android:abc123',
    messagingSenderId: '123456',
    projectId: 'wrestler-66b71',
    storageBucket: 'wrestler-66b71.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyBVoyZTImMuLP8In0-9B1sZHQsRjnTT4TY',
  appId: '1:6432039174:ios:f371f5c5696cb5bd94be87',
  messagingSenderId: '6432039174',
  projectId: 'wrestler-66b71',
  storageBucket: 'wrestler-66b71.firebasestorage.app',
  iosBundleId: 'com.example.wrestlerFantasyBooker',
);
}