import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';
import 'common_interface_page.dart';
import 'connections_page.dart';

const _teal = Color(0xFF00999D);
const _navy = Color(0xFF10243B);
const _muted = Color(0xFF64748B);

// Groups the trainer's courses, learners, connections, and account details.
class TrainerDashboardPage extends StatefulWidget {
  const TrainerDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  State<TrainerDashboardPage> createState() => _TrainerDashboardPageState();
}

// Owns trainer tab selection, course forms, and search filters.
class _TrainerDashboardPageState extends State<TrainerDashboardPage> {
  static const _teal = Color(0xFF00999D);
  static const _navy = Color(0xFF10243B);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFDCE4EC);
  static const _background = Color(0xFFF3F5F8);

  final _courseFormKey = GlobalKey<FormState>();
  final _courseTitleController = TextEditingController();
  final _courseCategoryController = TextEditingController();
  final _courseDurationController = TextEditingController();
  final _courseFeeController = TextEditingController();
  final _courseSearchController = TextEditingController();
  final _learnerSearchController = TextEditingController();

  int _selectedIndex = 0;
  bool _isCreatingCourse = false;
  bool _isSavingCourse = false;
  String _courseQuery = '';
  String _learnerQuery = '';

  @override
  void dispose() {
    _courseTitleController.dispose();
    _courseCategoryController.dispose();
    _courseDurationController.dispose();
    _courseFeeController.dispose();
    _courseSearchController.dispose();
    _learnerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the trainer's navigation aligned with course and enrollment flows.
    final pages = <Widget>[
      DashboardPage(
        showHeader: false,
        trainerHome: true,
        onEmployerSearch: _searchCourses,
      ),
      _isCreatingCourse ? _buildCourseForm() : _buildCourses(),
      _buildLearners(),
      _buildMessages(),
      _buildDashboard(),
      _buildProfile(),
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
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Learners',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Connections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
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

  void _searchCourses(String query) {
    setState(() {
      _courseQuery = query;
      _courseSearchController.text = query;
      _isCreatingCourse = false;
      _selectedIndex = 1;
    });
  }

  // Shows live course and enrollment activity from the shared account system.
  Widget _buildDashboard() {
    return StreamBuilder<List<MarketplacePost>>(
      stream: ConnectionService.watchMyPosts(type: 'course'),
      builder: (context, coursesSnapshot) {
        if (coursesSnapshot.hasError) {
          return _notice('Could not load courses: ${coursesSnapshot.error}');
        }
        if (!coursesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<ConnectionRequest>>(
          stream: ConnectionService.watchRequests(incoming: true),
          builder: (context, requestsSnapshot) {
            if (requestsSnapshot.hasError) {
              return _notice(
                'Could not load learner enrollments: ${requestsSnapshot.error}',
              );
            }
            if (!requestsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final courses = coursesSnapshot.data!;
            final enrollments = requestsSnapshot.data!
                .where((request) => request.type == 'course')
                .toList();
            final pending = enrollments
                .where((request) => request.status == 'pending')
                .length;
            final acceptedLearners = enrollments
                .where((request) => request.status == 'accepted')
                .length;
            final openEnrollments = enrollments
                .where((request) => request.status != 'rejected')
                .length;
            final activeCourses = courses
                .where((course) => course.status == 'published')
                .length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              children: [
                _pageTitle(
                  title: 'Training overview',
                  subtitle: 'Courses and learner enrollments at a glance.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Published courses',
                        value: '$activeCourses',
                        icon: Icons.menu_book_outlined,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricCard(
                        title: 'Pending enrollments',
                        value: '$pending',
                        icon: Icons.mark_email_unread_outlined,
                        color: const Color(0xFFDB8A22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Accepted learners',
                        value: '$acceptedLearners',
                        icon: Icons.people_outline,
                        color: const Color(0xFF6754C8),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricCard(
                        title: 'Open enrollments',
                        value: '$openEnrollments',
                        icon: Icons.groups_outlined,
                        color: const Color(0xFF008A68),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 45,
                  child: FilledButton.icon(
                    onPressed: _openCourseForm,
                    icon: const Icon(Icons.add, size: 19),
                    label: const Text(
                      'Publish a course',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text('Review enrollments'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _line),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _sectionTitle('Recent courses')),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (courses.isEmpty)
                  _notice(
                    'Publish your first course to make it available to learners.',
                  )
                else
                  for (final course in courses.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CourseCard(
                        course: course,
                        onTap: () => _showCourse(course),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  // Lists the trainer's courses and lets them start a new course.
  Widget _buildCourses() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Courses',
          subtitle: 'Publish and manage your training programs.',
          trailing: IconButton.filled(
            tooltip: 'Publish course',
            onPressed: _openCourseForm,
            style: IconButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _courseSearchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _courseQuery = value),
          decoration: _inputDecoration(hint: 'Search course or trade').copyWith(
            prefixIcon: const Icon(Icons.search, color: _muted),
            suffixIcon: _courseQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _courseSearchController.clear();
                      setState(() => _courseQuery = '');
                    },
                    icon: const Icon(Icons.close, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<MarketplacePost>>(
          stream: ConnectionService.watchMyPosts(type: 'course'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _notice('Could not load courses: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final courses = snapshot.data!;
            final query = _courseQuery.trim().toLowerCase();
            final visibleCourses = courses.where((course) {
              return query.isEmpty ||
                  '${course.title} ${course.category} ${course.description}'
                      .toLowerCase()
                      .contains(query);
            }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryBanner(
                  icon: Icons.menu_book_outlined,
                  title:
                      '${courses.where((course) => course.status == 'published').length} published courses',
                  subtitle:
                      'Your listings are shared with learners on TradeProof.',
                ),
                const SizedBox(height: 10),
                if (visibleCourses.isEmpty)
                  _notice(
                    query.isEmpty
                        ? 'No courses yet. Publish a course to reach learners.'
                        : 'No courses match "$_courseQuery".',
                  )
                else
                  for (final course in visibleCourses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _CourseCard(
                        course: course,
                        onTap: () => _showCourse(course),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Collects the details for a course the trainer wants to publish.
  Widget _buildCourseForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Publish a course',
          subtitle: 'Share your training with learners on TradeProof.',
          trailing: IconButton(
            tooltip: 'Close course form',
            onPressed: _isSavingCourse
                ? null
                : () => setState(() => _isCreatingCourse = false),
            icon: const Icon(Icons.close),
          ),
        ),
        const SizedBox(height: 14),
        Form(
          key: _courseFormKey,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _courseField(
                  controller: _courseTitleController,
                  label: 'Course title',
                  hint: 'e.g. Electrical Installation & Safety',
                ),
                const SizedBox(height: 10),
                _courseField(
                  controller: _courseCategoryController,
                  label: 'Trade category',
                  hint: 'e.g. Electrical',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _courseField(
                        controller: _courseDurationController,
                        label: 'Duration',
                        hint: 'e.g. 4 weeks',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _courseField(
                        controller: _courseFeeController,
                        label: 'Course fee',
                        hint: 'e.g. ৳2,000',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 43,
                  child: FilledButton(
                    onPressed: _isSavingCourse ? null : _saveCourse,
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _isSavingCourse
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Publish course'),
                  ),
                ),
                TextButton(
                  onPressed: _isSavingCourse
                      ? null
                      : () => setState(() => _isCreatingCourse = false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _courseField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: _inputDecoration(label: label, hint: hint),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Enter $label.' : null,
    );
  }

  // Lists learners whose course enrollments have been accepted.
  Widget _buildLearners() {
    return StreamBuilder<List<ConnectionRequest>>(
      stream: ConnectionService.watchRequests(incoming: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _notice('Could not load learners: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final query = _learnerQuery.trim().toLowerCase();
        final learners = snapshot.data!
            .where(
              (request) =>
                  request.type == 'course' && request.status == 'accepted',
            )
            .where(
              (request) =>
                  query.isEmpty ||
                  '${request.requesterName} ${request.title}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
          children: [
            _pageTitle(
              title: 'Learners',
              subtitle: 'People enrolled in your courses.',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _learnerSearchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _learnerQuery = value),
              decoration: _inputDecoration(hint: 'Search learner or course')
                  .copyWith(
                    prefixIcon: const Icon(Icons.search, color: _muted),
                    suffixIcon: _learnerQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _learnerSearchController.clear();
                              setState(() => _learnerQuery = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              '${learners.length} ${learners.length == 1 ? 'learner' : 'learners'}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            for (final learner in learners)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _LearnerCard(
                  request: learner,
                  onOpenMessages: () => setState(() => _selectedIndex = 3),
                ),
              ),
            if (learners.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Text(
                    query.isEmpty
                        ? 'Accepted course enrollments will appear here.'
                        : 'No learners match "$_learnerQuery".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Shows the trainer's connection requests and conversations.
  Widget _buildMessages() {
    return const ConnectionsPage(trainerView: true);
  }

  // Shows trainer details and account actions.
  Widget _buildProfile() {
    final user = widget.isDemo ? null : FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : widget.isDemo
        ? ConnectionService.currentUserName ?? 'Trainer Demo'
        : 'Trainer Account';
    final email =
        user?.email ??
        (widget.isDemo
            ? ConnectionService.currentUserEmail ?? 'Demo trainer account'
            : '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Trainer Profile',
          subtitle: 'Your account and teaching overview.',
        ),
        const SizedBox(height: 15),
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
                    const Row(
                      children: [
                        Icon(Icons.verified, color: _teal, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Trainer / Assessor',
                          style: TextStyle(
                            color: _teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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

  Widget _pageTitle({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
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

  InputDecoration _inputDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 11),
      labelStyle: const TextStyle(color: _muted, fontSize: 11),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _teal, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(13),
  );

  Widget _notice(String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: Text(message, style: const TextStyle(color: _muted, fontSize: 11)),
  );

  // Switches to the course tab and opens its form.
  void _openCourseForm() {
    setState(() {
      _selectedIndex = 1;
      _isCreatingCourse = true;
    });
  }

  Future<void> _saveCourse() async {
    if (_isSavingCourse || !_courseFormKey.currentState!.validate()) return;
    final title = _courseTitleController.text.trim();
    final category = _courseCategoryController.text.trim();
    final duration = _courseDurationController.text.trim();
    final fee = _courseFeeController.text.trim();
    final normalizedFee = fee.replaceAll(',', '').replaceAll('৳', '').trim();
    final feeBdt = int.tryParse(normalizedFee);
    if (feeBdt == null || feeBdt <= 0) {
      _showMessage('Enter a course fee in whole Bangladeshi taka.');
      return;
    }
    setState(() => _isSavingCourse = true);
    try {
      await ConnectionService.publishPost(
        type: 'course',
        title: title,
        category: category,
        description: '$duration · Course fee: $fee',
        priceBdt: feeBdt,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isSavingCourse = false);
        _showMessage(authErrorMessage(error));
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSavingCourse = false;
      _isCreatingCourse = false;
      _courseTitleController.clear();
      _courseCategoryController.clear();
      _courseDurationController.clear();
      _courseFeeController.clear();
    });
    _showMessage('Course published to TradeProof accounts.');
  }

  // Opens a summary of the selected course.
  void _showCourse(MarketplacePost course) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
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
            const SizedBox(height: 10),
            Text(
              '${course.category} · ${_formatCourseFee(course.priceBdt)}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Listing status: ${course.status.toUpperCase()}',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // Signs out the user or exits the sample account.
  Future<void> _signOut(BuildContext context) async {
    if (widget.isDemo) {
      ConnectionService.endDemoSession();
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
      if (context.mounted) _showMessage(authErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final MarketplacePost course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDCE4EC)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F6),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.school_outlined,
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
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.category} · ${course.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCourseFee(course.priceBdt),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _StatusBadge(label: course.status.toUpperCase()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({required this.request, required this.onOpenMessages});

  final ConnectionRequest request;
  final VoidCallback onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final initials = request.requesterName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDCE4EC)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFEAF7F6),
              child: Text(
                initials,
                style: const TextStyle(
                  color: _teal,
                  fontSize: 11,
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
                    request.requesterName,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    request.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onOpenMessages,
              icon: const Icon(Icons.chat_bubble_outline, size: 15),
              label: const Text('Message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF008C95), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF10243B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isClosed = label == 'CLOSED';
    final color = isClosed
        ? _muted
        : label == 'ENROLLED'
        ? const Color(0xFF008A68)
        : const Color(0xFF008C95);
    final background = isClosed
        ? const Color(0xFFF1F5F9)
        : label == 'ENROLLED'
        ? const Color(0xFFEAFBF5)
        : const Color(0xFFEAF7F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatCourseFee(int? feeBdt) =>
    feeBdt == null ? 'Fee not set' : '৳$feeBdt';
