import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  late final Future<bool> _adminAccess;

  @override
  void initState() {
    super.initState();
    if (!widget.isDemo) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      _adminAccess = uid == null
          ? Future<bool>.value(false)
          : AccountService.isAdmin(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDemo) return const _DemoAdminDashboard();

    return FutureBuilder<bool>(
      future: _adminAccess,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _accessMessage(
            'Could not verify administrator access: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return _accessMessage(
            'This login is not registered as a TradeProof administrator.',
          );
        }

        final pages = <Widget>[
          _AdminOverviewTab(
            onViewApplications: () => setState(() => _selectedIndex = 1),
          ),
          const _ApplicationsTab(),
          const _AccountsTab(),
          const _AdminProfileTab(),
        ];
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          body: SafeArea(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: 'Applications',
              ),
              NavigationDestination(
                icon: Icon(Icons.manage_accounts_outlined),
                selectedIcon: Icon(Icons.manage_accounts),
                label: 'Accounts',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _accessMessage(String message) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 44,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  try {
                    await AuthService.signOut();
                    if (!navigator.mounted) return;
                    navigator.pushNamedAndRemoveUntil(
                      '/dashboard',
                      (_) => false,
                    );
                  } catch (error) {
                    if (messenger.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Could not sign out: $error')),
                      );
                    }
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoAdminDashboard extends StatefulWidget {
  const _DemoAdminDashboard();

  @override
  State<_DemoAdminDashboard> createState() => _DemoAdminDashboardState();
}

class _DemoAdminDashboardState extends State<_DemoAdminDashboard> {
  int _selectedIndex = 0;

  final _applications = <_DemoApplication>[
    _DemoApplication(
      uid: 'demo-app-tradesperson',
      name: 'Rafiq Hasan',
      email: 'rafiq@demo.tradeproof',
      role: 'Tradesperson',
      cvFileName: 'rafiq-work-history.pdf',
      details: const {
        'Trade': 'Electrician',
        'Experience': '7 years',
        'Location': 'Dhaka',
        'Qualifications': 'Electrical safety and installation',
        'Work experience': 'Residential and commercial projects',
      },
    ),
    _DemoApplication(
      uid: 'demo-app-employer',
      name: 'Maya Construction',
      email: 'maya@demo.tradeproof',
      role: 'Employer / Contractor',
      cvFileName: 'maya-company-profile.pdf',
      details: const {
        'Company': 'Maya Construction',
        'Industry': 'Building and infrastructure',
        'Location': 'Chattogram',
        'Hiring needs': 'Electricians and site supervisors',
        'Experience': '12 years in construction',
      },
    ),
    _DemoApplication(
      uid: 'demo-app-trainer',
      name: 'Farzana Akter',
      email: 'farzana@demo.tradeproof',
      role: 'Trainer / Assessor',
      cvFileName: 'farzana-trainer-cv.docx',
      details: const {
        'Specialty': 'Workplace electrical safety',
        'Experience': '9 years',
        'Location': 'Dhaka',
        'Certifications': 'Technical training and safety assessment',
        'Assessment experience': 'Apprentice assessment and refresher courses',
      },
    ),
  ];

  final _accounts = <_DemoManagedAccount>[
    _DemoManagedAccount(
      uid: 'demo-app-tradesperson',
      name: 'Rafiq Hasan',
      email: 'rafiq@demo.tradeproof',
      role: 'Tradesperson',
      status: 'pending_review',
    ),
    _DemoManagedAccount(
      uid: 'demo-app-employer',
      name: 'Maya Construction',
      email: 'maya@demo.tradeproof',
      role: 'Employer / Contractor',
      status: 'pending_review',
    ),
    _DemoManagedAccount(
      uid: 'demo-app-trainer',
      name: 'Farzana Akter',
      email: 'farzana@demo.tradeproof',
      role: 'Trainer / Assessor',
      status: 'pending_review',
    ),
    _DemoManagedAccount(
      uid: 'demo-active-worker',
      name: 'Nabil Ahmed',
      email: 'nabil@demo.tradeproof',
      role: 'Tradesperson',
      status: 'active',
    ),
    _DemoManagedAccount(
      uid: 'demo-active-employer',
      name: 'Northstar Works',
      email: 'northstar@demo.tradeproof',
      role: 'Employer / Contractor',
      status: 'active',
    ),
    _DemoManagedAccount(
      uid: 'demo-paused-trainer',
      name: 'Sajid Rahman',
      email: 'sajid@demo.tradeproof',
      role: 'Trainer / Assessor',
      status: 'suspended',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildOverview(),
      _buildApplications(),
      _buildAccounts(),
      _buildProfile(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final pending = _applications
        .where(
          (application) =>
              application.status == 'pending_review' ||
              application.status == 'interview_invited',
        )
        .length;
    final active = _accounts
        .where((account) => account.status == 'active')
        .length;
    final meetings = _applications
        .where((application) => application.status == 'interview_invited')
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        _pageHeading(
          'Admin overview · Demo',
          'Sample applications and accounts. Changes stay on this device.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _statCard(
              'Total accounts',
              '${_accounts.length}',
              Icons.people_outline,
            ),
            _statCard('Active', '$active', Icons.verified_outlined),
            _statCard('Pending decisions', '$pending', Icons.pending_actions),
            _statCard('Meetings', '$meetings', Icons.video_call_outlined),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Applications needing review',
                style: TextStyle(
                  color: Color(0xFF10243B),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text('View all'),
            ),
          ],
        ),
        ..._applications
            .where(
              (application) =>
                  application.status == 'pending_review' ||
                  application.status == 'interview_invited',
            )
            .take(3)
            .map(_applicationCard),
      ],
    );
  }

  Widget _buildApplications() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        _pageHeading(
          'Applications · Demo',
          'Review, approve, decline or invite a sample applicant to meet.',
        ),
        const SizedBox(height: 14),
        ..._applications.map(_applicationCard),
        if (_applications.isEmpty)
          const _EmptyPanel(
            icon: Icons.task_alt,
            title: 'No demo applications',
            message: 'All sample applications have been cleared.',
          ),
      ],
    );
  }

  Widget _applicationCard(_DemoApplication application) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: () => _showApplication(application),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9F7F6),
          child: Icon(
            _roleIcon(application.role),
            color: const Color(0xFF008C96),
          ),
        ),
        title: Text(
          application.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${application.role} · ${application.email}\n'
          '${application.cvFileName}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_right),
            Text(
              _statusLabel(application.status),
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccounts() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        _pageHeading(
          'Account management · Demo',
          'Pause or restore sample accounts. No real accounts are affected.',
        ),
        const SizedBox(height: 14),
        ..._accounts.map((account) {
          final canManage =
              account.status == 'active' || account.status == 'suspended';
          final nextStatus = account.status == 'suspended'
              ? 'active'
              : 'suspended';
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE9F7F6),
                child: Icon(
                  _roleIcon(account.role),
                  color: const Color(0xFF008C96),
                ),
              ),
              title: Text(
                account.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${account.role} · ${account.email}\n'
                '${_statusLabel(account.status)}',
              ),
              isThreeLine: true,
              trailing: canManage
                  ? TextButton(
                      onPressed: () =>
                          _setDemoAccountStatus(account, nextStatus),
                      child: Text(
                        account.status == 'suspended' ? 'Restore' : 'Pause',
                      ),
                    )
                  : const Icon(Icons.hourglass_top, color: Color(0xFF94A3B8)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _pageHeading('Demo administrator', 'Local sample account.'),
        const SizedBox(height: 16),
        const Card(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE5F5F3),
              child: Icon(Icons.admin_panel_settings, color: Color(0xFF008C96)),
            ),
            title: Text('Demo Administrator'),
            subtitle: Text('admin@demo.tradeproof'),
          ),
        ),
        const SizedBox(height: 12),
        const _EmptyPanel(
          icon: Icons.shield_outlined,
          title: 'Demo mode only',
          message:
              'Demo actions update sample data in memory and cannot view or change real users, applications, or uploaded CVs.',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _leaveDemo,
          icon: const Icon(Icons.logout),
          label: const Text('Exit demo'),
        ),
      ],
    );
  }

  Future<void> _showApplication(_DemoApplication application) {
    final canReview =
        application.status == 'pending_review' ||
        application.status == 'interview_invited';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(application.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(application.role),
              Text(application.email),
              const SizedBox(height: 10),
              ...application.details.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              ),
              const Divider(height: 22),
              Text('Status: ${_statusLabel(application.status)}'),
              if (application.status == 'interview_invited') ...[
                const SizedBox(height: 8),
                Text('Meeting: ${_formatDate(application.meetingDate!)}'),
                Text('Link: ${application.meetingLink}'),
                Text('Message: ${application.meetingMessage}'),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showSampleCv(application),
                icon: const Icon(Icons.description_outlined),
                label: Text('Preview ${application.cvFileName}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (canReview) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _setDemoApplicationStatus(application, 'rejected');
              },
              child: const Text('Decline'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _inviteDemoApplicant(application);
              },
              child: const Text('Invite'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _setDemoApplicationStatus(application, 'active');
              },
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showSampleCv(_DemoApplication application) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(application.cvFileName),
        content: Text(
          'Sample ${application.role} application document. '
          'The demo does not store or download real files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteDemoApplicant(_DemoApplication application) async {
    final invitation = await _demoInviteDialog();
    if (invitation == null || !mounted) return;
    setState(() {
      application
        ..status = 'interview_invited'
        ..meetingDate = invitation.date
        ..meetingLink = invitation.link
        ..meetingMessage = invitation.message;
      _syncDemoAccountStatus(application.uid, application.status);
    });
    _showDemoMessage('Demo invitation saved; no email was sent.');
  }

  Future<_DemoMeetingInvitation?> _demoInviteDialog() async {
    final linkController = TextEditingController();
    final messageController = TextEditingController();
    DateTime? meetingDate;
    String? error;

    final result = await showDialog<_DemoMeetingInvitation>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite to an online meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      meetingDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    meetingDate == null
                        ? 'Choose meeting date and time'
                        : _formatDate(meetingDate!),
                  ),
                ),
                TextField(
                  controller: linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'HTTPS meeting link',
                  ),
                ),
                TextField(
                  controller: messageController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Invitation message',
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final uri = Uri.tryParse(linkController.text.trim());
                if (meetingDate == null ||
                    uri?.scheme != 'https' ||
                    messageController.text.trim().isEmpty) {
                  setDialogState(
                    () => error =
                        'Enter a meeting date, HTTPS link and invitation message.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _DemoMeetingInvitation(
                    date: meetingDate!,
                    link: uri.toString(),
                    message: messageController.text.trim(),
                  ),
                );
              },
              child: const Text('Send invitation'),
            ),
          ],
        ),
      ),
    );
    linkController.dispose();
    messageController.dispose();
    return result;
  }

  void _setDemoApplicationStatus(_DemoApplication application, String status) {
    setState(() {
      application
        ..status = status
        ..adminNote = status == 'active'
            ? 'Approved in demo mode.'
            : 'Declined in demo mode.';
      _syncDemoAccountStatus(application.uid, status);
    });
    _showDemoMessage('Sample application updated: ${_statusLabel(status)}.');
  }

  void _setDemoAccountStatus(_DemoManagedAccount account, String status) {
    setState(() {
      account.status = status;
      _syncDemoAccountStatus(account.uid, status);
    });
    _showDemoMessage('Sample account is now ${_statusLabel(status)}.');
  }

  void _syncDemoAccountStatus(String uid, String status) {
    for (final account in _accounts.where((item) => item.uid == uid)) {
      account.status = status;
    }
  }

  void _showDemoMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _leaveDemo() {
    ConnectionService.endDemoSession();
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
  }
}

