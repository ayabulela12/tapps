import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', 
      defaultValue: 'AIzaSyB8mhR3UIV8vlu2wLpVbNDILNvTA_TjKCw'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN',
      defaultValue: 'tapps-4b1cb.firebaseapp.com'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID',
      defaultValue: 'tapps-4b1cb'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
      defaultValue: 'tapps-4b1cb.firebasestorage.app'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '792179995434'),
    appId: String.fromEnvironment('FIREBASE_APP_ID',
      defaultValue: '1:792179995434:web:36fab1334ebcb4bcc0e453'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID',
      defaultValue: 'G-FX1C0E04KY'),
  );
}
