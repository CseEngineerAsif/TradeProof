import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

// Handles sign-in, account creation, and password reset with Firebase.
class AuthService {
  AuthService._();

  // Signs in with an email address and password.
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    await FirebaseService.initialize();
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Looks up the signed-in user's account role in Firestore.
  static Future<String?> currentUserRole() async {
    await FirebaseService.initialize();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = snapshot.data()?['role'];
    return role is String ? role : null;
  }

  // Creates the login account and saves its profile details.
  static Future<UserCredential> createAccount({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    await FirebaseService.initialize();
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    final user = credential.user;
    if (user == null) {
      throw const AuthProfileException(
        'The account was created, but its user details were not returned.',
      );
    }

    try {
      // Save the profile details after Firebase creates the login account.
      await user.updateDisplayName(fullName.trim());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      throw AuthProfileException(
        'Your login account was created, but saving the profile failed '
        '(${error.code}). You can sign in and complete setup later.',
      );
    } on FirebaseException catch (error) {
      throw AuthProfileException(
        'Your login account was created, but saving the profile failed '
        '(${error.code}). Check Firestore setup/rules, then sign in again.',
      );
    }
    return credential;
  }

  // Asks Firebase to email a password reset link.
  static Future<void> sendPasswordReset(String email) async {
    await FirebaseService.initialize();
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  // Ends the current Firebase login session.
  static Future<void> signOut() async {
    await FirebaseService.initialize();
    await FirebaseAuth.instance.signOut();
  }
}

// Explains when the login account exists but its profile was not saved.
class AuthProfileException implements Exception {
  const AuthProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

// Turns Firebase errors into messages that are easier for users to understand.
String authErrorMessage(Object error) {
  if (error is AuthProfileException) return error.message;
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Choose a stronger password (at least 6 characters).',
      'network-request-failed' =>
        'Network error. Check your internet connection and try again.',
      'operation-not-allowed' =>
        'Email/password sign-in is not enabled in Firebase Authentication.',
      _ => error.message ?? 'Authentication failed (${error.code}).',
    };
  }
  if (error is FirebaseException) {
    return 'Firebase is not ready (${error.code}). Add the Android '
        'google-services.json file and check Firebase setup.';
  }
  return 'Authentication error: $error';
}
