import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';
import 'common_interface_page.dart';
import 'connections_page.dart';
import 'worker_profile_page.dart';

// This dashboard helps an employer post jobs, search workers, and review applicants.
class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  State<EmployerDashboardPage> createState() => _EmployerDashboardPageState();
}

// Search, filters, and current employer tab state live here.
class _EmployerDashboardPageState extends State<EmployerDashboardPage> {
  static const _teal = Color(0xFF00999D);
  static const _navy = Color(0xFF0D1B2E);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFDCE4EC);
  static const _background = Color(0xFFF3F5F8);

  static const _workers = <_Worker>[
    _Worker(
      name: 'Jack Carter',
      trade: 'Master Electrician',
      experience: '8 Years Exp',
      licenses: ['L3 License', 'OSHA-30'],
      match: '95% MATCH',
    ),
    _Worker(
      name: 'Marcus Vance',
      trade: 'Journeyman Wireman',
      experience: '5 Years Exp',
      licenses: ['L1 License'],
      match: '80% MATCH',
    ),
    _Worker(
      name: 'Amina Rahman',
      trade: 'Solar Installer',
      experience: '6 Years Exp',
      licenses: ['L3 License', 'OSHA-30'],
      match: '92% MATCH',
    ),
  ];

  static const _applicants = <_Applicant>[
    _Applicant(
      name: 'Jack Carter',
      trade: 'Master Electrician',
      match: '95% Match',
      status: 'NEW',
    ),
    _Applicant(
      name: 'Marcus Vance',
      trade: 'Journeyman',
      match: '80% Match',
      status: 'REVIEWED',
    ),
  ];

  final _jobFormKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final List<_EmployerJob> _postedJobs = [
    const _EmployerJob(
      title: 'Lead Commercial Electrician',
      category: 'Electrical System / Smart Grid',
      verification: 'Gold L3 Verification',
    ),
  ];

  int _selectedIndex = 0;
  bool _isCreatingJob = false;
  bool _requireL3 = true;
  bool _filterL3 = true;
  bool _filterOsha = false;
  String _searchQuery = '';
  String _jobTitle = 'Lead Commercial Electrician';
  String _tradeCategory = 'Electrical System / Smart Grid';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Connect each employer tab to its page and search actions.
    final pages = <Widget>[
      DashboardPage(
        showHeader: false,
        employerHome: true,
        onEmployerSearch: (query) {
          _searchController.text = query;
          setState(() {
            _searchQuery = query;
            _selectedIndex = 2;
          });
        },
      ),
      _buildOverview(isDashboard: true),
      _buildSearch(),
      _isCreatingJob ? _buildJobForm() : _buildOverview(),
      _buildMessages(),
      _buildProfile(),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _teal,
        unselectedItemColor: const Color(0xFF91A2BC),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Main overview view with job metrics, actions, and recent applicants.
  Widget _buildOverview({bool isDashboard = false}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        Text(
          isDashboard ? 'Employer Dashboard' : 'Employer Portal',
          style: const TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Apex Power Solutions Dashboard',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Active Jobs',
                value: '${4 + _postedJobs.length}',
                valueColor: _teal,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _MetricCard(title: 'Total Candidates', value: '34'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Post New Job',
                onPressed: _openJobForm,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Search Workers',
                dark: true,
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Recent Applicants'),
        const SizedBox(height: 8),
        ..._applicants.map(
          (applicant) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _ApplicantCard(
              applicant: applicant,
              onTap: () => _showApplicant(applicant),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle('Your Job Posts'),
        const SizedBox(height: 8),
        ..._postedJobs.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _PostedJobCard(job: job),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    // Filter the sample workers by search text and selected credentials.
    final query = _searchQuery.trim().toLowerCase();
    final matchingWorkers = _workers.where((worker) {
      final matchesText =
          query.isEmpty ||
          worker.name.toLowerCase().contains(query) ||
          worker.trade.toLowerCase().contains(query) ||
          worker.licenses.any(
            (license) => license.toLowerCase().contains(query),
          );
      final matchesL3 = !_filterL3 || worker.licenses.contains('L3 License');
      final matchesOsha = !_filterOsha || worker.licenses.contains('OSHA-30');
      return matchesText && matchesL3 && matchesOsha;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
      children: [
        const Text(
          'Search Compliance',
          style: TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Find verified tradespeople in real-time.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Trade, worker or credential',
            hintStyle: const TextStyle(color: _muted, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: _muted, size: 19),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close, size: 18),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          children: [
            FilterChip(
              label: const Text('With L3 Verified'),
              selected: _filterL3,
              onSelected: (value) => setState(() => _filterL3 = value),
              selectedColor: _teal,
              labelStyle: TextStyle(
                color: _filterL3 ? Colors.white : _navy,
                fontSize: 10,
              ),
              side: BorderSide(color: _filterL3 ? _teal : _line),
              showCheckmark: false,
            ),
            FilterChip(
              label: const Text('OSHA verified'),
              selected: _filterOsha,
              onSelected: (value) => setState(() => _filterOsha = value),
              selectedColor: _teal,
              labelStyle: TextStyle(
                color: _filterOsha ? Colors.white : _navy,
                fontSize: 10,
              ),
              side: BorderSide(color: _filterOsha ? _teal : _line),
              showCheckmark: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${matchingWorkers.length} verified ${matchingWorkers.length == 1 ? 'worker' : 'workers'} found',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        for (final worker in matchingWorkers)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _WorkerCard(
              worker: worker,
              onTap: () => _showWorker(worker),
            ),
          ),
        if (matchingWorkers.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No verified workers match these filters.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  // Collects the information needed to publish a job post.
  Widget _buildJobForm() {
    return Form(
      key: _jobFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(9, 14, 9, 20),
        children: [
          const Text(
            'Create Job Post',
            style: TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set required credentials for automated compliance matching.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          _fieldLabel('JOB TITLE'),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: _jobTitle,
            decoration: _inputDecoration(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a job title.'
                : null,
            onSaved: (value) => _jobTitle = value!.trim(),
          ),
          const SizedBox(height: 14),
          _fieldLabel('TRADE CATEGORY'),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: _tradeCategory,
            decoration: _inputDecoration(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a trade category.'
                : null,
            onSaved: (value) => _tradeCategory = value!.trim(),
          ),
          const SizedBox(height: 14),
          _fieldLabel('TARGET VERIFICATION LEVEL'),
          const SizedBox(height: 6),
          _VerificationOption(
            label: 'Requires Gold L3 Verification',
            selected: _requireL3,
            onTap: () => setState(() => _requireL3 = true),
          ),
          const SizedBox(height: 6),
          _VerificationOption(
            label: 'Requires Standard L1 Compliance',
            selected: !_requireL3,
            onTap: () => setState(() => _requireL3 = false),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: _publishJob,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Publish Opportunity',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _isCreatingJob = false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Shows requests and messages related to the employer's posts.
  Widget _buildMessages() {
    return const ConnectionsPage();
  }

  // Shows employer details and account actions.
  Widget _buildProfile() {
    final user = widget.isDemo ? null : FirebaseAuth.instance.currentUser;
    final companyName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : widget.isDemo
        ? 'Apex Power Solutions'
        : 'Employer Account';
    final email = user?.email;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
      children: [
        const Text(
          'Company Profile',
          style: TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE0F4F2),
                child: Icon(Icons.business_outlined, color: _teal),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ??
                          (widget.isDemo
                              ? 'Demo employer account'
                              : 'Employer account'),
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: _teal, size: 19),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _profileInfoRow(
                icon: Icons.work_outline,
                label: 'Job posts',
                value: '${_postedJobs.length}',
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              _profileInfoRow(
                icon: Icons.people_outline,
                label: 'Recent applicants',
                value: '${_applicants.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout, size: 17),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: _line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: _navy,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: _navy,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _teal, width: 1.5),
    ),
  );

  void _openJobForm() {
    setState(() {
      _selectedIndex = 3;
      _isCreatingJob = true;
    });
  }

  Future<void> _publishJob() async {
    // Validate the job form and publish its details to the marketplace.
    if (!_jobFormKey.currentState!.validate()) return;
    _jobFormKey.currentState!.save();
    try {
      await ConnectionService.publishPost(
        type: 'job',
        title: _jobTitle,
        category: _tradeCategory,
        description:
            'Verification required: ${_requireL3 ? 'Gold L3 Verification' : 'Standard L1 Compliance'}. '
            'Contact the employer to discuss project details and availability.',
      );
    } catch (error) {
      if (mounted) _showMessage(context, authErrorMessage(error));
      return;
    }
    if (!mounted) return;
    setState(() {
      _postedJobs.insert(
        0,
        _EmployerJob(
          title: _jobTitle,
          category: _tradeCategory,
          verification: _requireL3
              ? 'Gold L3 Verification'
              : 'Standard L1 Compliance',
        ),
      );
      _isCreatingJob = false;
    });
    _showMessage(context, 'Job published to TradeProof accounts.');
  }

  // Opens a summary of a person who applied for a job.
  void _showApplicant(_Applicant applicant) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(applicant.name),
        content: Text(
          '${applicant.trade} • ${applicant.match}\nApplication status: ${applicant.status}',
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

  // Opens the selected worker's profile.
  void _showWorker(_Worker worker) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkerProfilePage(
          name: worker.name,
          trade: worker.trade,
          experience: worker.experience,
          credentials: worker.licenses,
          match: worker.match,
        ),
      ),
    );
  }

  // Signs out the user or exits the sample account.
  Future<void> _signOut(BuildContext context) async {
    if (widget.isDemo) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      return;
    }

    try {
      await AuthService.signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, authErrorMessage(error));
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(12),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    this.valueColor = const Color(0xFF0D1B2E),
  });

  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.dark = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: dark
              ? const Color(0xFF0D1B2E)
              : const Color(0xFF00999D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.applicant, required this.onTap});

  final _Applicant applicant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNew = applicant.status == 'NEW';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE4EC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE0F4F2),
              child: Text(
                applicant.name.substring(0, 1),
                style: const TextStyle(
                  color: Color(0xFF008C96),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applicant.name,
                    style: const TextStyle(
                      color: Color(0xFF0D1B2E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${applicant.trade} • ${applicant.match}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: isNew
                    ? const Color(0xFFEAFBF5)
                    : const Color(0xFFFFF7E5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isNew
                      ? const Color(0xFF9CEBCB)
                      : const Color(0xFFFFD56D),
                ),
              ),
              child: Text(
                applicant.status,
                style: TextStyle(
                  color: isNew
                      ? const Color(0xFF009E79)
                      : const Color(0xFFB36A00),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostedJobCard extends StatelessWidget {
  const _PostedJobCard({required this.job});

  final _EmployerJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline, color: Color(0xFF00999D), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    color: Color(0xFF0D1B2E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${job.category} • ${job.verification}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF91A2BC)),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.worker, required this.onTap});

  final _Worker worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE4EC)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE0F4F2),
                  child: Text(
                    worker.name.substring(0, 1),
                    style: const TextStyle(
                      color: Color(0xFF008C96),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              worker.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0D1B2E),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF00999D),
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${worker.trade} • ${worker.experience}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  worker.match,
                  style: const TextStyle(
                    color: Color(0xFF009E79),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 5,
              children: worker.licenses
                  .map(
                    (license) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2E),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        license,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00999D),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationOption extends StatelessWidget {
  const _VerificationOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF00999D) : const Color(0xFFDCE4EC),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFF00999D)
                  : const Color(0xFF91A2BC),
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF0D1B2E)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Worker {
  const _Worker({
    required this.name,
    required this.trade,
    required this.experience,
    required this.licenses,
    required this.match,
  });

  final String name;
  final String trade;
  final String experience;
  final List<String> licenses;
  final String match;
}

class _Applicant {
  const _Applicant({
    required this.name,
    required this.trade,
    required this.match,
    required this.status,
  });

  final String name;
  final String trade;
  final String match;
  final String status;
}

class _EmployerJob {
  const _EmployerJob({
    required this.title,
    required this.category,
    required this.verification,
  });

  final String title;
  final String category;
  final String verification;
}
