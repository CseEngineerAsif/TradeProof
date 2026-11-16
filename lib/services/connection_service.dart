import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

// A marketplace post shown to people looking for work, courses, or services.
class MarketplacePost {
  const MarketplacePost({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerRole,
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.priceBdt,
  });

  // Creates a post object from one Firestore record.
  factory MarketplacePost.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return MarketplacePost(
      id: snapshot.id,
      ownerUid: data['ownerUid'] as String,
      ownerName: data['ownerName'] as String,
      ownerRole: data['ownerRole'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      category: data['category'] as String,
      description: data['description'] as String,
      status: data['status'] as String,
      createdAt: _readDate(data['createdAt']),
      priceBdt: data['priceBdt'] as int?,
    );
  }

  final String id;
  final String ownerUid;
  final String ownerName;
  final String ownerRole;
  final String type;
  final String title;
  final String category;
  final String description;
  final String status;
  final DateTime? createdAt;
  final int? priceBdt;

  // Chooses a button label based on the kind of post.
  String get actionLabel => switch (type) {
    'course' => 'Request enrollment',
    'job' => 'Apply for job',
    _ => 'Request service',
  };
}

// A request sent by one account to connect with another account's post.
class ConnectionRequest {
  const ConnectionRequest({
    required this.id,
    required this.postId,
    required this.type,
    required this.title,
    required this.ownerUid,
    required this.ownerName,
    required this.requesterUid,
    required this.requesterName,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.paymentStatus,
    this.amountBdt,
  });

  // Creates a request object from one Firestore record.
  factory ConnectionRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return ConnectionRequest(
      id: snapshot.id,
      postId: data['postId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      ownerUid: data['ownerUid'] as String,
      ownerName: data['ownerName'] as String,
      requesterUid: data['requesterUid'] as String,
      requesterName: data['requesterName'] as String,
      status: data['status'] as String,
      createdAt: _readDate(data['createdAt']),
      paymentMethod: data['paymentMethod'] as String?,
      paymentStatus: data['paymentStatus'] as String?,
      amountBdt: data['amountBdt'] as int?,
    );
  }

  final String id;
  final String postId;
  final String type;
  final String title;
  final String ownerUid;
  final String ownerName;
  final String requesterUid;
  final String requesterName;
  final String status;
  final DateTime? createdAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final int? amountBdt;

  // Finds the other person's name in this request.
  String otherPartyName(String currentUid) =>
      currentUid == ownerUid ? requesterName : ownerName;
}

// A single message sent inside an accepted connection.
class ConnectionMessage {
  const ConnectionMessage({
    required this.senderUid,
    required this.senderName,
    required this.text,
  });

  // Creates a message object from one Firestore record.
  factory ConnectionMessage.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return ConnectionMessage(
      senderUid: data['senderUid'] as String,
      senderName: data['senderName'] as String,
      text: data['text'] as String,
    );
  }

  final String senderUid;
  final String senderName;
  final String text;
}

// Reads and writes marketplace posts, requests, and connection messages.
class ConnectionService {
  ConnectionService._();

  static const _users = 'users';
  static const _posts = 'marketplace_posts';
  static const _requests = 'connection_requests';

  // Makes sure Firebase is ready before returning the database.
  static Future<FirebaseFirestore> _firestore() async {
    await FirebaseService.initialize();
    return FirebaseFirestore.instance;
  }

