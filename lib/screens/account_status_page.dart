import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/account_service.dart';
import '../services/auth_service.dart';
import 'create_account_page.dart';
import 'employer_dashboard_page.dart';
import 'trainer_dashboard_page.dart';
import 'tradeworker.dart';

class AccountStatusPage extends StatelessWidget {
  const AccountStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your account status.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Application status'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10243B),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<AccountApplication?>(
        stream: AccountService.watchApplication(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              icon: Icons.error_outline,
              title: 'Could not load your application',
              body: '${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final application = snapshot.data;
          if (application == null) {
            return FutureBuilder<String?>(
              future: AuthService.currentUserStatus(),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.hasError) {
                  return _message(
                    icon: Icons.error_outline,
                    title: 'Could not load account status',
                    body: '${statusSnapshot.error}',
                  );
                }
                if (!statusSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (statusSnapshot.data == 'suspended') {
                  return _message(
                    icon: Icons.pause_circle_outline,
                    title: 'Account temporarily paused',
                    body: 'Contact TradeProof support for more information.',
                  );
                }
                return _message(
                  icon: Icons.info_outline,
                  title: 'Application not found',
                  body: 'Please contact TradeProof support for help.',
                );
              },
            );
          }
          return _applicationBody(context, application);
        },
      ),
    );
  }

  Widget _applicationBody(
    BuildContext context,
    AccountApplication application,
  ) {
    final state = switch (application.status) {
      'active' => (
        Icons.verified_outlined,
        'Your account is approved',
        'Your ${application.role} features are now available.',
        const Color(0xFF087F5B),
      ),
      'interview_invited' => (
        Icons.video_call_outlined,
        'Online meeting requested',
        application.meetingMessage?.trim().isNotEmpty == true
            ? application.meetingMessage!
            : 'Please review the meeting details and contact us if you need to reschedule.',
        const Color(0xFFB36B00),
      ),
      'rejected' => (
        Icons.info_outline,
        'Application needs attention',
        application.adminNote?.trim().isNotEmpty == true
            ? application.adminNote!
            : 'The review team could not approve this application yet.',
        const Color(0xFFB54708),
      ),
      'suspended' => (
        Icons.pause_circle_outline,
        'Account temporarily paused',
        application.adminNote?.trim().isNotEmpty == true
            ? application.adminNote!
            : 'Contact TradeProof support for more information.',
        const Color(0xFFB54708),
      ),
      'draft' || 'application_draft' => (
        Icons.edit_note_outlined,
        'Application not submitted',
        'Complete and submit your professional details to start the review.',
        const Color(0xFFB36B00),
      ),
      _ => (
        Icons.hourglass_top_rounded,
        'Application under review',
        'Your account will be activated after an administrator approves it.',
        const Color(0xFF008C96),
      ),
    };

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E6EE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(state.$1, size: 38, color: state.$4),
              const SizedBox(height: 12),
              Text(
                state.$2,
                style: const TextStyle(
                  color: Color(0xFF10243B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.$3,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
              ),
              const Divider(height: 28),
              _detailRow('Applicant', application.fullName),
              _detailRow('Account type', application.role),
              _detailRow('Email', application.email),
              _detailRow('Status', _statusLabel(application.status)),
              if (application.status == 'interview_invited') ...[
                const SizedBox(height: 12),
                const Text(
                  'Meeting invitation',
                  style: TextStyle(
                    color: Color(0xFF10243B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (application.meetingDate != null)
                  _detailRow(
                    'Date and time',
                    _formatDate(application.meetingDate!),
                  ),
                if (application.meetingLink?.isNotEmpty == true)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _openMeeting(context, application.meetingLink!),
                      icon: const Icon(Icons.video_call_outlined),
                      label: const Text('Join online meeting'),
                    ),
                  ),
                if (application.adminNote?.isNotEmpty == true)
                  _detailRow('Review note', application.adminNote!),
              ],
              if (application.status == 'active') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openAccount(context, application.role),
                    child: const Text('Open my account'),
                  ),
                ),
              ],
              if (application.status == 'draft' ||
                  application.status == 'application_draft') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CreateAccountPage(draft: application),
                      ),
                    ),
                    child: const Text('Continue application'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF64748B)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF10243B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF10243B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'pending_review' => 'Pending review',
    'interview_invited' => 'Meeting requested',
    'application_draft' || 'draft' => 'Draft',
    'active' => 'Approved',
    'rejected' => 'Not approved',
    'suspended' => 'Paused',
    _ => status,
  };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year} · $hour:$minute $suffix';
  }

  Future<void> _openMeeting(BuildContext context, String link) async {
    try {
      if (!await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('No application could open the meeting link.');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the meeting: $error')),
        );
      }
    }
  }

  void _openAccount(BuildContext context, String role) {
    final Widget page = switch (role) {
      'Employer / Contractor' || 'Employer' => const EmployerDashboardPage(),
      'Trainer / Assessor' || 'Trainer' => const TrainerDashboardPage(),
      _ => const AuthenticatedShell(),
    };
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page),
      (_) => false,
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService.signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      }
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }
}
