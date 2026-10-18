import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

typedef Doc = Map<String, dynamic>;

class AppUser {
  final String id, name, email, role;
  const AppUser(this.id, this.name, this.email, this.role);
}

/// Tamper-evident credential seal: SHA-256 over the credential fields.
String credHash(String name, String holder, String issuer, String date) =>
    sha256.convert(utf8.encode([name, holder, issuer, date].join('|'))).toString();

String errText(Object e) =>
    e is FirebaseAuthException ? (e.message ?? e.code) : e.toString().replaceFirst('Exception: ', '');

abstract class Repo {
  final ValueNotifier<AppUser?> session = ValueNotifier<AppUser?>(null);
  bool get isFirebase;
  Future<void> signIn(String email, String pass);
  Future<void> register(String name, String email, String pass, String role);
  Future<void> demoLogin(String role);
  Future<void> signOut();
  Stream<List<Doc>> watch(String col);
  Future<void> add(String col, Doc data);
  Future<void> update(String col, String id, Doc data);
  Future<String?> uploadImage(String path);
}

late Repo repo;
String get me => repo.session.value?.name ?? '';

/// Uses Firebase when configured (flutterfire configure), otherwise Demo Mode.
Future<Repo> createRepo() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final r = FirebaseRepo();
    await r.restore();
    return r;
  } catch (e) {
    debugPrint('Demo mode (Firebase not configured): $e');
    return DemoRepo();
  }
}

