import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'account_service.dart';
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

  static Future<String?> currentUserStatus() async {
    await FirebaseService.initialize();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final status = snapshot.data()?['status'];
    return status is String ? status : null;
  }

  static Future<bool> currentUserIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return AccountService.isAdmin(user.uid);
  }

  // Creates a login and submits its professional account application.
  static Future<User> createAccount({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> applicationDetails,
    Uint8List? cvBytes,
    String? cvFileName,
    String? existingCvPath,
    void Function(String stage, double? uploadProgress)? onProgress,
  }) async {
    await FirebaseService.initialize();
    if (!const {
      'Tradesperson',
      'Employer / Contractor',
      'Trainer / Assessor',
    }.contains(role)) {
      throw const AuthProfileException(
        'This account type cannot be created through public registration.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final existingUser = FirebaseAuth.instance.currentUser;
    final user = existingUser?.email?.toLowerCase() == normalizedEmail
        ? existingUser!
        : (await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )).user;
    if (user == null) {
      throw const AuthProfileException('Firebase did not return the new user.');
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final applicationRef = firestore
        .collection('account_applications')
        .doc(user.uid);
    try {
      onProgress?.call('Preparing your account', null);

      final parallelResults = await Future.wait<Object?>([
        userRef.get(),
        user.updateDisplayName(fullName.trim()).then<Object?>((_) => null),
      ]);
      final userSnapshot =
          parallelResults.first as DocumentSnapshot<Map<String, dynamic>>;
      if (!userSnapshot.exists) {
        await userRef.set({
          'fullName': fullName.trim(),
          'email': normalizedEmail,
          'role': role,
          'status': 'application_draft',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (userSnapshot.data()?['status'] != 'application_draft') {
        throw const AuthProfileException(
          'This login already has an account profile. Please sign in instead.',
        );
      } else {
        await userRef.update({
          'fullName': fullName.trim(),
          'email': normalizedEmail,
        });
      }

      onProgress?.call('Saving your application', null);
      await applicationRef.set({
        'fullName': fullName.trim(),
        'email': normalizedEmail,
        'role': role,
        'details': applicationDetails,
        'status': 'draft',
        'cvPath': existingCvPath,
        'cvFileName': cvFileName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      var cvPath = existingCvPath;
      if (cvBytes != null && cvFileName != null) {
        final safeName = cvFileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        cvPath =
            'account_applications/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
        final extension = safeName.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'pdf' => 'application/pdf',
          'doc' => 'application/msword',
          'docx' =>
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          _ => 'application/octet-stream',
        };
        onProgress?.call('Uploading your CV', 0);
        final uploadTask = FirebaseStorage.instance
            .ref(cvPath)
            .putData(cvBytes, SettableMetadata(contentType: contentType));
        final progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.totalBytes == 0
              ? null
              : snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress?.call('Uploading your CV', progress);
        }, onError: (_) {});
        try {
          // A missing/unprovisioned bucket can leave the SDK retrying without
          // ever advancing the transfer. Fail clearly instead of spinning forever.
          await uploadTask.timeout(const Duration(seconds: 60));
        } on TimeoutException {
          await uploadTask.cancel();
          throw const AuthProfileException(
            'CV upload timed out. In Firebase Console, finish Storage setup '
            'and create the default bucket, then deploy Storage rules and retry.',
          );
        } finally {
          await progressSubscription.cancel();
        }
      }

      onProgress?.call('Sending application for review', null);
      final batch = firestore.batch();
      batch.update(applicationRef, {
        'status': 'pending_review',
        'cvPath': cvPath,
        'cvFileName': cvFileName,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(userRef, {
        'status': 'pending_review',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseAuthException catch (error) {
      throw AuthProfileException(
        'Your login was created, but the application could not be completed '
        '(${error.code}). You can sign in and complete setup later.',
      );
    } on FirebaseException catch (error) {
      throw AuthProfileException(
        'Your login exists, but submitting the application failed '
        '(${error.code}). ${error.message ?? 'Your saved draft can be retried.'}',
      );
    }
    return user;
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
    if (error.code == 'permission-denied') {
      return 'Firebase permission denied. Check that Firestore rules are deployed '
          'and that admins/{your Firebase Auth UID} exists.';
    }
    return 'Firebase is not ready (${error.code}). Add the Android '
        'google-services.json file and check Firebase setup.';
  }
  return 'Authentication error: $error';
}