  // Returns the signed-in user or stops the action with an error.
  static User _requireUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to use account connections.');
    return user;
  }

  // Keeps the published marketplace posts updated as Firestore changes.
  static Stream<List<MarketplacePost>> watchPosts({String? type}) async* {
    final firestore = await _firestore();
    final query = firestore
        .collection(_posts)
        .where('status', isEqualTo: 'published');
    await for (final snapshot in query.snapshots()) {
      final posts =
          snapshot.docs
              .map(MarketplacePost.fromSnapshot)
              .where((post) => type == null || post.type == type)
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            );
      yield posts;
    }
  }

  // Saves a new marketplace post using the signed-in user's profile.
  static Future<void> publishPost({
    required String type,
    required String title,
    required String category,
    required String description,
    int? priceBdt,
  }) async {
    if (type == 'course' && (priceBdt == null || priceBdt <= 0)) {
      throw ArgumentError.value(
        priceBdt,
        'priceBdt',
        'Courses need a fee greater than zero.',
      );
    }
    final user = _requireUser();
    final firestore = await _firestore();
    final userSnapshot = await firestore.collection(_users).doc(user.uid).get();
    final data = userSnapshot.data();
    final ownerName = (data?['fullName'] as String?)?.trim();
    final ownerRole = (data?['role'] as String?)?.trim();
    if (ownerName == null ||
        ownerName.isEmpty ||
        ownerRole == null ||
        ownerRole.isEmpty) {
      throw StateError('Complete your account profile before publishing.');
    }
    await firestore.collection(_posts).add({
      'ownerUid': user.uid,
      'ownerName': ownerName,
      'ownerRole': ownerRole,
      'type': type,
      'title': title.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'status': 'published',
      'createdAt': FieldValue.serverTimestamp(),
      'priceBdt': ?priceBdt,
    });
  }

  // Creates or updates a basic service post for a tradesperson.
  static Future<void> ensureWorkerPost() async {
    final user = _requireUser();
    final firestore = await _firestore();
    final userSnapshot = await firestore.collection(_users).doc(user.uid).get();
    final data = userSnapshot.data();
    final ownerName = (data?['fullName'] as String?)?.trim();
    final ownerRole = (data?['role'] as String?)?.trim();
    if (ownerName == null ||
        ownerName.isEmpty ||
        ownerRole == null ||
        ownerRole.isEmpty) {
      return;
    }
    await firestore.collection(_posts).doc('worker_${user.uid}').set({
      'ownerUid': user.uid,
      'ownerName': ownerName,
      'ownerRole': ownerRole,
      'type': 'service',
      'title': '$ownerName · Tradesperson profile',
      'category': 'Tradesperson',
      'description':
          'Connect with $ownerName, a TradeProof tradesperson, to discuss '
          'verified trade services and availability.',
      'status': 'published',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Sends a request to the owner of a marketplace post.
  static Future<void> requestPost(
    MarketplacePost post, {
    String? paymentMethod,
    String? paymentStatus,
  }) async {
    final user = _requireUser();
    if (user.uid == post.ownerUid) {
      throw StateError('You cannot request access to your own post.');
    }
    if ((paymentMethod == null) != (paymentStatus == null)) {
      throw ArgumentError(
        'Payment method and payment status must be provided together.',
      );
    }
    if (paymentMethod != null &&
        (post.type != 'course' || post.priceBdt == null)) {
      throw StateError('This course does not have a payable fee set.');
    }
    final firestore = await _firestore();
    final requesterSnapshot = await firestore
        .collection(_users)
        .doc(user.uid)
        .get();
    final requesterName = (requesterSnapshot.data()?['fullName'] as String?)
        ?.trim();
    if (requesterName == null || requesterName.isEmpty) {
      throw StateError(
        'Complete your account profile before sending requests.',
      );
    }

    final requestRef = firestore
        .collection(_requests)
        .doc('${user.uid}-${post.id}');
    await firestore.runTransaction((transaction) async {
      final existing = await transaction.get(requestRef);
      if (existing.exists) {
        throw StateError('You already have a request for this post.');
      }
      transaction.set(requestRef, {
        'postId': post.id,
        'type': post.type,
        'title': post.title,
        'ownerUid': post.ownerUid,
        'ownerName': post.ownerName,
        'requesterUid': user.uid,
        'requesterName': requesterName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        if (paymentMethod != null) ...{
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentStatus,
          'amountBdt': post.priceBdt,
        },
      });
    });
  }

  // Resolves a real, published course before opening its checkout.
  static Future<MarketplacePost> findPublishedCourseByTitle(
    String title,
  ) async {
    final firestore = await _firestore();
    final snapshot = await firestore
        .collection(_posts)
        .where('status', isEqualTo: 'published')
        .get();
    final matches = snapshot.docs
        .map(MarketplacePost.fromSnapshot)
        .where((post) => post.type == 'course' && post.title == title)
        .toList();
    if (matches.isEmpty) {
      throw StateError(
        'This course is a sample. Choose a course published by a TradeProof account.',
      );
    }
    if (matches.length > 1) {
      throw StateError(
        'More than one account published this course. Choose it from the marketplace.',
      );
    }
    final course = matches.single;
    if (course.priceBdt == null || course.priceBdt! <= 0) {
      throw StateError(
        'The course fee is not set up for checkout. Ask the trainer to update the course.',
      );
    }
    return course;
  }

  // Finds a real published post before sending a request for a featured item.
  static Future<void> requestPublishedPostByTitle({
    required String title,
    required String type,
  }) async {
    final firestore = await _firestore();
    final snapshot = await firestore
        .collection(_posts)
        .where('status', isEqualTo: 'published')
        .get();
    final matches = snapshot.docs
        .map(MarketplacePost.fromSnapshot)
        .where(
          (post) =>
              post.type == type &&
              (post.title == title || post.ownerName == title),
        )
        .toList();
    if (matches.isEmpty) {
      throw StateError(
        'This featured item is a sample. Choose a post published by a TradeProof account.',
      );
    }
    if (matches.length > 1) {
      throw StateError(
        'More than one account published this title. Choose the owner from the marketplace.',
      );
    }
    await requestPost(matches.single);
  }

  // Streams requests sent to or received by the signed-in user.
  static Stream<List<ConnectionRequest>> watchRequests({
    required bool incoming,
  }) async* {
    final user = _requireUser();
    final firestore = await _firestore();
    final field = incoming ? 'ownerUid' : 'requesterUid';
    await for (final snapshot
        in firestore
            .collection(_requests)
            .where(field, isEqualTo: user.uid)
            .snapshots()) {
      final requests =
          snapshot.docs.map(ConnectionRequest.fromSnapshot).toList()..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
      yield requests;
    }
  }

  // Lets the post owner accept or reject a waiting request.
  static Future<void> respondToRequest(
    ConnectionRequest request, {
    required bool accept,
  }) async {
    final user = _requireUser();
    if (request.ownerUid != user.uid || request.status != 'pending') {
      throw StateError('This request can no longer be updated.');
    }
    final firestore = await _firestore();
    await firestore.collection(_requests).doc(request.id).update({
      'status': accept ? 'accepted' : 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Lets the course owner confirm receipt of an offline payment.
  static Future<void> confirmOfflinePayment(ConnectionRequest request) async {
    final user = _requireUser();
    if (request.ownerUid != user.uid ||
        request.type != 'course' ||
        !['cash', 'bank_transfer'].contains(request.paymentMethod) ||
        ![
          'awaiting_cash',
          'awaiting_bank_transfer',
        ].contains(request.paymentStatus) ||
        request.status != 'accepted') {
      throw StateError('This offline payment cannot be confirmed.');
    }
    final firestore = await _firestore();
    await firestore.collection(_requests).doc(request.id).update({
      'paymentStatus': 'confirmed_offline',
      'paymentConfirmedAt': FieldValue.serverTimestamp(),
    });
  }

  // Streams messages in a connection conversation.
  static Stream<List<ConnectionMessage>> watchMessages(
    String requestId,
  ) async* {
    final firestore = await _firestore();
    await for (final snapshot
        in firestore
            .collection(_requests)
            .doc(requestId)
            .collection('messages')
            .orderBy('createdAt')
            .snapshots()) {
      yield snapshot.docs.map(ConnectionMessage.fromSnapshot).toList();
    }
  }

  // Saves a message when the connection has been accepted.
  static Future<void> sendMessage(
    ConnectionRequest request,
    String text,
  ) async {
    final user = _requireUser();
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;
    if (request.status != 'accepted' ||
        (user.uid != request.ownerUid && user.uid != request.requesterUid)) {
      throw StateError('Messaging is available after the owner accepts.');
    }
    final firestore = await _firestore();
    final userSnapshot = await firestore.collection(_users).doc(user.uid).get();
    final senderName =
        (userSnapshot.data()?['fullName'] as String?)?.trim() ?? user.uid;
    await firestore
        .collection(_requests)
        .doc(request.id)
        .collection('messages')
        .add({
          'senderUid': user.uid,
          'senderName': senderName,
          'text': normalizedText,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}

// Converts Firestore date values into Dart dates.
DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
