import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

// Starts Firebase once so other services can safely use it.
class FirebaseService {
  FirebaseService._();

  static Future<void>? _initialization;

  static Future<void> initialize() {
    // Reuse an ongoing setup instead of starting Firebase twice.
    if (Firebase.apps.isNotEmpty) return Future<void>.value();
    return _initialization ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) {});
  }
}
