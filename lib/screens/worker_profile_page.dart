import 'package:flutter/material.dart';

// This page shows a worker's identity, match score, and profile details.
class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({
    super.key,
    required this.name,
    required this.trade,
    required this.experience,
    required this.credentials,
    required this.match,
  });

  final String name;
  final String trade;
  final String experience;
  final List<String> credentials;
  final String match;

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

// The selected profile tab controls which section is shown.
class _WorkerProfilePageState extends State<WorkerProfilePage> {
  static const _teal = Color(0xFF00999D);
  static const _navy = Color(0xFF10243B);
  static const _muted = Color(0xFF64748B);
  static const _background = Color(0xFFF3F5F8);
  static const _border = Color(0xFFDCE4EC);

  int _selectedSection = 0;

  // Creates example projects that match the worker's trade.
  List<_PortfolioItem> get _projects {
    final trade = widget.trade.toLowerCase();
    if (trade.contains('solar')) {
      return const [
        _PortfolioItem(
          title: 'Rooftop Solar Installation',
          client: 'Residential project',
          date: 'Completed 2025',
          description:
              'Installed rooftop solar equipment and checked system connections and safe operation.',
          icon: Icons.solar_power_outlined,
        ),
        _PortfolioItem(
          title: 'Grid Connection & Testing',
          client: 'Commercial project',
          date: 'Completed 2024',
          description:
              'Connected a solar installation to the grid and performed commissioning checks.',
          icon: Icons.electrical_services_outlined,
        ),
      ];
    }
    if (trade.contains('electric') || trade.contains('wire')) {
      return const [
        _PortfolioItem(
          title: 'Commercial Electrical Upgrade',
          client: 'Commercial project',
          date: 'Completed 2025',
          description:
              'Upgraded electrical circuits and distribution equipment, then completed operational checks.',
          icon: Icons.electrical_services_outlined,
        ),
        _PortfolioItem(
          title: 'Safety Inspection & Wiring',
          client: 'Residential project',
          date: 'Completed 2024',
          description:
              'Inspected wiring, documented safety issues, and completed approved electrical repairs.',
          icon: Icons.fact_check_outlined,
        ),
      ];
    }
    return [
      _PortfolioItem(
        title: '${widget.trade} Installation & Repair',
        client: 'Residential project',
        date: 'Completed 2025',
        description:
            'Completed a trade-specific installation and recorded quality and safety checks.',
        icon: Icons.handyman_outlined,
      ),
      _PortfolioItem(
        title: 'Site Maintenance Project',
        client: 'Commercial project',
        date: 'Completed 2024',
        description:
            'Delivered planned site maintenance and verified the work against project requirements.',
        icon: Icons.construction_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Use the first letters of the worker's name as the profile avatar.
    final initials = widget.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Worker profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        children: [
          _buildIdentityCard(initials),
          const SizedBox(height: 12),
          _buildStats(),
          const SizedBox(height: 18),
          _buildSectionSelector(),
          const SizedBox(height: 12),
          if (_selectedSection == 0) _buildOverview(),
          if (_selectedSection == 1) _buildPortfolio(),
          if (_selectedSection == 2) _buildCredentials(),
        ],
      ),
    );
  }

  // Shows the worker's name, trade, match score, and contact action.
  Widget _buildIdentityCard(String initials) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 39,
                backgroundColor: const Color(0xFFE0F4F2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: _teal, size: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.trade,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFBF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.match} job match',
              style: const TextStyle(
                color: Color(0xFF008A68),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Messaging is not connected in this demo yet.',
                    ),
                  ),
                ),
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: const Text(
                'Contact worker',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shows counts and key facts about the worker's profile.
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _ProfileStat(
            icon: Icons.workspace_premium_outlined,
            value: '${widget.credentials.length}',
            label: 'Credentials',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ProfileStat(
            icon: Icons.work_history_outlined,
            value: widget.experience,
            label: 'Experience',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ProfileStat(
            icon: Icons.folder_open_outlined,
            value: '${_projects.length}',
            label: 'Projects',
          ),
        ),
      ],
    );
  }

  // Lets the viewer switch between the profile sections.
  Widget _buildSectionSelector() {
    const labels = ['Overview', 'Portfolio', 'Credentials'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSection = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _selectedSection == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedSection == index
                        ? const [
                            BoxShadow(
                              color: Color(0x120D1B2E),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedSection == index ? _teal : _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Shows a short summary of the worker's experience and skills.
  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Professional summary'),
        const SizedBox(height: 8),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.experience} of experience as a ${widget.trade.toLowerCase()}.',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Profile highlights, work samples and listed credentials are available for employer review.',
                style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _sectionTitle('Featured work')),
            TextButton(
              onPressed: () => setState(() => _selectedSection = 1),
              child: const Text(
                'See all',
                style: TextStyle(color: _teal, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _projectCard(_projects.first),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _sectionTitle('Credentials')),
            TextButton(
              onPressed: () => setState(() => _selectedSection = 2),
              child: const Text(
                'See all',
                style: TextStyle(color: _teal, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ...widget.credentials.take(2).map(_credentialCard),
      ],
    );
  }

  // Lists example projects from the worker's portfolio.
  Widget _buildPortfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Work portfolio'),
        const SizedBox(height: 4),
        const Text(
          'Project highlights shared by this tradesperson.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        ..._projects.map(_projectCard),
      ],
    );
  }

  // Lists the worker's verified certificates and licenses.
  Widget _buildCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Credentials & licenses'),
        const SizedBox(height: 4),
        const Text(
          'Review the credentials listed on this profile.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        if (widget.credentials.isEmpty)
          _card(
            child: const Text(
              'No credentials have been added to this profile.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          )
        else
          ...widget.credentials.map(_credentialCard),
        const SizedBox(height: 5),
        const Text(
          'Confirm original documents before assigning regulated work.',
          style: TextStyle(color: _muted, fontSize: 10, height: 1.4),
        ),
      ],
    );
  }

  // Builds one project card with its title and work details.
  Widget _projectCard(_PortfolioItem project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F6),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(project.icon, color: _teal, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${project.client} · ${project.date}',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    project.description,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds one credential card.
  Widget _credentialCard(String credential) {
    final isOsha = credential.toLowerCase().contains('osha');
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _card(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOsha
                    ? Icons.health_and_safety_outlined
                    : Icons.workspace_premium_outlined,
                color: _teal,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credential,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Listed on worker profile',
                    style: TextStyle(color: _muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_outlined, color: _teal, size: 19),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: _navy,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    ),
  );

  // Applies the shared card background and border style.
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: child,
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _border),
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x080D1B2E), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00999D), size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _PortfolioItem {
  const _PortfolioItem({
    required this.title,
    required this.client,
    required this.date,
    required this.description,
    required this.icon,
  });

  final String title;
  final String client;
  final String date;
  final String description;
  final IconData icon;
}
