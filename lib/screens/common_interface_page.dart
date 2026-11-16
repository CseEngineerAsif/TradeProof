import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connection_service.dart';
import 'course_checkout_page.dart';
import 'marketplace_posts_section.dart';
import 'trade_details_page.dart';

// Reusable helpers for opening details and sending a marketplace request.
void _requestMarketplacePost(
  BuildContext context, {
  required String title,
  required String type,
}) {
  unawaited(() async {
    try {
      if (type == 'course') {
        await openCourseCheckoutForTitle(context, title);
        return;
      }
      await ConnectionService.requestPublishedPostByTitle(
        title: title,
        type: type,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent to the post owner.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }());
}

void _openTradeDetails(BuildContext context, TradeDetailsPage page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

// Build the job detail view shown when a user taps a matching opportunity.
TradeDetailsPage _jobDetails(
  BuildContext context,
  TradeJob job, {
  VoidCallback? onAction,
}) {
  return TradeDetailsPage(
    title: job.title,
    provider: job.client,
    location: job.location,
    primaryLabel: 'Budget / Rate',
    primaryValue: job.budget,
    secondaryLabel: 'Applicants',
    secondaryValue: '${job.applicants} applied',
    description: job.description,
    sections: [
      TradeDetailsSection(title: 'Required Skills & Certs', items: job.tags),
      TradeDetailsSection(
        title: 'Job Information',
        items: [
          'Posted by ${job.client}',
          'Service location: ${job.location}',
          'Current applications: ${job.applicants}',
        ],
      ),
    ],
    actionLabel: 'Apply for Job',
    onAction:
        onAction ??
        () => _requestMarketplacePost(context, title: job.title, type: 'job'),
  );
}

TradeDetailsPage _courseDetails(
  BuildContext context,
  TradeCourse course, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return TradeDetailsPage(
    title: course.title,
    provider: course.instructor,
    location: '${course.category} Training',
    primaryLabel: 'Course Fee',
    primaryValue: course.price,
    secondaryLabel: 'Rating',
    secondaryValue: '${course.rating} / 5',
    description:
        'Build practical ${course.category.toLowerCase()} skills through '
        '${course.level.toLowerCase()} training. The course runs for '
        '${course.duration.toLowerCase()} and is led by ${course.instructor}.',
    sections: [
      TradeDetailsSection(
        title: 'Course Overview',
        items: [
          'Category: ${course.category}',
          'Level: ${course.level}',
          'Duration: ${course.duration}',
          'Instructor: ${course.instructor}',
          '${course.reviews} learner reviews',
        ],
      ),
      TradeDetailsSection(
        title: 'Included',
        items: [
          course.title,
          'QR-verifiable course license',
          'TradeProof grant may cover up to 60% of the course fee',
        ],
      ),
    ],
    actionLabel: actionLabel ?? 'Enroll in Course',
    onAction:
        onAction ??
        () => _requestMarketplacePost(
          context,
          title: course.title,
          type: 'course',
        ),
  );
}

TradeDetailsPage _tradespersonDetails(
  BuildContext context,
  TradePerson person, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return TradeDetailsPage(
    title: 'Tradesperson Profile',
    provider: person.name,
    location: person.location,
    primaryLabel: 'Visit Rate',
    primaryValue: person.rate,
    secondaryLabel: 'Availability',
    secondaryValue: person.availability,
    description:
        '${person.name} is a verified ${person.trade.toLowerCase()} '
        'available in ${person.location}.',
    sections: [
      TradeDetailsSection(title: 'Skills & Experience', items: person.skills),
      TradeDetailsSection(
        title: 'Verified Credentials',
        items: ['${person.trade} license: ${person.license}'],
      ),
    ],
    actionLabel: actionLabel ?? 'Book Service',
    onAction:
        onAction ??
        () => _requestMarketplacePost(
          context,
          title: person.name,
          type: 'service',
        ),
  );
}

TradeDetailsPage _trainerDetails(
  BuildContext context,
  TradeTrainer trainer, {
  String? actionLabel,
}) {
  final trainerName = trainer.name.toLowerCase();
  final matchingCourses = _courses
      .where(
        (course) =>
            course.instructor.toLowerCase().contains(trainerName) ||
            trainerName.contains(course.instructor.toLowerCase()) ||
            trainer.qualification.toLowerCase().contains(
              course.category.toLowerCase().split(' ').first,
            ),
      )
      .map((course) => '${course.title} (${course.duration}, ${course.price})')
      .toList();

  return TradeDetailsPage(
    title: 'Trainer Profile',
    provider: trainer.name,
    location: 'TradeProof Verified Trainer',
    primaryLabel: 'Learners Certified',
    primaryValue: trainer.certification,
    secondaryLabel: 'Rating / Experience',
    secondaryValue: trainer.rating,
    description:
        '${trainer.name} is a verified trainer with expertise in '
        '${trainer.qualification.toLowerCase()}.',
    sections: [
      TradeDetailsSection(
        title: 'Qualifications & Certifications',
        items: [trainer.qualification, trainer.certification, trainer.rating],
      ),
      TradeDetailsSection(
        title: 'Courses',
        items: matchingCourses.isEmpty
            ? ['Contact ${trainer.name} to check current course availability.']
            : matchingCourses,
      ),
    ],
    actionLabel: actionLabel ?? 'View Courses',
    onAction: () =>
        _requestMarketplacePost(context, title: trainer.name, type: 'course'),
  );
}

TradeDetailsPage _employerDetails(
  BuildContext context,
  HiringEmployer employer, {
  String? actionLabel,
}) {
  return TradeDetailsPage(
    title: 'Featured Job',
    provider: employer.name,
    location: employer.location,
    primaryLabel: 'Featured Project Pay',
    primaryValue: employer.pay,
    secondaryLabel: 'Open Jobs',
    secondaryValue: '${employer.jobs}',
    description:
        '${employer.name} works in ${employer.specialty.toLowerCase()}. '
        'Explore the featured project and review the payment terms before '
        'applying.',
    sections: [
      TradeDetailsSection(
        title: 'Featured Work & Pay',
        items: [
          employer.project,
          'Project pay: ${employer.pay}',
          'Project location: ${employer.location}',
        ],
      ),
      TradeDetailsSection(
        title: 'Employer Information',
        items: [
          'Specialty: ${employer.specialty}',
          '${employer.jobs} jobs posted',
          employer.guarantee,
        ],
      ),
    ],
    actionLabel: actionLabel ?? 'View Jobs',
    onAction: () =>
        _requestMarketplacePost(context, title: employer.name, type: 'job'),
  );
}

// Shows the marketplace dashboard and controls which sections are visible.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.showHeader = true,
    this.showTradespeople = true,
    this.employerHome = false,
    this.trainerHome = false,
    this.userHome = false,
    this.onEmployerSearch,
    this.onUserHire,
    this.onUserJobApply,
    this.onUserEnroll,
    this.onUserSearch,
  });

  final bool showHeader;
  final bool showTradespeople;
  final bool employerHome;
  final bool trainerHome;
  final bool userHome;
  final ValueChanged<String>? onEmployerSearch;
  final ValueChanged<String>? onUserHire;
  final ValueChanged<String>? onUserJobApply;
  final ValueChanged<String>? onUserEnroll;
  final ValueChanged<String>? onUserSearch;

  // Shared colors used across the dashboard.
  static const _green = Color(0xFF009E79);
  static const _navy = Color(0xFF071126);
  static const _ink = Color(0xFF10243B);
  static const _muted = Color(0xFF78879A);

  @override
  Widget build(BuildContext context) {
    // Arranges the dashboard sections in a scrollable page.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader) const _DashboardHeader(),
              _HeroSection(trainerHome: trainerHome),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 14, 11, 8),
                child: Column(
                  children: [
                    _SearchBar(
                      onSearch: onEmployerSearch,
                      trainerHome: trainerHome,
                      userHome: userHome,
                      onUserSearch: onUserSearch,
                    ),
                    const SizedBox(height: 14),
                    const MarketplacePostsSection(),
                    const SizedBox(height: 14),
                    if (userHome) ...[
                      _SectionCarousel<TradeJob>(
                        title: 'Featured Service Requests',
                        icon: Icons.handyman_outlined,
                        items: _jobs,
                        height: 134,
                        itemBuilder: (context, item, index) => _JobCard(
                          job: item,
                          index: index,
                          onBook: () {
                            Navigator.of(context).pop();
                            onUserJobApply?.call(item.title);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradePerson>(
                        title: 'Top Tradespeople',
                        icon: Icons.people_outline,
                        items: _tradespeople,
                        height: 148,
                        itemBuilder: (context, item, index) =>
                            _TradespersonCard(
                              person: item,
                              index: index,
                              onHire: () {
                                Navigator.of(context).pop();
                                onUserHire?.call(item.name);
                              },
                            ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradeCourse>(
                        title: 'Skill Courses',
                        icon: Icons.school_outlined,
                        items: _courses,
                        height: 180,
                        itemBuilder: (context, item, index) => _CourseCard(
                          course: item,
                          index: index,
                          onEnroll: () {
                            Navigator.of(context).pop();
                            onUserEnroll?.call(item.title);
                          },
                        ),
                      ),
                    ] else if (trainerHome) ...[
                      _SectionCarousel<TradeCourse>(
                        title: 'Featured Training Courses',
                        icon: Icons.school_outlined,
                        items: _courses,
                        height: 180,
                        itemBuilder: (context, item, index) =>
                            _CourseCard(course: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradeTrainer>(
                        title: 'Top Trainers & Assessors',
                        icon: Icons.workspace_premium_outlined,
                        items: _trainers,
                        height: 124,
                        itemBuilder: (context, item, index) =>
                            _TrainerCard(trainer: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradePerson>(
                        title: 'Tradespeople to Train',
                        icon: Icons.people_outline,
                        items: _tradespeople,
                        height: 148,
                        itemBuilder: (context, item, index) =>
                            _TradespersonCard(person: item, index: index),
                      ),
                    ] else if (employerHome) ...[
                      _SectionCarousel<TradePerson>(
                        title: 'Top Trade worker',
                        icon: Icons.people_outline,
                        items: _tradespeople,
                        height: 148,
                        itemBuilder: (context, item, index) =>
                            _TradespersonCard(person: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradeCourse>(
                        title: 'Top Trade Skill Courses',
                        icon: Icons.school_outlined,
                        items: _courses,
                        height: 180,
                        itemBuilder: (context, item, index) =>
                            _CourseCard(course: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradeTrainer>(
                        title: 'Top Contractor',
                        icon: Icons.school_outlined,
                        items: _trainers,
                        height: 124,
                        itemBuilder: (context, item, index) =>
                            _TrainerCard(trainer: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<HiringEmployer>(
                        title: 'Top Hiring Employers',
                        icon: Icons.apartment_outlined,
                        items: _employers,
                        height: 160,
                        itemBuilder: (context, item, index) =>
                            _EmployerCard(employer: item, index: index),
                      ),
                    ] else ...[
                      _SectionCarousel<TradeJob>(
                        title: 'Posted Trade Work',
                        icon: Icons.business_center_outlined,
                        items: _jobs,
                        height: 134,
                        itemBuilder: (context, item, index) =>
                            _JobCard(job: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradeCourse>(
                        title: 'Top Trade Skill Courses',
                        icon: Icons.school_outlined,
                        items: _courses,
                        height: 180,
                        itemBuilder: (context, item, index) =>
                            _CourseCard(course: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      if (showTradespeople)
                        _SectionCarousel<TradePerson>(
                          title: 'Top TradesPersons',
                          icon: Icons.people_outline,
                          items: _tradespeople,
                          height: 148,
                          itemBuilder: (context, item, index) =>
                              _TradespersonCard(person: item, index: index),
                        ),
                      const SizedBox(height: 12),
                      _SectionCarousel<TradeTrainer>(
                        title: 'Top Trainers',
                        icon: Icons.school_outlined,
                        items: _trainers,
                        height: 124,
                        itemBuilder: (context, item, index) =>
                            _TrainerCard(trainer: item, index: index),
                      ),
                      const SizedBox(height: 12),
                      _SectionCarousel<HiringEmployer>(
                        title: 'Top Hiring Employers',
                        icon: Icons.apartment_outlined,
                        items: _employers,
                        height: 160,
                        itemBuilder: (context, item, index) =>
                            _EmployerCard(employer: item, index: index),
                      ),
                    ],
                  ],
                ),
              ),
              if (!employerHome && !trainerHome && !userHome)
                const _DashboardFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// Shows the TradeProof brand and the login button at the top.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFF1B1D20),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: DashboardPage._green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TradeProof',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Verified Skills. Trusted Trades.',
                  style: TextStyle(
                    color: Color(0xFF42C8B2),
                    height: 1,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
          _HeaderButton(
            icon: Icons.login,
            label: 'Login',
            onPressed: () => Navigator.of(context).pushNamed('/login'),
          ),
        ],
      ),
    );
  }
}

// Builds a small header button with an icon and label.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        label: Text(label, style: const TextStyle(fontSize: 9)),
        style: FilledButton.styleFrom(
          backgroundColor: DashboardPage._green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// Shows a welcome message over a background image.
class _HeroSection extends StatelessWidget {
  const _HeroSection({this.trainerHome = false});

  final bool trainerHome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/dashboard_hero_photo.jpg',
            fit: BoxFit.cover,
            alignment: Alignment(1, -0.75),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xE9111A18),
                  Color(0xB822211B),
                  Color(0x40202020),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    text: trainerHome ? 'Teach Skills. ' : 'Repair Your ',
                    children: trainerHome
                        ? [
                            const TextSpan(
                              text: 'Build Careers',
                              style: TextStyle(color: Color(0xFFFFC400)),
                            ),
                          ]
                        : [
                            const TextSpan(
                              text: 'Home\n',
                              style: TextStyle(color: Color(0xFFFFC400)),
                            ),
                            const TextSpan(
                              text: 'Appliances & Services',
                              style: TextStyle(color: Color(0xFFFFC400)),
                            ),
                          ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  trainerHome
                      ? 'Practical training, competency assessments and verified credentials for the next generation of skilled tradespeople.'
                      : 'Instant technician dispatch, verified professionals & digital warranty guarantee across Dhaka.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 8,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

// Lets users search for services and choose a category.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    this.onSearch,
    this.trainerHome = false,
    this.userHome = false,
    this.onUserSearch,
  });

  final ValueChanged<String>? onSearch;
  final bool trainerHome;
  final bool userHome;
  final ValueChanged<String>? onUserSearch;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    // Send the search text to the callback for the current home page.
    if (widget.userHome) {
      widget.onUserSearch?.call(_controller.text.trim());
      return;
    }
    widget.onSearch?.call(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF8B9AAF), size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: 9, color: DashboardPage._ink),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: widget.userHome
                    ? 'Find a tradesperson or course...'
                    : widget.trainerHome
                    ? 'Search courses, skills or trainers...'
                    : 'Search services or requests...',
                hintStyle: TextStyle(fontSize: 9, color: Color(0xFF8997A9)),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 12,
                  color: DashboardPage._green,
                ),
                const SizedBox(width: 3),
                Text(
                  widget.userHome
                      ? 'All'
                      : widget.trainerHome
                      ? 'Training'
                      : 'All Categories',
                  style: const TextStyle(
                    fontSize: 8,
                    color: DashboardPage._ink,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 12,
                  color: DashboardPage._muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: _search,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 25,
              decoration: BoxDecoration(
                color: DashboardPage._green,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows a horizontal carousel for one type of marketplace item.
class _SectionCarousel<T> extends StatefulWidget {
  const _SectionCarousel({
    required this.title,
    required this.icon,
    required this.items,
    required this.height,
    required this.itemBuilder,
  });

  final String title;
  final IconData icon;
  final List<T> items;
  final double height;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  @override
  State<_SectionCarousel<T>> createState() => _SectionCarouselState<T>();
}

// Controls the carousel position, timer, and arrow navigation.
class _SectionCarouselState<T> extends State<_SectionCarousel<T>> {
  late final PageController _controller;
  Timer? _timer;
  int _currentIndex = 0;
  late final int _initialPage;

  @override
  void initState() {
    super.initState();
    // Start near the middle so users can keep swiping in either direction.
    _initialPage = widget.items.isEmpty ? 0 : 10000;
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.72,
    );
    _currentIndex = _initialPage % widget.items.length;
    // Move the carousel every few seconds and stop the timer when removed.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_controller.hasClients && widget.items.length > 1) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Move one card left or right.
  void _move(int direction) {
    if (!_controller.hasClients) return;
    if (direction > 0) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openMoreItems() async {
    _timer?.cancel();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _MoreItemsPage<T>(
          title: widget.title,
          icon: widget.icon,
          items: List<T>.of(widget.items),
          cardHeight: widget.height,
          itemBuilder: widget.itemBuilder,
        ),
      ),
    );
    if (mounted && widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_controller.hasClients) {
          _controller.nextPage(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shows the title, carousel controls, cards, and position indicator.
    return Column(
      children: [
        SizedBox(
          height: 22,
          child: Row(
            children: [
              Icon(widget.icon, size: 13, color: DashboardPage._green),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashboardPage._navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF47C89C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              _SmallArrow(icon: Icons.chevron_left, onPressed: () => _move(-1)),
              const SizedBox(width: 4),
              _SmallArrow(icon: Icons.chevron_right, onPressed: () => _move(1)),
              const SizedBox(width: 5),
              SizedBox(
                height: 21,
                child: FilledButton(
                  onPressed: _openMoreItems,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007F91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Row(
                    children: [
                      Text('View More', style: TextStyle(fontSize: 8)),
                      Icon(Icons.chevron_right, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemBuilder: (context, page) {
              final index = page % widget.items.length;
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: widget.itemBuilder(context, widget.items[index], index),
              );
            },
            onPageChanged: (page) {
              setState(() => _currentIndex = page % widget.items.length);
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Row(
              children: List.generate(widget.items.length, (index) {
                final selected = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 14 : 5,
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? DashboardPage._green
                        : const Color(0xFFDCE4EC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const Spacer(),
            Text(
              '${_currentIndex + 1} of ${widget.items.length} ${widget.title.toLowerCase()}',
              style: const TextStyle(color: DashboardPage._muted, fontSize: 7),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoreItemsPage<T> extends StatelessWidget {
  const _MoreItemsPage({
    required this.title,
    required this.icon,
    required this.items,
    required this.cardHeight,
    required this.itemBuilder,
  });

  final String title;
  final IconData icon;
  final List<T> items;
  final double cardHeight;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    // Shows every item in a scrollable list after "View More" is tapped.
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: DashboardPage._navy,
        elevation: 0,
        title: Row(
          children: [
            Icon(icon, color: DashboardPage._green, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'No items available right now.',
                style: TextStyle(color: DashboardPage._muted, fontSize: 12),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => SizedBox(
                height: cardHeight,
                child: itemBuilder(context, items[index], index),
              ),
            ),
    );
  }
}

// Builds a small button for moving to the previous or next card.
class _SmallArrow extends StatelessWidget {
  const _SmallArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 21,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFDCE4EC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Icon(icon, size: 14, color: DashboardPage._navy),
      ),
    );
  }
}

// Shows a customer's job request, budget, and application action.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.index, this.onBook});

  final TradeJob job;
  final int index;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      color: Colors.white,
      borderColor: const Color(0xFFB6DED5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoBanner(
            label: index.isEven
                ? 'Urgent Client Post'
                : 'Corporate Client Post',
            price: job.budget,
            alignment: index.isEven
                ? Alignment.centerLeft
                : Alignment.centerRight,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconText('♙  ${job.client}', color: DashboardPage._green),
                  const SizedBox(height: 3),
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardPage._navy,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _TagRow(tags: job.tags),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _IconText(
                          '${job.applicants} applied',
                          color: DashboardPage._muted,
                        ),
                      ),
                      _MiniButton(
                        label: 'Book Service',
                        icon: Icons.arrow_forward,
                        onPressed: () => _openTradeDetails(
                          context,
                          _jobDetails(context, job, onAction: onBook),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows a course title, instructor, rating, and enrollment action.
class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.index, this.onEnroll});

  final TradeCourse course;
  final int index;
  final VoidCallback? onEnroll;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      color: const Color(0xFFF7FAFC),
      borderColor: const Color(0xFF75D8C0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CourseBanner(course: course, index: index),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardPage._navy,
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _InstructorLine(name: course.instructor),
                  const SizedBox(height: 4),
                  _IconText('${course.duration}  •  QR License'),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 10,
                        color: Color(0xFFFFB400),
                      ),
                      Text(
                        ' ${course.rating} (${course.reviews})',
                        style: const TextStyle(
                          fontSize: 7,
                          color: DashboardPage._muted,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '60% TradeProof Grant',
                        style: TextStyle(
                          fontSize: 7,
                          color: DashboardPage._green,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniButton(
                          label: 'Enroll',
                          icon: Icons.menu_book,
                          onPressed: () => _openTradeDetails(
                            context,
                            _courseDetails(context, course, onAction: onEnroll),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _MiniButton(
                          label: 'View License',
                          icon: Icons.workspace_premium_outlined,
                          secondary: true,
                          onPressed: () => _openTradeDetails(
                            context,
                            _courseDetails(
                              context,
                              course,
                              actionLabel: 'View Course License',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows a worker's trade, rate, location, skills, and license.
class _TradespersonCard extends StatelessWidget {
  const _TradespersonCard({
    required this.person,
    required this.index,
    this.onHire,
  });

  final TradePerson person;
  final int index;
  final VoidCallback? onHire;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      color: Colors.white,
      borderColor: const Color(0xFF62D7B4),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name: person.name, index: index, size: 30),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VerifiedName(name: person.name),
                      Text(
                        person.trade,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashboardPage._muted,
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      'Visit Rate',
                      style: TextStyle(
                        fontSize: 6,
                        color: DashboardPage._muted,
                      ),
                    ),
                    Text(
                      person.rate,
                      style: const TextStyle(
                        color: DashboardPage._navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            _TagRow(tags: [person.availability, person.location]),
            const SizedBox(height: 5),
            _TagRow(tags: person.skills),
            const SizedBox(height: 5),
            _IconText('License: ${person.license}', color: DashboardPage._navy),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    label: 'Direct Hire',
                    icon: Icons.work_outline,
                    onPressed: () => _openTradeDetails(
                      context,
                      _tradespersonDetails(context, person, onAction: onHire),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _MiniButton(
                    label: 'Locker',
                    icon: Icons.verified_user_outlined,
                    secondary: true,
                    onPressed: () => _openTradeDetails(
                      context,
                      _tradespersonDetails(
                        context,
                        person,
                        actionLabel: 'View Verified Credentials',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Shows a trainer's qualifications, certifications, and rating.
class _TrainerCard extends StatelessWidget {
  const _TrainerCard({required this.trainer, required this.index});

  final TradeTrainer trainer;
  final int index;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      color: Colors.white,
      borderColor: const Color(0xFFE1E8EF),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          children: [
            Row(
              children: [
                _Avatar(name: trainer.name, index: index + 2, size: 30),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VerifiedName(name: trainer.name),
                      Text(
                        trainer.qualification,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 7,
                          color: DashboardPage._muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                _Pill(
                  text: trainer.certification,
                  color: const Color(0xFFD9F7F1),
                  textColor: DashboardPage._green,
                ),
                const Spacer(),
                _Pill(
                  text: '★ ${trainer.rating}',
                  color: const Color(0xFFFFF5D9),
                  textColor: const Color(0xFFCF8200),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    label: 'Courses',
                    icon: Icons.menu_book,
                    onPressed: () => _openTradeDetails(
                      context,
                      _trainerDetails(context, trainer),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _MiniButton(
                    label: 'Contact',
                    icon: Icons.call_outlined,
                    secondary: true,
                    onPressed: () => _openTradeDetails(
                      context,
                      _trainerDetails(
                        context,
                        trainer,
                        actionLabel: 'Contact Trainer',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Shows an employer's featured work, payment, and job action.
class _EmployerCard extends StatelessWidget {
  const _EmployerCard({required this.employer, required this.index});

  final HiringEmployer employer;
  final int index;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      color: Colors.white,
      borderColor: const Color(0xFF63DAB5),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name: employer.name, index: index + 1, size: 27),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VerifiedName(name: employer.name),
                      Text(
                        employer.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 7,
                          color: DashboardPage._muted,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  text: '${employer.jobs} Jobs',
                  color: const Color(0xFFDFF8F0),
                  textColor: DashboardPage._green,
                ),
              ],
            ),
            const SizedBox(height: 5),
            _Pill(
              text: employer.guarantee,
              color: const Color(0xFFE9FAF1),
              textColor: DashboardPage._green,
              fullWidth: true,
            ),
            const SizedBox(height: 5),
            const Text(
              'FEATURED WORK & PAY:',
              style: TextStyle(
                color: DashboardPage._muted,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    employer.project,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardPage._navy,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  employer.pay,
                  style: const TextStyle(
                    color: DashboardPage._green,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              employer.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 7, color: DashboardPage._muted),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    label: 'View Jobs',
                    icon: Icons.business_center,
                    onPressed: () => _openTradeDetails(
                      context,
                      _employerDetails(context, employer),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _MiniButton(
                    label: 'Apply',
                    icon: Icons.send_outlined,
                    secondary: true,
                    onPressed: () => _openTradeDetails(
                      context,
                      _employerDetails(
                        context,
                        employer,
                        actionLabel: 'Apply Now',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Adds a category label and budget badge over a job image.
class _PhotoBanner extends StatelessWidget {
  const _PhotoBanner({
    required this.label,
    required this.price,
    required this.alignment,
  });

  final String label;
  final String price;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/tradeproof_workers.png',
            fit: BoxFit.cover,
            alignment: alignment,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22212B32), Color(0xDD17252A)],
              ),
            ),
          ),
          Positioned(
            left: 5,
            top: 5,
            child: _Pill(
              text: label,
              color: const Color(0xDD102A43),
              textColor: Colors.white,
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: _Pill(
              text: price,
              color: DashboardPage._green,
              textColor: Colors.white,
            ),
          ),
          const Positioned(
            left: 6,
            bottom: 5,
            child: _Pill(
              text: '⚡ Immediate  •  20 mins ago',
              color: Color(0xFFFFB629),
              textColor: Color(0xFF462C00),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows a course category, level, and price in its banner.
class _CourseBanner extends StatelessWidget {
  const _CourseBanner({required this.course, required this.index});

  final TradeCourse course;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/tradeproof_workers.png',
            fit: BoxFit.cover,
            alignment: index.isEven
                ? Alignment.centerLeft
                : Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x24152932), Color(0xBB102A43)],
              ),
            ),
          ),
          Positioned(
            left: 5,
            top: 5,
            child: _Pill(
              text: course.category.toUpperCase(),
              color: DashboardPage._green,
              textColor: Colors.white,
            ),
          ),
          Positioned(
            right: 5,
            bottom: 5,
            child: Text(
              course.price,
              style: const TextStyle(
                color: Color(0xFFFFB719),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Text(
              course.level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Gives cards a shared background, border, rounded corners, and clipping.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

// Shows a list of tags that can scroll horizontally.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 17,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 3),
        itemBuilder: (context, index) => _Pill(
          text: tags[index],
          color: const Color(0xFFF0F4F7),
          textColor: const Color(0xFF4F6277),
          border: const Color(0xFFE2E9EF),
        ),
      ),
    );
  }
}

// Shows one small badge, with optional border and full-width layout.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    required this.textColor,
    this.border,
    this.fullWidth = false,
  });

  final String text;
  final Color color;
  final Color textColor;
  final Color? border;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 6.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Shows a short line of information with an icon.
class _IconText extends StatelessWidget {
  const _IconText(this.text, {this.color = DashboardPage._muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 7),
    );
  }
}

// Builds a small primary or secondary action button for a card.
class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 19,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 10),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: secondary
              ? const Color(0xFFF0F4F7)
              : DashboardPage._green,
          foregroundColor: secondary ? const Color(0xFF007C86) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// Shows the instructor's name with a verification mark.
class _InstructorLine extends StatelessWidget {
  const _InstructorLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle, size: 15, color: Color(0xFF3386A1)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DashboardPage._ink,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.verified, size: 10, color: DashboardPage._green),
        ],
      ),
    );
  }
}

// Builds a round avatar using the name's first letter and a color.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.index, required this.size});

  final String name;
  final int index;
  final double size;

  static const _colors = [
    Color(0xFFD6EEE8),
    Color(0xFFDDE8F5),
    Color(0xFFF3E1D3),
    Color(0xFFE6E2F2),
    Color(0xFFE2EED8),
  ];

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colors[index % _colors.length],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: DashboardPage._green,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Shows a name with a verification icon beside it.
class _VerifiedName extends StatelessWidget {
  const _VerifiedName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashboardPage._green,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.verified, size: 9, color: DashboardPage._green),
      ],
    );
  }
}

// Shows TradeProof and developer information at the bottom of the dashboard.
class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardPage._navy,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Color(0xFF28BEAA), size: 15),
              SizedBox(width: 5),
              Text(
                'TradeProof',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'Verified Trades & Skills Marketplace',
                style: TextStyle(color: Color(0xFFB5C3D2), fontSize: 8),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            '☎ Developed By: Asif Hasan   |   📍 Bausi, Saidpur',
            style: TextStyle(color: Color(0xFF46C8B5), fontSize: 7),
          ),
        ],
      ),
    );
  }
}

// Stores the details needed to show one job post.
class TradeJob {
  const TradeJob({
    required this.client,
    required this.title,
    required this.tags,
    required this.applicants,
    required this.budget,
    required this.location,
    required this.description,
  });

  final String client;
  final String title;
  final List<String> tags;
  final int applicants;
  final String budget;
  final String location;
  final String description;
}

// Sample job posts shown in the dashboard carousel.
const _jobs = [
  TradeJob(
    client: 'Nasrin Akhter (Homeowner)',
    title: 'Need Master Plumber for Concealed Pipe Leak',
    tags: ['Licensed Master Plumber', 'Hot Melt PPR Pipe Joint'],
    applicants: 5,
    budget: '৳1200',
    location: 'Dhanmondi, Dhaka',
    description:
        'Find and repair a concealed bathroom pipe leak. The work includes '
        'locating the leak, replacing the damaged pipe joint, and testing '
        'the water line after repair.',
  ),
  TradeJob(
    client: 'Engr. Farhan (Office Manager)',
    title: 'Need Certified Electrician for Tripping Breaker',
    tags: ['Licensed Electrician', 'Class II Digital'],
    applicants: 6,
    budget: '৳1500',
    location: 'Mirpur, Dhaka',
    description:
        'Inspect a frequently tripping electrical breaker, diagnose the '
        'circuit issue, and provide a safe repair with a final system test.',
  ),
  TradeJob(
    client: 'Zubair Rahman (Homeowner)',
    title: 'Need Master Plumber for Bathroom Fittings',
    tags: ['Sanitary Fittings', 'Digital Plumbing'],
    applicants: 3,
    budget: '৳900',
    location: 'Uttara, Dhaka',
    description:
        'Install and test bathroom sanitary fittings, including water '
        'connections and drainage. Bring the tools required for a clean finish.',
  ),
  TradeJob(
    client: 'Tariqul Islam (Property Owner)',
    title: 'Need Expert AC Repair Technician',
    tags: ['AC Maintenance', 'Verified Technician'],
    applicants: 4,
    budget: '৳1800',
    location: 'Banani, Dhaka',
    description:
        'Diagnose and repair a residential air conditioner, inspect the '
        'cooling system, and confirm safe operation after servicing.',
  ),
  TradeJob(
    client: 'Shanta Holdings',
    title: 'Certified Electrician for New Project Wiring',
    tags: ['Electrical Wiring', 'Safety Certified'],
    applicants: 8,
    budget: '৳2500',
    location: 'Gulshan, Dhaka',
    description:
        'Complete electrical wiring work for a new commercial project, '
        'following site safety requirements and applicable electrical standards.',
  ),
  TradeJob(
    client: 'Mahir Ahmed (Homeowner)',
    title: 'Looking for a Trusted Tile Installer',
    tags: ['Tile Installation', 'Experienced'],
    applicants: 2,
    budget: '৳1100',
    location: 'Mohammadpur, Dhaka',
    description:
        'Install floor tiles in a residential room with even spacing, '
        'accurate cuts, and a clean grout finish.',
  ),
];

// Stores the details needed to show one training course.
class TradeCourse {
  const TradeCourse({
    required this.category,
    required this.level,
    required this.price,
    required this.title,
    required this.instructor,
    required this.duration,
    required this.rating,
    required this.reviews,
  });

  final String category;
  final String level;
  final String price;
  final String title;
  final String instructor;
  final String duration;
  final String rating;
  final String reviews;
}

// Sample courses shown in the dashboard carousel.
const _courses = [
  TradeCourse(
    category: 'Plumbing',
    level: 'Master / Class-A',
    price: '৳1800',
    title: 'Master Sanitary & Thermal PPR Pipe Fusion Workshop',
    instructor: 'Engr. Shakil Ahmed',
    duration: '4 Weeks (Weekend)',
    rating: '4.9',
    reviews: '342',
  ),
  TradeCourse(
    category: 'Electrical',
    level: 'Professional',
    price: '৳2500',
    title: 'Class-A Electrical Wiring & Safety Certification',
    instructor: 'Farhad Ahmed',
    duration: '6 Weeks',
    rating: '4.8',
    reviews: '265',
  ),
  TradeCourse(
    category: 'HVAC',
    level: 'Specialist',
    price: '৳3200',
    title: 'Inverter AC & VRF Multi-Split Diagnostics',
    instructor: 'Engr. Nafis Imtiaz',
    duration: '4 Weeks',
    rating: '4.8',
    reviews: '195',
  ),
  TradeCourse(
    category: 'Solar & Tech',
    level: 'Advanced',
    price: '৳2800',
    title: 'Rooftop Solar Installation & Maintenance',
    instructor: 'Engr. Mahmud',
    duration: '3 Weeks',
    rating: '4.7',
    reviews: '126',
  ),
  TradeCourse(
    category: 'Carpentry',
    level: 'Professional',
    price: '৳1600',
    title: 'Modern Woodworking and Cabinet Installation',
    instructor: 'Md. Rafiq Islam',
    duration: '5 Weeks',
    rating: '4.9',
    reviews: '214',
  ),
  TradeCourse(
    category: 'Welding',
    level: 'Certified',
    price: '৳2200',
    title: 'Arc Welding, Fabrication & Workplace Safety',
    instructor: 'Engr. Kamal Hossain',
    duration: '5 Weeks',
    rating: '4.8',
    reviews: '183',
  ),
];

// Stores a worker's name, trade, rate, skills, and license details.
class TradePerson {
  const TradePerson({
    required this.name,
    required this.trade,
    required this.rate,
    required this.availability,
    required this.location,
    required this.skills,
    required this.license,
  });

  final String name;
  final String trade;
  final String rate;
  final String availability;
  final String location;
  final List<String> skills;
  final String license;
}

// Sample workers shown in the dashboard carousel.
const _tradespeople = [
  TradePerson(
    name: 'Md. Rafiq Islam',
    trade: 'Licensed Master Plumber',
    rate: '৳850',
    availability: 'Immediate (30 min)',
    location: 'Dhanmondi, Dhaka',
    skills: ['PPR Thermal Fusion', 'Acoustic Leak Detection'],
    license: 'TL-DCC-2022-8819',
  ),
  TradePerson(
    name: 'Engr. Farhan Ahmed',
    trade: 'Government Certified Electrician',
    rate: '৳1200',
    availability: 'Available Today',
    location: 'Mirpur, Dhaka',
    skills: ['3-Phase DB Load', 'Safety Inspection'],
    license: 'EL-GOV-2023-1082',
  ),
  TradePerson(
    name: 'Shakil Ahmed',
    trade: 'Senior AC Technician',
    rate: '৳1000',
    availability: 'Immediate (45 min)',
    location: 'Uttara, Dhaka',
    skills: ['AC Repair', 'Refrigerant Service'],
    license: 'HVAC-2024-3320',
  ),
  TradePerson(
    name: 'Tariqul Islam',
    trade: 'Verified Solar Installer',
    rate: '৳1500',
    availability: 'Available Tomorrow',
    location: 'Banani, Dhaka',
    skills: ['Rooftop Solar', 'Grid Connection'],
    license: 'SOL-2023-1475',
  ),
  TradePerson(
    name: 'Nafis Imtiaz',
    trade: 'Certified Carpenter',
    rate: '৳900',
    availability: 'Available Today',
    location: 'Mohammadpur, Dhaka',
    skills: ['Cabinet Work', 'Furniture Repair'],
    license: 'CAR-2022-0441',
  ),
  TradePerson(
    name: 'Kamal Hossain',
    trade: 'Certified Welding Specialist',
    rate: '৳1300',
    availability: 'Immediate (1 hour)',
    location: 'Saidpur, Nilphamari',
    skills: ['Arc Welding', 'Steel Fabrication'],
    license: 'WEL-2024-0926',
  ),
];

// Stores the details needed to show one trainer.
class TradeTrainer {
  const TradeTrainer({
    required this.name,
    required this.qualification,
    required this.certification,
    required this.rating,
  });

  final String name;
  final String qualification;
  final String certification;
  final String rating;
}

// Sample trainers shown in the dashboard carousel.
const _trainers = [
  TradeTrainer(
    name: 'Md. Aminul Islam',
    qualification: 'Electronics Diagnostic Head & Master Technician',
    certification: '315+ Certified',
    rating: '4.9 (13y exp)',
  ),
  TradeTrainer(
    name: 'Engr. Nafis Imtiaz',
    qualification: 'Renewable Energy Lab Lead & SREDA Accredited',
    certification: '290+ Certified',
    rating: '4.8 (8y exp)',
  ),
  TradeTrainer(
    name: 'Farhad Ahmed',
    qualification: 'Senior Electrical Instructor & Safety Assessor',
    certification: '240+ Certified',
    rating: '4.9 (10y exp)',
  ),
  TradeTrainer(
    name: 'Shakil Ahmed',
    qualification: 'Master Plumbing Trainer & Certified Assessor',
    certification: '180+ Certified',
    rating: '4.8 (7y exp)',
  ),
  TradeTrainer(
    name: 'Kamal Hossain',
    qualification: 'Welding and Fabrication Skills Instructor',
    certification: '150+ Certified',
    rating: '4.7 (9y exp)',
  ),
  TradeTrainer(
    name: 'Mahir Uddin',
    qualification: 'Building Maintenance & Construction Trainer',
    certification: '125+ Certified',
    rating: '4.8 (6y exp)',
  ),
];

List<TradeTrainer> get marketplaceTrainers => _trainers;

// Stores an employer's details and featured job information.
class HiringEmployer {
  const HiringEmployer({
    required this.name,
    required this.specialty,
    required this.jobs,
    required this.guarantee,
    required this.project,
    required this.pay,
    required this.location,
  });

  final String name;
  final String specialty;
  final int jobs;
  final String guarantee;
  final String project;
  final String pay;
  final String location;
}

// Sample employers shown in the dashboard carousel.
const _employers = [
  HiringEmployer(
    name: 'Shanta Holdings Facility Ops',
    specialty: 'Commercial High-Rise & Luxury Corporate',
    jobs: 4,
    guarantee: '100% Escrow Guaranteed   Within 12 Hours',
    project: '3-Phase Industrial DB Balancing &...',
    pay: '৳14500',
    location: 'Banani, Dhaka   •   Job Completed',
  ),
  HiringEmployer(
    name: 'Apex Living Home Services',
    specialty: 'Luxury Gated Community Facility',
    jobs: 3,
    guarantee: 'Guaranteed Community Escrow',
    project: 'Whole-Building Solar PV Inverter...',
    pay: '৳18000',
    location: 'Uttara Sector 3, Dhaka',
  ),
  HiringEmployer(
    name: 'Capital Estate Management',
    specialty: 'Residential & Commercial Property',
    jobs: 7,
    guarantee: 'Escrow Secured Payment',
    project: 'High-Voltage Panel Upgrade & Test...',
    pay: '৳22000',
    location: 'Gulshan, Dhaka',
  ),
  HiringEmployer(
    name: 'Green City Developments',
    specialty: 'Building Construction & Engineering',
    jobs: 5,
    guarantee: 'Verified Employer   Prompt Payment',
    project: 'Apartment Plumbing & Finishing...',
    pay: '৳19500',
    location: 'Mirpur, Dhaka',
  ),
  HiringEmployer(
    name: 'Northern Homes Limited',
    specialty: 'Home Maintenance & Renovation',
    jobs: 2,
    guarantee: 'Secure TradeProof Escrow',
    project: 'Office HVAC Installation Project...',
    pay: '৳12500',
    location: 'Saidpur, Nilphamari',
  ),
];

List<TradePerson> get marketplaceTradePeople => _tradespeople;
List<TradeCourse> get marketplaceTradeCourses => _courses;
