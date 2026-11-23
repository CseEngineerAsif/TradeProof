import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;

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

class DemoAccount {
  const DemoAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;
}

// Reads and writes marketplace posts, requests, and connection messages.
class ConnectionService {
  ConnectionService._();

  static const _users = 'users';
  static const _posts = 'marketplace_posts';
  static const _requests = 'connection_requests';

  static final _demoChanges = StreamController<int>.broadcast();
  static DemoAccount? _demoAccount;
  static int _demoRevision = 0;
  static int _demoId = 0;
  static final List<MarketplacePost> _demoPosts = _seedDemoPosts();
  static final List<ConnectionRequest> _demoRequests = _seedDemoRequests();
  static final Map<String, List<ConnectionMessage>> _demoMessages = {
    'demo-course-chat': [
      const ConnectionMessage(
        senderUid: 'demo-trainer',
        senderName: 'Dave Vance',
        text: 'Welcome! I will share the course schedule here.',
      ),
    ],
  };

  static bool get isDemoSession => _demoAccount != null;

  static bool get isSignedIn =>
      isDemoSession ||
      (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null);

  static String? get currentUserId {
    if (_demoAccount != null) return _demoAccount!.id;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static String? get currentUserName {
    if (_demoAccount != null) return _demoAccount!.name;
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : user?.email;
  }

  static String? get currentUserEmail {
    if (_demoAccount != null) return _demoAccount!.email;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.email;
  }

  static DemoAccount? get demoAccount => _demoAccount;

  static void beginDemoSession(String role) {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole.contains('admin')) {
      _demoAccount = const DemoAccount(
        id: 'demo-admin',
        name: 'Demo Administrator',
        email: 'admin@demo.tradeproof',
        role: 'Admin',
      );
    } else if (normalizedRole.contains('employer')) {
      _demoAccount = const DemoAccount(
        id: 'demo-employer',
        name: 'David Carter',
        email: 'employer@demo.tradeproof',
        role: 'Employer / Contractor',
      );
    } else if (normalizedRole.contains('trainer')) {
      _demoAccount = const DemoAccount(
        id: 'demo-trainer',
        name: 'Dave Vance',
        email: 'trainer@demo.tradeproof',
        role: 'Trainer / Assessor',
      );
    } else if (normalizedRole.contains('client') ||
        normalizedRole.contains('user')) {
      _demoAccount = const DemoAccount(
        id: 'demo-client',
        name: 'Sarah Jenkins',
        email: 'client@demo.tradeproof',
        role: 'General User',
      );
    } else {
      _demoAccount = const DemoAccount(
        id: 'demo-worker',
        name: 'Md. Asif Hasan',
        email: 'worker@demo.tradeproof',
        role: 'Tradesperson',
      );
    }
    _emitDemoChange();
  }

  static void endDemoSession() {
    if (_demoAccount == null) return;
    _demoAccount = null;
    _emitDemoChange();
  }

  static void _emitDemoChange() {
    _demoChanges.add(++_demoRevision);
  }

  static Stream<List<MarketplacePost>> _watchDemoPosts({
    String? type,
    String? ownerUid,
  }) async* {
    List<MarketplacePost> currentPosts() {
      final posts =
          _demoPosts
              .where(
                (post) =>
                    post.status == 'published' &&
                    (type == null || post.type == type) &&
                    (ownerUid == null || post.ownerUid == ownerUid),
              )
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            );
      return posts;
    }

