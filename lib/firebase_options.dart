// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAvyGfTrfGQNtNmGq5jeVVE8F5zvwLD60s',
    appId: '1:597873472110:web:1a7c1b4d40279ba8096c7f',
    messagingSenderId: '597873472110',
    projectId: 'pltu-pacitan',
    authDomain: 'pltu-pacitan.firebaseapp.com',
    storageBucket: 'pltu-pacitan.firebasestorage.app',
    measurementId: 'G-ZH8HFK9VTD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDpKOWgX-a201EZln4sP-HJIgbeeArApvs',
    appId: '1:597873472110:android:32008abb419fc95b096c7f',
    messagingSenderId: '597873472110',
    projectId: 'pltu-pacitan',
    storageBucket: 'pltu-pacitan.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkWUTzMJPJXIsatd-fH8uuWreh17xvwVc',
    appId: '1:597873472110:ios:be5c0044ada9d290096c7f',
    messagingSenderId: '597873472110',
    projectId: 'pltu-pacitan',
    storageBucket: 'pltu-pacitan.firebasestorage.app',
    iosBundleId: 'com.example.apkmonitoring',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDkWUTzMJPJXIsatd-fH8uuWreh17xvwVc',
    appId: '1:597873472110:ios:be5c0044ada9d290096c7f',
    messagingSenderId: '597873472110',
    projectId: 'pltu-pacitan',
    storageBucket: 'pltu-pacitan.firebasestorage.app',
    iosBundleId: 'com.example.apkmonitoring',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAvyGfTrfGQNtNmGq5jeVVE8F5zvwLD60s',
    appId: '1:597873472110:web:5d127bf1a4e2c391096c7f',
    messagingSenderId: '597873472110',
    projectId: 'pltu-pacitan',
    authDomain: 'pltu-pacitan.firebaseapp.com',
    storageBucket: 'pltu-pacitan.firebasestorage.app',
    measurementId: 'G-8DQ88S0EGE',
  );
}