class _DemoApplication {
  _DemoApplication({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.cvFileName,
    required this.details,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String cvFileName;
  final Map<String, String> details;
  String status = 'pending_review';
  String? adminNote;
  DateTime? meetingDate;
  String? meetingLink;
  String? meetingMessage;
}

class _DemoManagedAccount {
  _DemoManagedAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  String status;
}

class _DemoMeetingInvitation {
  const _DemoMeetingInvitation({
    required this.date,
    required this.link,
    required this.message,
  });

  final DateTime date;
  final String link;
  final String message;
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab({required this.onViewApplications});

  final VoidCallback onViewApplications;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccountApplication>>(
      stream: AccountService.watchApplications(),
      builder: (context, applicationsSnapshot) {
        if (applicationsSnapshot.hasError) {
          return _loadError('applications', applicationsSnapshot.error!);
        }
        if (!applicationsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<ManagedAccount>>(
          stream: AccountService.watchAccounts(),
          builder: (context, accountsSnapshot) {
            if (accountsSnapshot.hasError) {
              return _loadError('accounts', accountsSnapshot.error!);
            }
            if (!accountsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final applications = applicationsSnapshot.data!;
            final accounts = accountsSnapshot.data!;
            final reviewQueue = applications
                .where(
                  (item) =>
                      item.status == 'pending_review' ||
                      item.status == 'interview_invited',
                )
                .length;
            final interviews = applications
                .where((item) => item.status == 'interview_invited')
                .length;
            final active = accounts
                .where((item) => item.status == 'active')
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                _pageHeading(
                  'Admin overview',
                  'Review professional applications and manage account access.',
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 650
                      ? 4
                      : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _statCard(
                      'Total accounts',
                      '${accounts.length}',
                      Icons.people_outline,
                    ),
                    _statCard('Active', '$active', Icons.verified_outlined),
                    _statCard(
                      'Pending decisions',
                      '$reviewQueue',
                      Icons.pending_actions,
                    ),
                    _statCard(
                      'Meetings',
                      '$interviews',
                      Icons.video_call_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Applications needing review',
                        style: TextStyle(
                          color: Color(0xFF10243B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onViewApplications,
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...applications
                    .where(
                      (item) =>
                          item.status == 'pending_review' ||
                          item.status == 'interview_invited',
                    )
                    .take(4)
                    .map(
                      (application) => _ApplicationCard(
                        application: application,
                        onTap: () => _openReview(context, application),
                      ),
                    ),
                if (reviewQueue == 0)
                  const _EmptyPanel(
                    icon: Icons.task_alt,
                    title: 'Review queue is clear',
                    message: 'New professional applications will appear here.',
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  String _filter = 'Needs review';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccountApplication>>(
      stream: AccountService.watchApplications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _loadError('applications', snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!;
        final applications = all.where((application) {
          switch (_filter) {
            case 'Invited':
              return application.status == 'interview_invited';
            case 'Resolved':
              return application.status == 'active' ||
                  application.status == 'rejected' ||
                  application.status == 'suspended';
            case 'All':
              return true;
            default:
              return application.status == 'pending_review' ||
                  application.status == 'interview_invited';
          }
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            _pageHeading(
              'Applications',
              'Check applicant details, request a meeting, or approve access.',
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Needs review', 'Invited', 'Resolved', 'All']
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            if (applications.isEmpty)
              _EmptyPanel(
                icon: Icons.inbox_outlined,
                title: 'No applications here',
                message: _filter == 'Needs review'
                    ? 'New submissions will appear when candidates apply.'
                    : 'There are no applications in this group.',
              )
            else
              ...applications.map(
                (application) => _ApplicationCard(
                  application: application,
                  onTap: () => _openReview(context, application),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AccountsTab extends StatefulWidget {
  const _AccountsTab();

  @override
  State<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<_AccountsTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ManagedAccount>>(
      stream: AccountService.watchAccounts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _loadError('accounts', snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final accounts = snapshot.data!
            .where(
              (account) =>
                  account.uid != currentUid &&
                  (account.fullName.toLowerCase().contains(_query) ||
                      account.email.toLowerCase().contains(_query) ||
                      account.role.toLowerCase().contains(_query)),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            _pageHeading(
              'Account management',
              'Search accounts and pause or restore approved access.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search name, email or role',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (accounts.isEmpty)
              const _EmptyPanel(
                icon: Icons.person_search_outlined,
                title: 'No accounts found',
                message: 'Try a different search term.',
              )
            else
              ...accounts.map(
                (account) =>
                    _AccountCard(account: account, onStatusChanged: _setStatus),
              ),
          ],
        );
      },
    );
  }

  Future<void> _setStatus(ManagedAccount account, String status) async {
    try {
      await AccountService.setAccountStatus(account, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.fullName} account is now $status.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(context, 'Could not update account: $error');
    }
  }
}

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _pageHeading('Administrator profile', 'TradeProof operations access.'),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE5F5F3),
              child: Icon(Icons.admin_panel_settings, color: Color(0xFF008C96)),
            ),
            title: Text(user?.displayName ?? 'Administrator'),
            subtitle: Text(user?.email ?? ''),
          ),
        ),
        const SizedBox(height: 12),
        const _EmptyPanel(
          icon: Icons.shield_outlined,
          title: 'Protected administrator access',
          message:
              'Only accounts provisioned by a trusted administrator can use this portal.',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/dashboard', (_) => false);
            } catch (error) {
              if (!context.mounted) return;
              _showError(context, 'Could not sign out: $error');
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _ApplicationReviewPage extends StatefulWidget {
  const _ApplicationReviewPage({required this.application});

  final AccountApplication application;

  @override
  State<_ApplicationReviewPage> createState() => _ApplicationReviewPageState();
}

class _ApplicationReviewPageState extends State<_ApplicationReviewPage> {
  bool _isLoading = false;

  AccountApplication get application => widget.application;

  @override
  Widget build(BuildContext context) {
    final canReview =
        application.status == 'pending_review' ||
        application.status == 'interview_invited';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Application review'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10243B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.fullName,
                    style: const TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(application.role),
                  const SizedBox(height: 12),
                  _infoRow('Email', application.email),
                  _infoRow('Status', _statusLabel(application.status)),
                  ...application.details.entries.map(
                    (entry) => _infoRow(_label(entry.key), '${entry.value}'),
                  ),
                  if (application.cvFileName?.isNotEmpty == true) ...[
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF008C96),
                      ),
                      title: Text(application.cvFileName!),
                      subtitle: const Text('Private applicant document'),
                      trailing: IconButton(
                        tooltip: 'Open document',
                        onPressed: _isLoading ? null : _openCv,
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ),
                  ],
                  if (application.adminNote?.isNotEmpty == true)
                    _infoRow('Previous review note', application.adminNote!),
                ],
              ),
            ),
          ),
          if (canReview) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _approve,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve and activate account'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087F5B),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _invite,
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Invite to an online meeting'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isLoading ? null : _reject,
              icon: const Icon(Icons.close),
              label: const Text('Decline application'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB42318),
              ),
            ),
          ],
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _approve() async {
    final note = await _noteDialog(
      title: 'Approve application',
      prompt: 'Optional message for the applicant',
      confirmText: 'Approve account',
    );
    if (note == null) return;
    await _review(status: 'active', note: note);
  }

  Future<void> _reject() async {
    final note = await _noteDialog(
      title: 'Decline application',
      prompt: 'Reason or next steps for the applicant',
      confirmText: 'Decline',
    );
    if (note == null) return;
    await _review(status: 'rejected', note: note);
  }

  Future<void> _invite() async {
    final invitation = await _inviteDialog();
    if (invitation == null) return;
    await _review(
      status: 'interview_invited',
      note: invitation.note,
      meetingDate: invitation.date,
      meetingLink: invitation.link,
      meetingMessage: invitation.message,
    );
  }

  Future<void> _review({
    required String status,
    String? note,
    DateTime? meetingDate,
    String? meetingLink,
    String? meetingMessage,
  }) async {
    setState(() => _isLoading = true);
    try {
      await AccountService.reviewApplication(
        application: application,
        status: status,
        note: note,
        meetingDate: meetingDate,
        meetingLink: meetingLink,
        meetingMessage: meetingMessage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application updated: ${_statusLabel(status)}.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      _showError(context, 'Could not update application: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCv() async {
    final path = application.cvPath;
    if (path == null) return;
    setState(() => _isLoading = true);
    try {
      final url = await AccountService.getCvDownloadUrl(path);
      if (!mounted) return;
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('No application could open this document.');
      }
    } catch (error) {
      if (!mounted) return;
      if (!mounted) return;
      _showError(context, 'Could not open the applicant document: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _noteDialog({
    required String title,
    required String prompt,
    required String confirmText,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: prompt),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<_MeetingInvitation?> _inviteDialog() async {
    final linkController = TextEditingController();
    final messageController = TextEditingController();
    DateTime? selectedDate;
    String? error;

    final result = await showDialog<_MeetingInvitation>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite applicant to an online meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    selectedDate == null
                        ? 'Choose meeting date and time'
                        : _formatDate(selectedDate!),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Online meeting link',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Invitation message',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final uri = Uri.tryParse(linkController.text.trim());
                if (selectedDate == null ||
                    uri == null ||
                    uri.scheme != 'https' ||
                    messageController.text.trim().isEmpty) {
                  setDialogState(
                    () => error =
                        'Add a date, an HTTPS meeting link and an invitation message.',
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  _MeetingInvitation(
                    date: selectedDate!,
                    link: uri.toString(),
                    message: messageController.text.trim(),
                    note: 'Online meeting invitation sent.',
                  ),
                );
              },
              child: const Text('Send invitation'),
            ),
          ],
        ),
      ),
    );
    linkController.dispose();
    messageController.dispose();
    return result;
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final AccountApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9F7F6),
          child: Icon(
            _roleIcon(application.role),
            color: const Color(0xFF008C96),
          ),
        ),
        title: Text(
          application.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${application.role} · ${application.email}\n'
          '${application.cvFileName == null ? 'No document attached' : 'Supporting document attached'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_right),
            Text(
              _statusLabel(application.status),
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onStatusChanged});

  final ManagedAccount account;
  final Future<void> Function(ManagedAccount, String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final canManage =
        account.role != 'Admin' &&
        (account.status == 'active' || account.status == 'suspended');
    final nextStatus = account.status == 'suspended' ? 'active' : 'suspended';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9F7F6),
          child: Icon(_roleIcon(account.role), color: const Color(0xFF008C96)),
        ),
        title: Text(
          account.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${account.role} · ${account.email}\n${_statusLabel(account.status)}',
        ),
        isThreeLine: true,
        trailing: canManage
            ? PopupMenuButton<String>(
                tooltip: 'Manage account',
                onSelected: (value) => onStatusChanged(account, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: nextStatus,
                    child: Text(
                      account.status == 'suspended'
                          ? 'Restore access'
                          : 'Pause access',
                    ),
                  ),
                ],
              )
            : const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _MeetingInvitation {
  const _MeetingInvitation({
    required this.date,
    required this.link,
    required this.message,
    required this.note,
  });

  final DateTime date;
  final String link;
  final String message;
  final String note;
}

Widget _pageHeading(String title, String subtitle) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      title,
      style: const TextStyle(
        color: Color(0xFF10243B),
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
  ],
);

Widget _statCard(String label, String value, IconData icon) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE0E6EE)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF008C96)),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF10243B),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
    ],
  ),
);

Widget _loadError(String area, Object error) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text('Could not load $area: $error', textAlign: TextAlign.center),
  ),
);

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E6EE)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 30, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    ),
  );
}

void _openReview(BuildContext context, AccountApplication application) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ApplicationReviewPage(application: application),
    ),
  );
}

Widget _infoRow(String label, String value) => Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 145,
        child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF10243B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

String _label(String key) {
  final words = key.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return words[0].toUpperCase() + words.substring(1);
}

String _statusLabel(String status) => switch (status) {
  'pending_review' => 'Pending review',
  'interview_invited' => 'Meeting invited',
  'application_draft' || 'draft' => 'Draft',
  'active' => 'Active',
  'rejected' => 'Declined',
  'suspended' => 'Paused',
  _ => status,
};

IconData _roleIcon(String role) => switch (role) {
  'Tradesperson' => Icons.handyman_outlined,
  'Employer / Contractor' || 'Employer' => Icons.business_outlined,
  'Trainer / Assessor' || 'Trainer' => Icons.school_outlined,
  'Admin' => Icons.admin_panel_settings_outlined,
  _ => Icons.person_outline,
};

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day}/${local.month}/${local.year} · $hour:$minute $suffix';
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