    yield currentPosts();
    await for (final _ in _demoChanges.stream) {
      yield currentPosts();
    }
  }

  static Stream<List<MarketplacePost>> _watchMyDemoPosts({
    String? type,
    required String ownerUid,
  }) async* {
    List<MarketplacePost> currentPosts() {
      final posts =
          _demoPosts
              .where(
                (post) =>
                    post.ownerUid == ownerUid &&
                    (type == null || post.type == type),
              )
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            );
      return posts;
    }

    yield currentPosts();
    await for (final _ in _demoChanges.stream) {
      yield currentPosts();
    }
  }

  static Stream<List<ConnectionRequest>> _watchDemoRequests({
    required String userId,
    required bool incoming,
  }) async* {
    List<ConnectionRequest> currentRequests() {
      final requests =
          _demoRequests
              .where(
                (request) => incoming
                    ? request.ownerUid == userId
                    : request.requesterUid == userId,
              )
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            );
      return requests;
    }

    yield currentRequests();
    await for (final _ in _demoChanges.stream) {
      yield currentRequests();
    }
  }

  static Stream<List<ConnectionMessage>> _watchDemoMessages(
    String requestId,
  ) async* {
    final requests = _demoRequests.where((item) => item.id == requestId);
    if (requests.length != 1 ||
        requests.single.status != 'accepted' ||
        (_demoAccount!.id != requests.single.ownerUid &&
            _demoAccount!.id != requests.single.requesterUid)) {
      throw StateError(
        'Messaging is only available to participants of an accepted request.',
      );
    }
    List<ConnectionMessage> currentMessages() =>
        List<ConnectionMessage>.unmodifiable(
          _demoMessages[requestId] ?? const <ConnectionMessage>[],
        );

    yield currentMessages();
    await for (final _ in _demoChanges.stream) {
      yield currentMessages();
    }
  }

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
    if (_demoAccount != null) {
      yield* _watchDemoPosts(type: type);
      return;
    }
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

  // Streams posts owned by the signed-in user, including closed posts.
  static Stream<List<MarketplacePost>> watchMyPosts({String? type}) async* {
    if (_demoAccount != null) {
      yield* _watchMyDemoPosts(type: type, ownerUid: _demoAccount!.id);
      return;
    }
    final user = _requireUser();
    final firestore = await _firestore();
    await for (final snapshot
        in firestore
            .collection(_posts)
            .where('ownerUid', isEqualTo: user.uid)
            .snapshots()) {
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
    if (_demoAccount != null) {
      final owner = _demoAccount!;
      final existingIndex = _demoPosts.indexWhere(
        (post) =>
            post.ownerUid == owner.id &&
            post.type == type &&
            post.title == title.trim(),
      );
      final existingPost = existingIndex < 0 ? null : _demoPosts[existingIndex];
      final post = MarketplacePost(
        id: existingPost?.id ?? 'demo-post-${_demoId++}',
        ownerUid: owner.id,
        ownerName: owner.name,
        ownerRole: owner.role,
        type: type,
        title: title.trim(),
        category: category.trim(),
        description: description.trim(),
        status: 'published',
        createdAt: existingPost?.createdAt ?? DateTime.now(),
        priceBdt: priceBdt,
      );
      if (existingIndex < 0) {
        _demoPosts.insert(0, post);
      } else {
        _demoPosts[existingIndex] = post;
      }
      _emitDemoChange();
      return;
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

  // Lets a post owner stop accepting new requests for one of their posts.
  static Future<void> closePost(MarketplacePost post) async {
    if (_demoAccount != null) {
      if (post.ownerUid != _demoAccount!.id || post.status != 'published') {
        throw StateError('This post can no longer be closed.');
      }
      final postIndex = _demoPosts.indexWhere((item) => item.id == post.id);
      if (postIndex < 0) throw StateError('This post is no longer available.');
      final currentPost = _demoPosts[postIndex];
      if (currentPost.status != 'published') {
        throw StateError('This post can no longer be closed.');
      }
      _demoPosts[postIndex] = MarketplacePost(
        id: currentPost.id,
        ownerUid: currentPost.ownerUid,
        ownerName: currentPost.ownerName,
        ownerRole: currentPost.ownerRole,
        type: currentPost.type,
        title: currentPost.title,
        category: currentPost.category,
        description: currentPost.description,
        status: 'closed',
        createdAt: currentPost.createdAt,
        priceBdt: currentPost.priceBdt,
      );
      _emitDemoChange();
      return;
    }
    final user = _requireUser();
    if (post.ownerUid != user.uid || post.status != 'published') {
      throw StateError('This post can no longer be closed.');
    }
    final firestore = await _firestore();
    await firestore.collection(_posts).doc(post.id).update({
      'status': 'closed',
    });
  }

  // Creates or updates a basic service post for a tradesperson.
  static Future<void> ensureWorkerPost() async {
    if (_demoAccount != null) {
      if (_demoAccount!.role != 'Tradesperson' ||
          _demoPosts.any(
            (post) =>
                post.ownerUid == _demoAccount!.id && post.type == 'service',
          )) {
        return;
      }
      final owner = _demoAccount!;
      _demoPosts.insert(
        0,
        MarketplacePost(
          id: 'demo-post-${_demoId++}',
          ownerUid: owner.id,
          ownerName: owner.name,
          ownerRole: owner.role,
          type: 'service',
          title: '${owner.name} · Tradesperson profile',
          category: 'Tradesperson',
          description:
              'Connect with ${owner.name}, a TradeProof tradesperson, to '
              'discuss verified trade services and availability.',
          status: 'published',
          createdAt: DateTime.now(),
        ),
      );
      _emitDemoChange();
      return;
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
    if (_demoAccount != null) {
      final user = _demoAccount!;
      if (user.id == post.ownerUid) {
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
      final livePost = _demoPosts.where((item) => item.id == post.id);
      if (livePost.isEmpty ||
          livePost.single.status != 'published' ||
          livePost.single.ownerUid != post.ownerUid) {
        throw StateError('This post is no longer available.');
      }
      final requestId = '${user.id}-${post.id}';
      if (_demoRequests.any((request) => request.id == requestId)) {
        throw StateError('You already have a request for this post.');
      }
      _demoRequests.insert(
        0,
        ConnectionRequest(
          id: requestId,
          postId: post.id,
          type: post.type,
          title: post.title,
          ownerUid: post.ownerUid,
          ownerName: post.ownerName,
          requesterUid: user.id,
          requesterName: user.name,
          status: 'pending',
          createdAt: DateTime.now(),
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
          amountBdt: paymentMethod == null ? null : post.priceBdt,
        ),
      );
      _emitDemoChange();
      return;
    }
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
    if (_demoAccount != null) {
      final matches = _demoPosts
          .where(
            (post) =>
                post.status == 'published' &&
                post.type == 'course' &&
                post.title == title,
          )
          .toList();
      if (matches.isEmpty) {
        throw StateError('No published demo course matches "$title".');
      }
      if (matches.length > 1) {
        throw StateError(
          'More than one account published this course. Choose it from the marketplace.',
        );
      }
      final course = matches.single;
      if (course.priceBdt == null || course.priceBdt! <= 0) {
        throw StateError('This course does not have a payable fee set.');
      }
      return course;
    }
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
    if (_demoAccount != null) {
      final matches = _demoPosts
          .where(
            (post) =>
                post.status == 'published' &&
                post.type == type &&
                (post.title == title || post.ownerName == title),
          )
          .toList();
      if (matches.isEmpty) {
        throw StateError('No published demo post matches "$title".');
      }
      if (matches.length > 1) {
        throw StateError(
          'More than one account published this title. Choose the owner from the marketplace.',
        );
      }
      await requestPost(matches.single);
      return;
    }
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
    if (_demoAccount != null) {
      yield* _watchDemoRequests(userId: _demoAccount!.id, incoming: incoming);
      return;
    }
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
    if (_demoAccount != null) {
      if (request.ownerUid != _demoAccount!.id || request.status != 'pending') {
        throw StateError('This request can no longer be updated.');
      }
      final index = _demoRequests.indexWhere((item) => item.id == request.id);
      if (index < 0) throw StateError('This request is no longer available.');
      final currentRequest = _demoRequests[index];
      if (currentRequest.status != 'pending') {
        throw StateError('This request can no longer be updated.');
      }
      _demoRequests[index] = _copyRequest(
        currentRequest,
        status: accept ? 'accepted' : 'rejected',
      );
      _emitDemoChange();
      return;
    }
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
    if (_demoAccount != null) {
      if (request.ownerUid != _demoAccount!.id ||
          request.type != 'course' ||
          !['cash', 'bank_transfer'].contains(request.paymentMethod) ||
          ![
            'awaiting_cash',
            'awaiting_bank_transfer',
          ].contains(request.paymentStatus) ||
          request.status != 'accepted') {
        throw StateError('This offline payment cannot be confirmed.');
      }
      final index = _demoRequests.indexWhere((item) => item.id == request.id);
      if (index < 0) throw StateError('This request is no longer available.');
      final currentRequest = _demoRequests[index];
      if (currentRequest.status != 'accepted' ||
          ![
            'awaiting_cash',
            'awaiting_bank_transfer',
          ].contains(currentRequest.paymentStatus)) {
        throw StateError('This offline payment cannot be confirmed.');
      }
      _demoRequests[index] = _copyRequest(
        currentRequest,
        paymentStatus: 'confirmed_offline',
      );
      _emitDemoChange();
      return;
    }
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
    if (_demoAccount != null) {
      yield* _watchDemoMessages(requestId);
      return;
    }
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
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;
    if (_demoAccount != null) {
      final user = _demoAccount!;
      final currentRequests = _demoRequests.where(
        (item) => item.id == request.id,
      );
      if (currentRequests.length != 1 ||
          currentRequests.single.status != 'accepted' ||
          (user.id != currentRequests.single.ownerUid &&
              user.id != currentRequests.single.requesterUid)) {
        throw StateError('Messaging is available after the owner accepts.');
      }
      (_demoMessages[request.id] ??= <ConnectionMessage>[]).add(
        ConnectionMessage(
          senderUid: user.id,
          senderName: user.name,
          text: normalizedText,
        ),
      );
      _emitDemoChange();
      return;
    }
    final user = _requireUser();
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

  static ConnectionRequest _copyRequest(
    ConnectionRequest request, {
    String? status,
    String? paymentStatus,
  }) => ConnectionRequest(
    id: request.id,
    postId: request.postId,
    type: request.type,
    title: request.title,
    ownerUid: request.ownerUid,
    ownerName: request.ownerName,
    requesterUid: request.requesterUid,
    requesterName: request.requesterName,
    status: status ?? request.status,
    createdAt: request.createdAt,
    paymentMethod: request.paymentMethod,
    paymentStatus: paymentStatus ?? request.paymentStatus,
    amountBdt: request.amountBdt,
  );
}

List<MarketplacePost> _seedDemoPosts() {
  final now = DateTime.now();
  return [
    MarketplacePost(
      id: 'demo-job-lead-electrician',
      ownerUid: 'demo-employer',
      ownerName: 'David Carter',
      ownerRole: 'Employer / Contractor',
      type: 'job',
      title: 'Lead Commercial Electrician',
      category: 'Electrical System / Smart Grid',
      description:
          'Join a commercial electrical project. Gold L3 verification and '
          'OSHA-30 safety training are preferred.',
      status: 'published',
      createdAt: now,
    ),
    MarketplacePost(
      id: 'demo-service-asif',
      ownerUid: 'demo-worker',
      ownerName: 'Md. Asif Hasan',
      ownerRole: 'Tradesperson',
      type: 'service',
      title: 'Md. Asif Hasan · Tradesperson profile',
      category: 'Electrical',
      description:
          'Master Electrician focused on safe, compliant residential and '
          'industrial wiring. Skills include solar and EV charging.',
      status: 'published',
      createdAt: now,
    ),
    MarketplacePost(
      id: 'demo-course-electrical-safety',
      ownerUid: 'demo-trainer',
      ownerName: 'Dave Vance',
      ownerRole: 'Trainer / Assessor',
      type: 'course',
      title: 'Electrical Installation & Safety',
      category: 'Electrical',
      description: '6 weeks · Course fee: ৳2,500',
      status: 'published',
      createdAt: now,
      priceBdt: 2500,
    ),
  ];
}

List<ConnectionRequest> _seedDemoRequests() => [
  ConnectionRequest(
    id: 'demo-application-lead-electrician',
    postId: 'demo-job-lead-electrician',
    type: 'job',
    title: 'Lead Commercial Electrician',
    ownerUid: 'demo-employer',
    ownerName: 'David Carter',
    requesterUid: 'demo-worker',
    requesterName: 'Md. Asif Hasan',
    status: 'pending',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  ConnectionRequest(
    id: 'demo-service-request-asif',
    postId: 'demo-service-asif',
    type: 'service',
    title: 'Md. Asif Hasan · Tradesperson profile',
    ownerUid: 'demo-worker',
    ownerName: 'Md. Asif Hasan',
    requesterUid: 'demo-client',
    requesterName: 'Sarah Jenkins',
    status: 'pending',
    createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
  ),
  ConnectionRequest(
    id: 'demo-course-chat',
    postId: 'demo-course-electrical-safety',
    type: 'course',
    title: 'Electrical Installation & Safety',
    ownerUid: 'demo-trainer',
    ownerName: 'Dave Vance',
    requesterUid: 'demo-client',
    requesterName: 'Sarah Jenkins',
    status: 'accepted',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// Converts Firestore date values into Dart dates.
DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