/* ------------------------- Firebase implementation ------------------------- */
class FirebaseRepo extends Repo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  bool get isFirebase => true;

  Future<void> restore() async {
    final u = _auth.currentUser;
    if (u != null) await _load(u.uid, u.email ?? '');
  }

  Future<void> _load(String uid, String email) async {
    final s = await _db.collection('users').doc(uid).get();
    final d = s.data();
    session.value = AppUser(uid, (d?['name'] ?? email).toString(), email, (d?['role'] ?? 'worker').toString());
  }

  @override
  Future<void> signIn(String email, String pass) async {
    final c = await _auth.signInWithEmailAndPassword(email: email, password: pass);
    await _load(c.user!.uid, email);
  }

  @override
  Future<void> register(String name, String email, String pass, String role) async {
    final c = await _auth.createUserWithEmailAndPassword(email: email, password: pass);
    final uid = c.user!.uid;
    await _db.collection('users').doc(uid).set({'name': name, 'email': email, 'role': role});
    if (role == 'worker') {
      await _db.collection('workers').doc(uid).set({
        'name': name, 'role': 'Tradesperson', 'exp': 0, 'rating': 0, 'match': 0,
        'loc': '', 'about': 'New TradeProof member.', 'tags': <String>[], 'skills': <String>[],
      });
    }
    session.value = AppUser(uid, name, email, role);
  }

  @override
  Future<void> demoLogin(String role) async => throw Exception('Demo access is only available in Demo Mode.');

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    session.value = null;
  }

  @override
  Stream<List<Doc>> watch(String col) => _db.collection(col).snapshots().map((q) {
        final l = q.docs.map<Doc>((d) => {...d.data(), 'id': d.id}).toList();
        l.sort((a, b) => ((b['ts'] ?? 0) as num).compareTo((a['ts'] ?? 0) as num));
        return l;
      });

  @override
  Future<void> add(String col, Doc data) async {
    await _db.collection(col).add({...data, 'ts': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Future<void> update(String col, String id, Doc data) => _db.collection(col).doc(id).update(data);

  @override
  Future<String?> uploadImage(String path) async {
    final uid = session.value?.id ?? 'anon';
    final ref = FirebaseStorage.instance.ref('portfolio/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(path));
    return ref.getDownloadURL();
  }
}

/* --------------------------- Demo implementation --------------------------- */
class DemoRepo extends Repo {
  final Map<String, Map<String, String>> _acc = {};
  final Map<String, List<Doc>> _db = _seed();
  final Map<String, StreamController<List<Doc>>> _ctl = {};
  int _n = 100;

  @override
  bool get isFirebase => false;

  StreamController<List<Doc>> _c(String col) =>
      _ctl.putIfAbsent(col, () => StreamController<List<Doc>>.broadcast());

  void _emit(String col) => _c(col).add(List<Doc>.from(_db[col] ?? <Doc>[]));

  @override
  Stream<List<Doc>> watch(String col) async* {
    yield List<Doc>.from(_db[col] ?? <Doc>[]);
    yield* _c(col).stream;
  }

  @override
  Future<void> add(String col, Doc data) async {
    _db.putIfAbsent(col, () => <Doc>[]).insert(0, {...data, 'id': 'd${_n++}'});
    _emit(col);
  }

  @override
  Future<void> update(String col, String id, Doc data) async {
    final l = _db[col] ?? <Doc>[];
    final i = l.indexWhere((d) => d['id'] == id);
    if (i >= 0) {
      l[i] = {...l[i], ...data};
      _emit(col);
    }
  }

  @override
  Future<void> signIn(String email, String pass) async {
    final a = _acc[email.toLowerCase()];
    if (a == null) throw Exception('No account found. Create one first, or use demo access.');
    if (a['pass'] != pass) throw Exception('Wrong email or password.');
    session.value = AppUser(email, a['name']!, email, a['role']!);
  }

  @override
  Future<void> register(String name, String email, String pass, String role) async {
    _acc[email.toLowerCase()] = {'pass': pass, 'name': name, 'role': role};
    if (role == 'worker') {
      await add('workers', {
        'name': name, 'role': 'Tradesperson', 'exp': 0, 'rating': 0, 'match': 0,
        'loc': '', 'about': 'New TradeProof member.', 'tags': <String>[], 'skills': <String>[],
      });
    }
    session.value = AppUser(email, name, email, role);
  }

  @override
  Future<void> demoLogin(String role) async {
    const names = {
      'worker': 'Md. Asif Hasan', 'employer': 'David Carter',
      'trainer': 'Dave Vance', 'client': 'Sarah Jenkins',
    };
    session.value = AppUser('demo-$role', names[role] ?? 'Demo User', '$role@demo.tradeproof', role);
  }

  @override
  Future<void> signOut() async => session.value = null;

  @override
  Future<String?> uploadImage(String path) async => null;
}

Map<String, List<Doc>> _seed() {
  const w = 'Md. Asif Hasan';
  Doc cred(String id, String n, String i, String s, String d) =>
      {'id': id, 'name': n, 'issuer': i, 'status': s, 'date': d, 'holder': w, 'hash': credHash(n, w, i, d)};
  return {
    'workers': [
      {'id': 'w0', 'name': w, 'role': 'Master Electrician', 'exp': 8, 'rating': 4.8, 'match': 95, 'loc': 'Saidpur, Nilphamari',
        'about': 'Master Electrician focused on safe, compliant residential and industrial wiring.',
        'tags': ['Residential', 'Industrial', 'Solar'],
        'skills': ['Residential Wiring:95', 'Industrial Electrical:85', 'Solar Installation:70', 'EV Charging Infrastructure:90']},
      {'id': 'w1', 'name': 'Jack Carter', 'role': 'Master Electrician', 'exp': 10, 'rating': 4.8, 'match': 95, 'loc': 'San Francisco, CA',
        'about': 'Master Electrician with 10+ years in commercial and solar work. Fully bonded and insured.',
        'tags': ['Commercial', 'Industrial', 'Solar PV', 'EV Charger'],
        'skills': ['Commercial Power Distribution:95', 'Solar Array Integration:85', 'EV Charger Setup:85']},
      {'id': 'w2', 'name': 'Sarah Jenkins', 'role': 'Apprentice Carpenter', 'exp': 3, 'rating': 4.6, 'match': 80, 'loc': 'Oakland, CA',
        'about': 'Detail-focused carpenter completing Level 3 woodwork certification.',
        'tags': ['Residential', 'Framing', 'Finish Carpentry'], 'skills': ['Framing:82', 'Finish Carpentry:74']},
      {'id': 'w3', 'name': 'Marcus Vance', 'role': 'Journeyman Wireman', 'exp': 5, 'rating': 4.5, 'match': 80, 'loc': 'San Jose, CA',
        'about': 'Journeyman wireman focused on safe, code-compliant residential work.',
        'tags': ['L1 License', 'Wiring'], 'skills': ['Residential Wiring:88', 'Panel Upgrades:76']},
    ],
    'credentials': [
      cred('c1', 'Licensed Electrician - Grade A', 'CA Dept of Consumer Affairs', 'VERIFIED', '2021-01-15'),
      cred('c2', 'Arc Flash Certified (NFPA 70E)', 'Electrical Safety Council', 'VERIFIED', '2024-06-10'),
      cred('c3', 'Master Solar Installer (NABCEP)', 'Board of Certified Energy Practitioners', 'EXPIRED', '2021-05-20'),
      cred('c4', 'Smart Grid Assessor Stamp', 'TradeProof Authority', 'PENDING', '2025-09-01'),
    ],
    'safety': [
      {'id': 's1', 'holder': w, 'name': 'OSHA 30-Hour Construction Safety', 'issuer': 'OSHA / Training Council', 'status': 'VERIFIED', 'note': 'Valid indefinitely'},
      {'id': 's2', 'holder': w, 'name': 'First Aid Level 2 & CPR', 'issuer': 'Red Cross Society', 'status': 'EXPIRED', 'note': 'Expired Mar 2026'},
      {'id': 's3', 'holder': w, 'name': 'Working at Heights Certification', 'issuer': 'Global Safety Board', 'status': 'EXPIRED', 'note': 'Expired Nov 2025'},
      {'id': 's4', 'holder': w, 'name': 'Confined Space Entry Protocol', 'issuer': 'Industrial Safety Dept', 'status': 'VERIFIED', 'note': 'Valid until May 2027'},
    ],
    'portfolio': [
      {'id': 'p1', 'holder': w, 'title': 'Commercial Office Rewiring', 'client': 'Google SF Hub · Jan 2026', 'status': 'VERIFIED'},
      {'id': 'p2', 'holder': w, 'title': 'Residential Smart Grid Setup', 'client': 'Linden Homes · Nov 2025', 'status': 'VERIFIED'},
      {'id': 'p3', 'holder': w, 'title': 'Warehouse Lighting Upgrade', 'client': 'Bay Logistics · Aug 2025', 'status': 'PENDING'},
      {'id': 'p4', 'holder': 'Liam Davies', 'title': 'Three-phase isolation switch install', 'client': 'Practical Wiring Level 3', 'status': 'PENDING'},
    ],
    'jobs': [
      {'id': 'j1', 'title': 'Lead Commercial Electrician', 'company': 'Apex Power Solutions', 'location': 'San Jose, CA', 'pay': r'$55 - $65 / hr', 'match': 95,
        'tags': ['L3 Licence', 'OSHA-30'], 'req': ['L3 Electrical License (City & Guilds)', 'OSHA-30 Safety Training Card', 'Advanced Smart Metering Competence']},
      {'id': 'j2', 'title': 'Solar PV Systems Installer', 'company': 'NextGen Solar Corp', 'location': 'Oakland, CA', 'pay': r'$42 - $48 / hr', 'match': 80,
        'tags': ['Journeyman Card'], 'req': ['Solar Installation Level 2', 'OSHA-30 Safety Training Card']},
    ],
    'applications': [
      {'id': 'a1', 'jobTitle': 'Lead Commercial Electrician', 'applicant': 'Jack Carter', 'match': 95, 'status': 'NEW'},
      {'id': 'a2', 'jobTitle': 'Lead Commercial Electrician', 'applicant': 'Marcus Vance', 'match': 80, 'status': 'NEW'},
    ],
    'assessments': [
      {'id': 'x1', 'candidate': 'Liam Davies', 'trade': 'Electrical', 'title': 'Practical Wiring Assessment - Level 3', 'when': 'Today, 10:00 AM', 'status': 'SCHEDULED'},
      {'id': 'x2', 'candidate': 'Freya Miller', 'trade': 'Plumbing', 'title': 'Copper Pipe Joining & Seal Test', 'when': 'Jan 19, 01:30 PM', 'status': 'SCHEDULED'},
      {'id': 'x3', 'candidate': 'Marcus Vance', 'trade': 'Electrical', 'title': 'Three-Phase Distribution Board Setup', 'when': 'Jan 15, 04:00 PM', 'status': 'PASSED'},
    ],
    'reviews': <Doc>[],
  };
}
