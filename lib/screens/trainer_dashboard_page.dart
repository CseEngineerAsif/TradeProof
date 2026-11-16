import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';
import 'common_interface_page.dart';
import 'connections_page.dart';

const _teal = Color(0xFF00999D);
const _navy = Color(0xFF10243B);
const _muted = Color(0xFF64748B);

// This dashboard groups the trainer's overview, course list, learners, and profile.
class TrainerDashboardPage extends StatefulWidget {
  const TrainerDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  State<TrainerDashboardPage> createState() => _TrainerDashboardPageState();
}

// The selected tab and trainer data are stored here.
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
  final _learnerSearchController = TextEditingController();

  final List<_TrainingCourse> _courses = [
    _TrainingCourse(
      title: 'Electrical Installation & Safety',
      category: 'Electrical',
      duration: '6 weeks',
      fee: '৳2,500',
      learners: 18,
      status: 'ENROLLING',
      icon: Icons.electrical_services_outlined,
    ),
    _TrainingCourse(
      title: 'Solar PV Installation Workshop',
      category: 'Solar & Tech',
      duration: '3 weeks',
      fee: '৳2,800',
      learners: 12,
      status: 'ENROLLING',
      icon: Icons.solar_power_outlined,
    ),
    _TrainingCourse(
      title: 'Workplace Safety Assessment',
      category: 'Safety',
      duration: '2 days',
      fee: '৳1,200',
      learners: 24,
      status: 'ACTIVE',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  final List<_Learner> _learners = [
    _Learner(
      name: 'Arif Hossain',
      course: 'Electrical Installation & Safety',
      progress: 82,
      status: 'Ready for assessment',
    ),
    _Learner(
      name: 'Nusrat Jahan',
      course: 'Solar PV Installation Workshop',
      progress: 64,
      status: 'In progress',
    ),
    _Learner(
      name: 'Tanvir Ahmed',
      course: 'Electrical Installation & Safety',
      progress: 100,
      status: 'Assessment pending',
    ),
    _Learner(
      name: 'Sadia Rahman',
      course: 'Workplace Safety Assessment',
      progress: 100,
      status: 'Certified',
    ),
  ];

  int _selectedIndex = 0;
  bool _isCreatingCourse = false;
  String _learnerQuery = '';

  @override
  void dispose() {
    _courseTitleController.dispose();
    _courseCategoryController.dispose();
    _courseDurationController.dispose();
    _courseFeeController.dispose();
    _learnerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build each trainer tab and show the selected one.
    final pages = <Widget>[
      const DashboardPage(showHeader: false, trainerHome: true),
      _buildDashboard(),
      _isCreatingCourse ? _buildCourseForm() : _buildCourses(),
      _buildLearners(),
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
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

  // Builds the trainer summary cards and quick status metrics.
  // Shows course and learner counts with shortcuts to common tasks.
  Widget _buildDashboard() {
    final readyCount = _learners
        .where((learner) => learner.status == 'Ready for assessment')
        .length;
    final pendingCount = _learners
        .where((learner) => learner.status == 'Assessment pending')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'Trainer Dashboard',
          subtitle: 'Your training and assessment overview',
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Active Courses',
                value: '${_courses.length}',
                icon: Icons.menu_book_outlined,
                color: _teal,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _MetricCard(
                title: 'My Learners',
                value: '${_learners.length}',
                icon: Icons.people_outline,
                color: const Color(0xFF6754C8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Assessments',
                value: '$pendingCount',
                icon: Icons.fact_check_outlined,
                color: const Color(0xFFDB8A22),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _MetricCard(
                title: 'Ready to assess',
                value: '$readyCount',
                icon: Icons.assignment_turned_in_outlined,
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
              'Create a course',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
        SizedBox(
          height: 43,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _selectedIndex = 3),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text(
              'Review learners',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _sectionTitle('Upcoming assessments')),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 3),
              child: const Text(
                'View all',
                style: TextStyle(color: _teal, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ..._learners
            .where(
              (learner) =>
                  learner.status == 'Ready for assessment' ||
                  learner.status == 'Assessment pending',
            )
            .map(
              (learner) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LearnerCard(
                  learner: learner,
                  onTap: () => _showLearner(learner),
                ),
              ),
            ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _sectionTitle('Your courses')),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: const Text(
                'View all',
                style: TextStyle(color: _teal, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ..._courses
            .take(2)
            .map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CourseCard(
                  course: course,
                  onTap: () => _showCourse(course),
                ),
              ),
            ),
      ],
    );
  }

  // Lists the trainer's courses and lets them start a new course.
  Widget _buildCourses() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'My Courses',
          subtitle: 'Create and manage your training programs.',
          trailing: IconButton.filled(
            tooltip: 'Create course',
            onPressed: _openCourseForm,
            style: IconButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryBanner(
          icon: Icons.menu_book_outlined,
          title: '${_courses.length} training programs',
          subtitle: 'Track enrollment and share practical learning plans.',
        ),
        const SizedBox(height: 12),
        if (_isCreatingCourse) ...[
          _buildCourseForm(),
          const SizedBox(height: 10),
        ],
        for (final course in _courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _CourseCard(
              course: course,
              onTap: () => _showCourse(course),
            ),
          ),
      ],
    );
  }

  // Collects the details for a course the trainer wants to publish.
  Widget _buildCourseForm() {
    return Form(
      key: _courseFormKey,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create training course',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close course form',
                  onPressed: () => setState(() => _isCreatingCourse = false),
                  icon: const Icon(Icons.close, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                onPressed: _saveCourse,
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text('Add course'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isCreatingCourse = false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
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

  // Lists learners and lets the trainer review their progress.
  Widget _buildLearners() {
    final query = _learnerQuery.trim().toLowerCase();
    final visibleLearners = _learners.where((learner) {
      return query.isEmpty ||
          learner.name.toLowerCase().contains(query) ||
          learner.course.toLowerCase().contains(query) ||
          learner.status.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _pageTitle(
          title: 'My Learners',
          subtitle: 'Track progress and review competency assessments.',
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
          '${visibleLearners.length} ${visibleLearners.length == 1 ? 'learner' : 'learners'}',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        for (final learner in visibleLearners)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _LearnerCard(
              learner: learner,
              onTap: () => _showLearner(learner),
            ),
          ),
        if (visibleLearners.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 36),
            child: Center(
              child: Text(
                'No learners match your search.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  // Shows the trainer's connection requests and conversations.
  Widget _buildMessages() {
    return const ConnectionsPage();
  }

  // Shows trainer details and account actions.
  Widget _buildProfile() {
    final user = widget.isDemo ? null : FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : widget.isDemo
        ? 'Trainer Demo'
        : 'Trainer Account';
    final email = user?.email ?? (widget.isDemo ? 'Demo trainer account' : '');

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
        const SizedBox(height: 12),
        _SummaryBanner(
          icon: Icons.workspace_premium_outlined,
          title: 'Training impact',
          subtitle:
              '${_courses.length} courses · ${_learners.length} learners · ${_learners.where((learner) => learner.status == 'Certified').length} certified',
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

  // Switches to the course tab and opens its form.
  void _openCourseForm() {
    setState(() {
      _selectedIndex = 2;
      _isCreatingCourse = true;
    });
  }

  Future<void> _saveCourse() async {
    // Validate the course form and add its details to the course list.
    if (!_courseFormKey.currentState!.validate()) return;
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
    try {
      await ConnectionService.publishPost(
        type: 'course',
        title: title,
        category: category,
        description: '$duration · Course fee: $fee',
        priceBdt: feeBdt,
      );
    } catch (error) {
      if (mounted) _showMessage(authErrorMessage(error));
      return;
    }
    if (!mounted) return;
    setState(() {
      _courses.insert(
        0,
        _TrainingCourse(
          title: title,
          category: category,
          duration: duration,
          fee: fee,
          learners: 0,
          status: 'DRAFT',
          icon: Icons.school_outlined,
        ),
      );
      _isCreatingCourse = false;
      _courseTitleController.clear();
      _courseCategoryController.clear();
      _courseDurationController.clear();
      _courseFeeController.clear();
    });
    _showMessage('Course published to TradeProof accounts.');
  }

  // Opens a summary of the selected course.
  void _showCourse(_TrainingCourse course) {
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
              '${course.category} · ${course.duration} · ${course.fee}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '${course.learners} learners · ${course.status}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Opens learner progress and assessment actions.
  void _showLearner(_Learner learner) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              learner.name,
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              learner.course,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 13),
            Text(
              '${learner.progress}% course progress',
              style: const TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(
              value: learner.progress / 100,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              color: _teal,
              backgroundColor: const Color(0xFFDCE4EC),
            ),
            const SizedBox(height: 9),
            Text(
              'Status: ${learner.status}',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            if (learner.status == 'Ready for assessment' ||
                learner.status == 'Assessment pending') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _markCertified(learner);
                  },
                  icon: const Icon(Icons.verified_outlined, size: 17),
                  label: const Text('Mark assessment complete'),
                  style: FilledButton.styleFrom(backgroundColor: _teal),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markCertified(_Learner learner) {
    // Update the learner's status after marking them as certified.
    setState(() {
      learner
        ..status = 'Certified'
        ..progress = 100;
    });
    _showMessage('${learner.name} marked as certified in this session.');
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

  final _TrainingCourse course;
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
                child: Icon(course.icon, color: _teal, size: 21),
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
                      '${course.category} · ${course.duration} · ${course.learners} learners',
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
                    course.fee,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _StatusBadge(label: course.status),
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
  const _LearnerCard({required this.learner, required this.onTap});

  final _Learner learner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = learner.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
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
                      learner.name,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      learner.course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 9),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: learner.progress / 100,
                        minHeight: 5,
                        color: _teal,
                        backgroundColor: const Color(0xFFE8EDF2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${learner.progress}% complete',
                      style: const TextStyle(color: _muted, fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _StatusBadge(label: learner.status)),
            ],
          ),
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
    final certified = label == 'Certified';
    final needsAction =
        label == 'Ready for assessment' || label == 'Assessment pending';
    final color = certified
        ? const Color(0xFF008A68)
        : needsAction
        ? const Color(0xFFB36A00)
        : const Color(0xFF008C95);
    final background = certified
        ? const Color(0xFFEAFBF5)
        : needsAction
        ? const Color(0xFFFFF6E5)
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

class _TrainingCourse {
  _TrainingCourse({
    required this.title,
    required this.category,
    required this.duration,
    required this.fee,
    required this.learners,
    required this.status,
    required this.icon,
  });

  final String title;
  final String category;
  final String duration;
  final String fee;
  final int learners;
  final String status;
  final IconData icon;
}

class _Learner {
  _Learner({
    required this.name,
    required this.course,
    required this.progress,
    required this.status,
  });

  final String name;
  final String course;
  int progress;
  String status;
}
