import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_service.dart';

class AccountApplication {
  const AccountApplication({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.details,
    this.cvPath,
    this.cvFileName,
    this.adminNote,
    this.meetingDate,
    this.meetingLink,
    this.meetingMessage,
  });

  factory AccountApplication.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final details = data['details'];
    return AccountApplication(
      uid: snapshot.id,
      fullName: data['fullName'] as String? ?? 'Unknown applicant',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      status: data['status'] as String? ?? 'application_draft',
      details: details is Map
          ? Map<String, dynamic>.from(details)
          : const <String, dynamic>{},
      cvPath: data['cvPath'] as String?,
      cvFileName: data['cvFileName'] as String?,
      adminNote: data['adminNote'] as String?,
      meetingDate: _readDate(data['meetingDate']),
      meetingLink: data['meetingLink'] as String?,
      meetingMessage: data['meetingMessage'] as String?,
    );
  }

  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final Map<String, dynamic> details;
  final String? cvPath;
  final String? cvFileName;
  final String? adminNote;
  final DateTime? meetingDate;
  final String? meetingLink;
  final String? meetingMessage;

  bool get isAwaitingReview =>
      status == 'pending_review' || status == 'interview_invited';
}

class ManagedAccount {
  const ManagedAccount({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
  });

  factory ManagedAccount.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ManagedAccount(
      uid: snapshot.id,
      fullName: data['fullName'] as String? ?? 'Unnamed account',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'Unknown role',
      status: data['status'] as String? ?? 'active',
    );
  }

  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String status;
}

class AccountService {
  AccountService._();

  static const _users = 'users';
  static const _applications = 'account_applications';
  static const _admins = 'admins';

  static Future<bool> isAdmin(String uid) async {
    await FirebaseService.initialize();
    final snapshot = await FirebaseFirestore.instance
        .collection(_admins)
        .doc(uid)
        .get();
    return snapshot.exists;
  }

  static Stream<List<AccountApplication>> watchApplications() {
    return FirebaseFirestore.instance
        .collection(_applications)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AccountApplication.fromSnapshot).toList()
                ..sort((a, b) => a.fullName.compareTo(b.fullName)),
        );
  }

  static Stream<AccountApplication?> watchApplication(String uid) {
    return FirebaseFirestore.instance
        .collection(_applications)
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists
              ? AccountApplication.fromSnapshot(snapshot)
              : null,
        );
  }

  static Stream<List<ManagedAccount>> watchAccounts() {
    return FirebaseFirestore.instance
        .collection(_users)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ManagedAccount.fromSnapshot).toList()
                ..sort((a, b) => a.fullName.compareTo(b.fullName)),
        );
  }

  static Future<void> reviewApplication({
    required AccountApplication application,
    required String status,
    String? note,
    DateTime? meetingDate,
    String? meetingLink,
    String? meetingMessage,
  }) async {
    if (!const {'active', 'rejected', 'interview_invited'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported review status');
    }

    final admin = await _requireAdmin();
    final firestore = FirebaseFirestore.instance;
    final applicationRef = firestore
        .collection(_applications)
        .doc(application.uid);
    final userRef = firestore.collection(_users).doc(application.uid);
    final now = FieldValue.serverTimestamp();
    final batch = firestore.batch();

    batch.update(applicationRef, {
      'status': status,
      'adminNote': note?.trim() ?? '',
      'reviewedBy': admin.uid,
      'reviewedAt': now,
      'updatedAt': now,
      if (status == 'interview_invited') ...{
        'meetingDate': meetingDate,
        'meetingLink': meetingLink?.trim() ?? '',
        'meetingMessage': meetingMessage?.trim() ?? '',
      },
    });
    batch.update(userRef, {'status': status, 'updatedAt': now});
    await batch.commit();
  }

  static Future<void> setAccountStatus(
    ManagedAccount account, {
    required String status,
  }) async {
    if (status != 'active' && status != 'suspended') {
      throw ArgumentError.value(status, 'status', 'Unsupported account status');
    }
    await _requireAdmin();

    final firestore = FirebaseFirestore.instance;
    final now = FieldValue.serverTimestamp();
    final batch = firestore.batch();
    batch.update(firestore.collection(_users).doc(account.uid), {
      'status': status,
      'updatedAt': now,
    });
    final applicationRef = firestore.collection(_applications).doc(account.uid);
    final application = await applicationRef.get();
    if (application.exists) {
      batch.update(applicationRef, {'status': status, 'updatedAt': now});
    }
    await batch.commit();
  }

  static Future<String> getCvDownloadUrl(String path) async {
    await _requireAdmin();
    return FirebaseStorage.instance.ref(path).getDownloadURL();
  }

  static Future<User> _requireAdmin() async {
    await FirebaseService.initialize();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !await isAdmin(user.uid)) {
      throw StateError('Admin access is required for this action.');
    }
    return user;
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
