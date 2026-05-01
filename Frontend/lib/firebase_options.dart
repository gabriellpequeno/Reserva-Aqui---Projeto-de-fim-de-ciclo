// Arquivo gerado por `flutterfire configure`.
// Substitua os valores PLACEHOLDER após configurar o projeto Firebase.
// Docs: https://firebase.google.com/docs/flutter/setup
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String vapidKey =
      'BFkRVCvk5gAEa7QH6xDTR-epwqSniL5ME7S0xISNfCHhzRnZspYOTsEpUATWfxEu9A_TifhqVNVavYD43g9Fm6I';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma. '
          'Execute `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhQw4awAFfnyYfx732B5LFZ59dZG4SZYo',
    authDomain: 'reservaqui-45478.firebaseapp.com',
    projectId: 'reservaqui-45478',
    storageBucket: 'reservaqui-45478.firebasestorage.app',
    messagingSenderId: '153552996154',
    appId: '1:153552996154:web:087f6a391c143e522f3203',
    measurementId: 'G-3NRWN1W7N4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBF6YT631fag63GhUsgs6dZA6vXL2jXbgw',
    appId: '1:153552996154:android:9a6a3b623df77cad2f3203',
    messagingSenderId: '153552996154',
    projectId: 'reservaqui-45478',
    storageBucket: 'reservaqui-45478.firebasestorage.app',
  );
}
