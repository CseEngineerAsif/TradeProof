import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';

const _profileNavy = Color(0xFF10243B);
const _profileTeal = Color(0xFF008C96);
const _profileMuted = Color(0xFF64748B);
const _profileLine = Color(0xFFDCE4EC);

/// Shared professional account profile for every signed-in account type.
class AccountProfileTab extends StatefulWidget {
  const AccountProfileTab({
    super.key,
    required this.role,
    required this.isDemo,
    this.onSignOut,
    this.onSwitchMarketplace,
  });

  final String role;
  final bool isDemo;
  final Future<void> Function(BuildContext context)? onSignOut;
  final VoidCallback? onSwitchMarketplace;

  @override
  State<AccountProfileTab> createState() => _AccountProfileTabState();
}

class _AccountProfileTabState extends State<AccountProfileTab> {
  final _imagePicker = ImagePicker();
  Uint8List? _localPhoto;
  String? _photoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
  }

  Future<void> _changePhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 86,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _message('ছবিটি ৫ MB-এর কম হতে হবে।');
        return;
      }
      if (widget.isDemo) {
        setState(() => _localPhoto = bytes);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please sign in again.');
      setState(() => _uploadingPhoto = true);
      final ref = FirebaseStorage.instance.ref('profile_photos/${user.uid}/avatar');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      if (!mounted) return;
      setState(() {
        _localPhoto = bytes;
        _photoUrl = url;
      });
      _message('Profile photo আপডেট হয়েছে।');
    } catch (error) {
      _message('ছবি আপডেট করা যায়নি: $error');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _signOut() async {
    if (widget.onSignOut != null) {
      await widget.onSignOut!(context);
      return;
    }
    if (widget.isDemo) {
      ConnectionService.endDemoSession();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      }
      return;
    }
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      }
    } catch (error) {
      _message(authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.isDemo ? null : FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : ConnectionService.currentUserName?.trim().isNotEmpty == true
        ? ConnectionService.currentUserName!.trim()
        : widget.role == 'Employer / Contractor'
        ? 'Your company'
        : 'TradeProof member';
    final email = user?.email ?? ConnectionService.currentUserEmail ?? '';
    final uid = user?.uid;

    if (uid == null) {
      return _profileBody(
        name: name,
        email: email,
        role: widget.role,
        details: const {},
        status: widget.isDemo ? 'Demo account' : 'Signed out',
        cvFileName: null,
        cvPath: null,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? const <String, dynamic>{};
        final actualName = userData['fullName'] as String? ?? name;
        final actualRole = userData['role'] as String? ?? widget.role;
        final status = userData['status'] as String? ?? 'active';
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('account_applications')
              .doc(uid)
              .snapshots(),
          builder: (context, applicationSnapshot) {
            final application = applicationSnapshot.data?.data() ?? const <String, dynamic>{};
            final details = application['details'] is Map
                ? Map<String, dynamic>.from(application['details'] as Map)
                : const <String, dynamic>{};
            return _profileBody(
              name: actualName,
              email: email,
              role: actualRole,
              details: details,
              status: status,
              cvFileName: application['cvFileName'] as String?,
              cvPath: application['cvPath'] as String?,
            );
          },
        );
      },
    );
  }

  Widget _profileBody({
    required String name,
    required String email,
    required String role,
    required Map<String, dynamic> details,
    required String status,
    required String? cvFileName,
    required String? cvPath,
  }) {
    final personalDetails = <(String, String)>[
      ('Email', email),
      if (_value(details, 'phone').isNotEmpty) ('Phone', _value(details, 'phone')),
      if (_value(details, 'location').isNotEmpty) ('Location', _value(details, 'location')),
      if (_value(details, 'trade').isNotEmpty) ('Trade', _value(details, 'trade')),
      if (_value(details, 'companyName').isNotEmpty) ('Company', _value(details, 'companyName')),
      if (_value(details, 'industry').isNotEmpty) ('Industry', _value(details, 'industry')),
      if (_value(details, 'specialty').isNotEmpty) ('Specialty', _value(details, 'specialty')),
      if (_value(details, 'experienceYears').isNotEmpty) ('Experience', '${_value(details, 'experienceYears')} years'),
      if (_value(details, 'qualifications').isNotEmpty) ('Qualifications', _value(details, 'qualifications')),
      if (_value(details, 'certifications').isNotEmpty) ('Certifications', _value(details, 'certifications')),
      if (_value(details, 'registrationNumber').isNotEmpty) ('Registration no.', _value(details, 'registrationNumber')),
      if (_value(details, 'hiringNeeds').isNotEmpty) ('Hiring needs', _value(details, 'hiringNeeds')),
    ];
    final photo = _localPhoto != null
        ? MemoryImage(_localPhoto!)
        : _photoUrl == null
        ? null
        : NetworkImage(_photoUrl!) as ImageProvider;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const Text('My profile', style: TextStyle(color: _profileNavy, fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Your professional identity and account documents.', style: TextStyle(color: _profileMuted, fontSize: 12)),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_profileNavy, Color(0xFF173D58)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x1A10243B), blurRadius: 16, offset: Offset(0, 7))],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFE0F4F2),
                    backgroundImage: photo,
                    child: photo == null ? Text(_initials(name), style: const TextStyle(color: _profileTeal, fontSize: 21, fontWeight: FontWeight.w800)) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: _profileTeal,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _uploadingPhoto ? null : _changePhoto,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: _uploadingPhoto
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(role, style: const TextStyle(color: Color(0xFFBCEBE5), fontSize: 12, fontWeight: FontWeight.w700)),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD5DFE8), fontSize: 10)),
                  ],
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
                    child: Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _uploadingPhoto ? null : _changePhoto,
            icon: const Icon(Icons.add_a_photo_outlined, size: 17),
            label: const Text('Change profile photo'),
            style: TextButton.styleFrom(foregroundColor: _profileTeal),
          ),
        ),
        const SizedBox(height: 8),
        _ProfileSectionCard(
          title: 'Personal details',
          icon: Icons.badge_outlined,
          child: personalDetails.isEmpty
              ? const Text('Application details will appear here when available.', style: TextStyle(color: _profileMuted, fontSize: 12))
              : Column(children: [
                  for (var i = 0; i < personalDetails.length; i++) ...[
                    _DetailLine(label: personalDetails[i].$1, value: personalDetails[i].$2),
                    if (i < personalDetails.length - 1) const Divider(height: 18, color: Color(0xFFEDF1F5)),
                  ],
                ]),
        ),
        const SizedBox(height: 12),
        _ProfileSectionCard(
          title: 'Professional CV',
          icon: Icons.description_outlined,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cvFileName?.isNotEmpty == true ? cvFileName! : 'No CV or supporting document uploaded', style: const TextStyle(color: _profileNavy, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Preview your formatted profile or open the original document submitted with your application.', style: TextStyle(color: _profileMuted, fontSize: 11, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ProfessionalCvPage(name: name, email: email, role: role, details: details, cvPath: cvPath, cvFileName: cvFileName))),
                icon: const Icon(Icons.preview_outlined, size: 17),
                label: const Text('View professional CV'),
              ),
              if (cvPath?.isNotEmpty == true)
                FilledButton.icon(
                  onPressed: () => _openOriginalCv(cvPath!),
                  icon: const Icon(Icons.open_in_new, size: 17),
                  label: const Text('Open uploaded CV'),
                  style: FilledButton.styleFrom(backgroundColor: _profileTeal),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        if (widget.onSwitchMarketplace != null) ...[
          OutlinedButton.icon(
            onPressed: widget.onSwitchMarketplace,
            icon: const Icon(Icons.storefront_outlined, size: 17),
            label: const Text('Switch to Customer Marketplace'),
            style: OutlinedButton.styleFrom(foregroundColor: _profileTeal, side: const BorderSide(color: _profileLine), padding: const EdgeInsets.symmetric(vertical: 13)),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, size: 17),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(foregroundColor: _profileNavy, side: const BorderSide(color: _profileLine), padding: const EdgeInsets.symmetric(vertical: 13)),
        ),
      ],
    );
  }

  Future<void> _openOriginalCv(String path) async {
    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        throw StateError('No app available to open the document.');
      }
    } catch (error) {
      _message('CV খোলা যায়নি: $error');
    }
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _profileLine), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: _profileTeal, size: 19), const SizedBox(width: 8), Text(title, style: const TextStyle(color: _profileNavy, fontSize: 14, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 112, child: Text(label, style: const TextStyle(color: _profileMuted, fontSize: 11))),
    Expanded(child: Text(value, style: const TextStyle(color: _profileNavy, fontSize: 11, fontWeight: FontWeight.w600))),
  ]);
}

