import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration for Mumbai Metro
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
      default:
        return web;
    }
  }

  // ==================== WEB CONFIG ====================
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBuJzVcUV4gugwySX3oi6GmymVhDjYlfP4', // Reusing Android API Key
    appId: 'PASTE_WEB_APP_ID_HERE_IF_NEEDED', // Only required if running on Chrome/Web
    messagingSenderId: '989207460958',
    projectId: 'pa-9-10-final',
    authDomain: 'pa-9-10-final.firebaseapp.com',
    storageBucket: 'pa-9-10-final.firebasestorage.app',
  );

  // ==================== ANDROID CONFIG ====================
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuJzVcUV4gugwySX3oi6GmymVhDjYlfP4',
    appId: '1:989207460958:android:29486f8656ff1851c048cf',
    messagingSenderId: '989207460958',
    projectId: 'pa-9-10-final',
    storageBucket: 'pa-9-10-final.firebasestorage.app',
  );

  // ==================== iOS CONFIG ====================
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY_HERE',
    appId: 'YOUR_IOS_APP_ID_HERE',
    messagingSenderId: '989207460958',
    projectId: 'pa-9-10-final',
    storageBucket: 'pa-9-10-final.firebasestorage.app',
    iosBundleId: 'com.example.final_mp_10',
  );
}
