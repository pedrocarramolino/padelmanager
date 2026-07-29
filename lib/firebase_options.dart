import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
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
    apiKey: 'AIzaSyBHur-uvEAX4C0BSyMRZZPm5bgIAJPjLeU',
    appId: '1:211698693:web:ec7b31e7266f55d5ffc86c',
    messagingSenderId: '211698693',
    projectId: 'padel-app-4f2f3',
    authDomain: 'padel-app-4f2f3.firebaseapp.com',
    storageBucket: 'padel-app-4f2f3.firebasestorage.app',
    measurementId: 'G-05VN0NVHD2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2rEjDZ5qwIfLpnDX7XLxsreqZPudmDiI',
    appId: '1:211698693:android:ded1f42e97aec40dffc86c',
    messagingSenderId: '211698693',
    projectId: 'padel-app-4f2f3',
    storageBucket: 'padel-app-4f2f3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjzIShTJUTfvWvXDBj5U5R17Ld7IO6Emc',
    appId: '1:211698693:ios:1edf5e4e51dc3cc1ffc86c',
    messagingSenderId: '211698693',
    projectId: 'padel-app-4f2f3',
    storageBucket: 'padel-app-4f2f3.firebasestorage.app',
    iosClientId:
        '211698693-7rlod192l24d5032hnhqucu9sqgo6f7j.apps.googleusercontent.com',
    iosBundleId: 'com.example.padelManager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBjzIShTJUTfvWvXDBj5U5R17Ld7IO6Emc',
    appId: '1:211698693:ios:1edf5e4e51dc3cc1ffc86c',
    messagingSenderId: '211698693',
    projectId: 'padel-app-4f2f3',
    storageBucket: 'padel-app-4f2f3.firebasestorage.app',
    iosClientId:
        '211698693-7rlod192l24d5032hnhqucu9sqgo6f7j.apps.googleusercontent.com',
    iosBundleId: 'com.example.padelManager',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBHur-uvEAX4C0BSyMRZZPm5bgIAJPjLeU',
    appId: '1:211698693:web:5f5f39ae97d00203ffc86c',
    messagingSenderId: '211698693',
    projectId: 'padel-app-4f2f3',
    authDomain: 'padel-app-4f2f3.firebaseapp.com',
    storageBucket: 'padel-app-4f2f3.firebasestorage.app',
    measurementId: 'G-6VXXG3WLT0',
  );
}