class _ProfessionalCvPage extends StatelessWidget {
  const _ProfessionalCvPage({required this.name, required this.email, required this.role, required this.details, required this.cvPath, required this.cvFileName});
  final String name;
  final String email;
  final String role;
  final Map<String, dynamic> details;
  final String? cvPath;
  final String? cvFileName;

  @override
  Widget build(BuildContext context) {
    final experience = _value(details, 'workExperience');
    final qualifications = _value(details, 'qualifications').isNotEmpty ? _value(details, 'qualifications') : _value(details, 'certifications');
    final highlights = <(String, String)>[
      if (_value(details, 'trade').isNotEmpty) ('Trade', _value(details, 'trade')),
      if (_value(details, 'companyName').isNotEmpty) ('Company', _value(details, 'companyName')),
      if (_value(details, 'industry').isNotEmpty) ('Industry', _value(details, 'industry')),
      if (_value(details, 'specialty').isNotEmpty) ('Specialty', _value(details, 'specialty')),
      if (_value(details, 'experienceYears').isNotEmpty) ('Experience', '${_value(details, 'experienceYears')} years'),
      if (_value(details, 'location').isNotEmpty) ('Location', _value(details, 'location')),
      if (_value(details, 'phone').isNotEmpty) ('Phone', _value(details, 'phone')),
      if (_value(details, 'hiringNeeds').isNotEmpty) ('Hiring needs', _value(details, 'hiringNeeds')),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(title: const Text('Professional CV'), backgroundColor: Colors.white, foregroundColor: _profileNavy),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x120D1B2E), blurRadius: 16, offset: Offset(0, 6))]),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(22, 24, 22, 22), decoration: const BoxDecoration(gradient: LinearGradient(colors: [_profileNavy, Color(0xFF1B5368)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TRADEPROOF  /  PROFESSIONAL PROFILE', style: TextStyle(color: Color(0xFF9DE4D7), fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.1, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(role, style: const TextStyle(color: Color(0xFFBEECE5), fontSize: 14, fontWeight: FontWeight.w700)),
              if (email.isNotEmpty) ...[const SizedBox(height: 10), Text(email, style: const TextStyle(color: Colors.white70, fontSize: 11))],
            ])),
            Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cvHeading('PROFILE DETAILS'),
              const SizedBox(height: 10),
              if (highlights.isEmpty) const Text('No additional professional details have been provided.', style: TextStyle(color: _profileMuted, fontSize: 12)),
              for (final item in highlights) Padding(padding: const EdgeInsets.only(bottom: 9), child: _DetailLine(label: item.$1, value: item.$2)),
              if (qualifications.isNotEmpty) ...[const SizedBox(height: 12), _cvHeading('QUALIFICATIONS & CERTIFICATIONS'), const SizedBox(height: 8), Text(qualifications, style: const TextStyle(color: _profileNavy, fontSize: 12, height: 1.5))],
              if (experience.isNotEmpty) ...[const SizedBox(height: 18), _cvHeading('WORK EXPERIENCE'), const SizedBox(height: 8), Text(experience, style: const TextStyle(color: _profileNavy, fontSize: 12, height: 1.6))],
              const SizedBox(height: 22),
              Row(children: [const Icon(Icons.verified_outlined, color: _profileTeal, size: 17), const SizedBox(width: 7), const Expanded(child: Text('TradeProof account profile', style: TextStyle(color: _profileMuted, fontSize: 10))), if (cvPath?.isNotEmpty == true) TextButton.icon(onPressed: () async { try { final url = await FirebaseStorage.instance.ref(cvPath!).getDownloadURL(); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the original CV.'))); } }, icon: const Icon(Icons.open_in_new, size: 15), label: Text(cvFileName == null ? 'Original CV' : 'Original document'))]),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _cvHeading(String text) => Text(text, style: const TextStyle(color: _profileTeal, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800));
}

String _value(Map<String, dynamic> details, String key) => details[key]?.toString().trim() ?? '';
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return 'TP';
  return parts.length == 1 ? parts.first.substring(0, 1).toUpperCase() : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
String _statusLabel(String status) => switch (status) {
  'active' => 'Verified account',
  'pending_review' || 'interview_invited' => 'Application under review',
  'suspended' => 'Account paused',
  'rejected' => 'Application needs attention',
  'Demo account' => status,
  _ => status,
};
