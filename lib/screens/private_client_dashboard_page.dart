import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';
import 'common_interface_page.dart';
import 'connections_page.dart';
import 'course_checkout_page.dart';
import 'marketplace_posts_section.dart';

// This dashboard helps a client hire, learn, and review requests in one place.
class PrivateClientDashboardPage extends StatefulWidget {
  const PrivateClientDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  State<PrivateClientDashboardPage> createState() =>
      _PrivateClientDashboardPageState();
}

// The current tab and search filters are managed in this state.
class _PrivateClientDashboardPageState
    extends State<PrivateClientDashboardPage> {
  static const _teal = Color(0xFF00999D);
  static const _navy = Color(0xFF10243B);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFDCE4EC);
  static const _background = Color(0xFFF3F5F8);

  final _hireSearchController = TextEditingController();
  final _learnSearchController = TextEditingController();

  int _selectedIndex = 0;
  String _hireQuery = '';
  String _learnQuery = '';
  String _hireFilter = 'All';

  @override
  void dispose() {
    _hireSearchController.dispose();
    _learnSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Connect each tab to its page and its available actions.
    final pages = <Widget>[
      DashboardPage(
        showHeader: false,
        userHome: true,
        onUserSearch: _searchFromHome,
        onUserHire: (title) =>
            _createRequest(title: title, type: 'Service', openRequests: false),
        onUserJobApply: (title) => _createRequest(
          title: title,
          type: 'Job application',
          openRequests: false,
        ),
        onUserEnroll: (title) =>
            _createRequest(title: title, type: 'Course', openRequests: false),
      ),
      _buildDashboard(),
      _buildHirePage(),
      _buildLearnPage(),
      _buildRequestsPage(),
      _buildMessagesPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _teal,
        unselectedItemColor: const Color(0xFF91A2BC),
        selectedFontSize: 9,
        unselectedFontSize: 9,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman_outlined),
            activeIcon: Icon(Icons.handyman),
            label: 'Hire',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.home),
            label: 'Asif',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Overview screen with fast links to hire, browse courses, and open requests.
  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Your Dashboard',
          subtitle: 'A quick overview of your requests and learning.',
        ),
        const SizedBox(height: 14),
        _buildConnectionSummary(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 43,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  icon: const Icon(Icons.handyman_outlined, size: 17),
                  label: const Text('Hire'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: SizedBox(
                height: 43,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 3),
                  icon: const Icon(Icons.school_outlined, size: 17),
                  label: const Text('Browse courses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedIndex = 4),
            icon: const Icon(Icons.assignment_outlined, size: 16),
            label: const Text('Open requests'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionSummary() {
    if (widget.isDemo) {
      return _emptyState(
        icon: Icons.account_circle_outlined,
        title: 'Sign in to sync connections',
        subtitle: 'Requests and accepted courses are stored with your account.',
      );
    }
    return StreamBuilder<List<ConnectionRequest>>(
      stream: ConnectionService.watchRequests(incoming: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            icon: Icons.error_outline,
            title: 'Could not load request summary',
            subtitle: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final requests = snapshot.data!;
        final pending = requests
            .where((item) => item.status == 'pending')
            .length;
        final enrollments = requests
            .where((item) => item.type == 'course')
            .length;
        final accepted = requests
            .where((item) => item.status == 'accepted')
            .length;
        return Column(
          children: [
            _ProfileStat(
              icon: Icons.assignment_outlined,
              title: 'Pending requests',
              value: '$pending',
            ),
            const SizedBox(height: 8),
            _ProfileStat(
              icon: Icons.school_outlined,
              title: 'Course enrollments',
              value: '$enrollments',
            ),
            const SizedBox(height: 8),
            _ProfileStat(
              icon: Icons.chat_bubble_outline,
              title: 'Accepted connections',
              value: '$accepted',
            ),
          ],
        );
      },
    );
  }

  // Shows marketplace services and workers that the user can hire.
  Widget _buildHirePage() {
    final query = _hireQuery.trim().toLowerCase();
    final workers = marketplaceTradePeople.where((person) {
      final matchesQuery =
          query.isEmpty ||
          person.name.toLowerCase().contains(query) ||
          person.trade.toLowerCase().contains(query) ||
          person.location.toLowerCase().contains(query) ||
          person.skills.any((skill) => skill.toLowerCase().contains(query));
      final matchesFilter =
          _hireFilter == 'All' ||
          (_hireFilter == 'Available now' &&
              person.availability.toLowerCase().contains('immediate')) ||
          (_hireFilter == 'Licensed' && person.license.isNotEmpty);
      return matchesQuery && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Hire a tradesperson',
          subtitle: 'Find verified local professionals for your project.',
        ),
        const SizedBox(height: 14),
        const MarketplacePostsSection(type: 'service'),
        const SizedBox(height: 12),
        TextField(
          controller: _hireSearchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _hireQuery = value),
          decoration: _searchDecoration(
            hint: 'Search trade, skill or location',
            query: _hireQuery,
            onClear: () {
              _hireSearchController.clear();
              setState(() => _hireQuery = '');
            },
          ),
        ),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in ['All', 'Available now', 'Licensed'])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _hireFilter == filter,
                    onSelected: (_) => setState(() => _hireFilter = filter),
                    selectedColor: _teal,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _hireFilter == filter ? Colors.white : _navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _hireFilter == filter ? _teal : _line,
                    ),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _resultCount(workers.length, 'tradesperson'),
        const SizedBox(height: 7),
        for (final person in workers)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _WorkerCard(
              person: person,
              onView: () => _showWorkerDetails(person),
              onHire: () =>
                  _createRequest(title: person.name, type: 'Hire request'),
            ),
          ),
        if (workers.isEmpty)
          _emptyState(
            icon: Icons.search_off,
            title: 'No tradespeople found',
            subtitle: 'Try a different trade, skill or location.',
          ),
      ],
    );
  }

  // Shows training courses that the user can browse and request.
  Widget _buildLearnPage() {
    final query = _learnQuery.trim().toLowerCase();
    final courses = marketplaceTradeCourses.where((course) {
      return query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query) ||
          course.instructor.toLowerCase().contains(query) ||
          course.level.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Learn a new skill',
          subtitle: 'Practical courses taught by experienced trainers.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _learnSearchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _learnQuery = value),
          decoration: _searchDecoration(
            hint: 'Search courses, trade or trainer',
            query: _learnQuery,
            onClear: () {
              _learnSearchController.clear();
              setState(() => _learnQuery = '');
            },
          ),
        ),
        const SizedBox(height: 10),
        const MarketplacePostsSection(type: 'course'),
        const SizedBox(height: 12),
        _resultCount(courses.length, 'course'),
        const SizedBox(height: 7),
        for (final course in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _CourseCard(
              course: course,
              onView: () => _showCourseDetails(course),
              onEnroll: () => _createRequest(
                title: course.title,
                type: 'Course enrollment',
              ),
            ),
          ),
        if (courses.isEmpty)
          _emptyState(
            icon: Icons.school_outlined,
            title: 'No courses found',
            subtitle: 'Try another skill, course or trainer.',
          ),
      ],
    );
  }

  // Shows the connection requests sent by this account.
  Widget _buildRequestsPage() {
    return const ConnectionRequestsPage(incoming: false);
  }

  // Shows requests and conversations with other accounts.
  Widget _buildMessagesPage() {
    return const ConnectionsPage();
  }

  // Shows the user's account information and sign-out action.
  Widget _buildProfilePage() {
    final user = widget.isDemo ? null : FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : widget.isDemo
        ? 'Guest User'
        : 'TradeProof User';
    final email = user?.email ?? (widget.isDemo ? 'Demo account' : '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'My profile',
          subtitle: 'Manage your TradeProof account.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFE0F4F2),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                    const SizedBox(height: 7),
                    const Text(
                      'General User',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _buildConnectionSummary(),
        const SizedBox(height: 17),
        SizedBox(
          height: 45,
          child: OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout, size: 17),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: _line),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _searchFromHome(String query) {
    // Send a home-page search to the matching hire or course tab.
    final normalized = query.toLowerCase();
    final isCourseSearch = marketplaceTradeCourses.any(
      (course) =>
          course.title.toLowerCase().contains(normalized) ||
          course.category.toLowerCase().contains(normalized) ||
          course.instructor.toLowerCase().contains(normalized),
    );

    setState(() {
      if (isCourseSearch && query.isNotEmpty) {
        _learnQuery = query;
        _learnSearchController.text = query;
        _selectedIndex = 3;
      } else {
        _hireQuery = query;
        _hireSearchController.text = query;
        _selectedIndex = 2;
      }
    });
  }

  // Create a request for a selected worker, job, or course.
  Future<void> _createRequest({
    required String title,
    required String type,
    bool openRequests = true,
  }) async {
    final isCourse = type == 'Course' || type == 'Course enrollment';
    try {
      if (isCourse) {
        await openCourseCheckoutForTitle(context, title);
        return;
      }
      await ConnectionService.requestPublishedPostByTitle(
        title: title,
        type: type == 'Job application' ? 'job' : 'service',
      );
      if (!mounted) return;
      if (openRequests) setState(() => _selectedIndex = 4);
      _showMessage('Request sent to the post owner.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  // Opens details for a worker selected from the marketplace.
  void _showWorkerDetails(TradePerson person) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              person.name,
              style: const TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(person.trade, style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            _detailRow(Icons.location_on_outlined, person.location),
            _detailRow(Icons.schedule_outlined, person.availability),
            _detailRow(Icons.workspace_premium_outlined, person.license),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: person.skills
                  .map((skill) => _Tag(label: skill))
                  .toList(),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _createRequest(title: person.name, type: 'Hire request');
                },
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: Text('Request to hire · ${person.rate}'),
                style: FilledButton.styleFrom(backgroundColor: _teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Opens details for a course selected from the marketplace.
  void _showCourseDetails(TradeCourse course) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.category_outlined,
              '${course.category} · ${course.level}',
            ),
            _detailRow(Icons.schedule_outlined, course.duration),
            _detailRow(Icons.person_outline, course.instructor),
            _detailRow(
              Icons.star_outline,
              '${course.rating} · ${course.reviews} reviews',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _createRequest(
                    title: course.title,
                    type: 'Course enrollment',
                  );
                },
                icon: const Icon(Icons.school_outlined, size: 18),
                label: Text('Request enrollment · ${course.price}'),
                style: FilledButton.styleFrom(backgroundColor: _teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }

  Widget _resultCount(int count, String item) => Text(
    '$count ${count == 1 ? item : '${item}s'} found',
    style: const TextStyle(
      color: _muted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _searchDecoration({
    required String hint,
    required String query,
    required VoidCallback onClear,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 11),
      prefixIcon: const Icon(Icons.search, color: _muted, size: 19),
      suffixIcon: query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _teal, width: 1.4),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 38),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF91A2BC), size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(13),
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Signs out the user or returns from the demo account.
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.person,
    required this.onView,
    required this.onHire,
  });

  final TradePerson person;
  final VoidCallback onView;
  final VoidCallback onHire;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFE0F4F2),
                child: Text(
                  person.name.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF00999D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      person.trade,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: Color(0xFF00999D), size: 17),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${person.location} · ${person.availability}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              ...person.skills.map((skill) => _Tag(label: skill)),
              _Tag(label: 'License ${person.license}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                person.rate,
                style: const TextStyle(
                  color: Color(0xFF10243B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                ' / visit',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
              ),
              const Spacer(),
              TextButton(
                onPressed: onView,
                child: const Text(
                  'Details',
                  style: TextStyle(color: Color(0xFF008C95), fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: onHire,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00999D),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Hire',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onView,
    required this.onEnroll,
  });

  final TradeCourse course;
  final VoidCallback onView;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F6),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFF00999D),
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF10243B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${course.category} · ${course.duration}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                ),
                const SizedBox(height: 3),
                Text(
                  '${course.instructor} · ★ ${course.rating}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      course.price,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onView,
                      child: const Text(
                        'Details',
                        style: TextStyle(
                          color: Color(0xFF008C95),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: onEnroll,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00999D),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text(
                          'Learn',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00999D), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF087F7D),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
