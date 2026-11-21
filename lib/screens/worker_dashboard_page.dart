import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/connection_service.dart';
import 'course_checkout_page.dart';

typedef AddCompletedProjectCallback =
    Future<void> Function({
      required String title,
      required String client,
      required String category,
      required String description,
    });

// This screen shows a worker's active jobs and live tracking progress.
class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({
    super.key,
    this.isDemo = false,
    this.onAddCompletedProject,
  });

  final bool isDemo;
  final AddCompletedProjectCallback? onAddCompletedProject;

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

// The job list, status tracking, and quick actions live in this state.
class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  // These labels show the steps from a job request to completion.
  static const _trackingStages = [
    'Request Send',
    'Request Accept',
    'Waiting for the Day',
    'On the Way',
    'Reach the Site',
    'Done',
  ];

  final List<_AppliedJob> _jobs = [
    _AppliedJob(
      id: 'JOB-9021',
      category: 'Electrical Engineering',
      title: '3-Phase Industrial Distribution Board & Surge Protector Setup',
      client: 'Rahim Textile Mills (Mr. Tanvir)',
      location: 'Plot 42, Tejgaon I/A, Dhaka',
      distance: '4.2 km',
      date: 'Tomorrow, Oct 24',
      pay: '৳14,500',
      statusIndex: 2,
      urgent: true,
      audit: [
        _AuditEntry('Request Accept', '21 Oct, 04:15 PM'),
        _AuditEntry('Waiting for the Day', '22 Oct, 10:00 AM'),
      ],
    ),
    _AppliedJob(
      id: 'JOB-8814',
      category: 'HVAC & Refrigeration',
      title: 'Commercial VRF Air Conditioning Piping & Pressure Leak Test',
      client: 'Banani Business Center',
      location: 'Road 11, Block D, Banani, Dhaka',
      distance: '6.1 km',
      date: 'Today, Oct 23',
      pay: '৳8,800',
      statusIndex: 3,
      audit: [
        _AuditEntry('Request Accept', '20 Oct, 02:20 PM'),
        _AuditEntry('Waiting for the Day', '21 Oct, 09:00 AM'),
        _AuditEntry('On the Way', '23 Oct, 08:15 AM'),
      ],
    ),
    _AppliedJob(
      id: 'JOB-7952',
      category: 'Electrical Automation',
      title: 'Emergency Generator ATS Transfer Panel Troubleshooting',
      client: 'Dhanmondi Medical Center',
      location: 'Dhanmondi 27, Dhaka',
      distance: '3.8 km',
      date: '20 Oct',
      pay: '৳11,200',
      statusIndex: 5,
      audit: [
        _AuditEntry('Request Accept', '18 Oct, 11:10 AM'),
        _AuditEntry('On the Way', '19 Oct, 08:00 AM'),
        _AuditEntry('Done', '20 Oct, 01:45 PM'),
      ],
    ),
    _AppliedJob(
      id: 'JOB-6540',
      category: 'Fire & Life Safety',
      title: 'Commercial Fire Alarm Panel Inspection & Sensor Testing',
      client: 'Northstar Tower',
      location: 'Gulshan 2, Dhaka',
      distance: '7.5 km',
      date: 'Oct 26',
      pay: '৳9,600',
      statusIndex: 0,
      audit: [_AuditEntry('Request Send', '22 Oct, 05:30 PM')],
    ),
  ];

  String get _displayName {
    // Use the signed-in name, or a sample name in demo mode.
    if (widget.isDemo) {
      return ConnectionService.currentUserName?.toUpperCase() ??
          'MD. ASIF HASAN';
    }
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    return name == null || name.isEmpty ? 'MD. ASIF HASAN' : name;
  }

  void _showActionMessage(String action) {
    final message = widget.isDemo
        ? '$action is only simulated in this demo; no money is transferred.'
        : '$action is not available in this prototype.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _enrollInCourse() async {
    try {
      await openCourseCheckoutForTitle(
        context,
        'Electrical Installation & Safety',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _openTracking(_AppliedJob job) async {
    // Open the dialog that shows this job's progress.
    await showDialog<void>(
      context: context,
      builder: (_) => _TrackingDialog(
        job: job,
        stages: _trackingStages,
        onAddCompletedProject: widget.onAddCompletedProject,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addCompletedProject(_AppliedJob job) async {
    // Send a finished job to the portfolio page.
    await widget.onAddCompletedProject?.call(
      title: job.title,
      client: job.client,
      category: job.category,
      description:
          'Completed ${job.title} for ${job.client} at ${job.location}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Count unfinished jobs for the live tracking banner.
    final addCompletedProject = widget.onAddCompletedProject;
    final activeJobs = _jobs
        .where((job) => job.statusIndex < _trackingStages.length - 1)
        .length;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 18),
          children: [
            _FinanceSummaryCard(
              displayName: _displayName,
              onWithdraw: () => _showActionMessage('Withdraw'),
              onEnroll: _enrollInCourse,
            ),
            const SizedBox(height: 12),
            _LiveTrackingBanner(activeJobs: activeJobs),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF009E9A),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select Applied Job (${_jobs.length})',
                    style: const TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Click “Tracking” button on any card for live popup',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            for (final job in _jobs) ...[
              _AppliedJobCard(
                job: job,
                stageLabel: _trackingStages[job.statusIndex],
                onTracking: () => _openTracking(job),
                onAddProject:
                    job.statusIndex == _trackingStages.length - 1 &&
                        addCompletedProject != null
                    ? () => _addCompletedProject(job)
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// Summary card for the worker's earnings and fast actions.
class _FinanceSummaryCard extends StatelessWidget {
  const _FinanceSummaryCard({
    required this.displayName,
    required this.onWithdraw,
    required this.onEnroll,
  });

  final String displayName;
  final VoidCallback onWithdraw;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF7),
        border: Border.all(color: const Color(0xFF98F1D9)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF009E91),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Live Job Tracking & Financial System (কাজ ট্র্যাকিং ও লেনদেন)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF53677E), fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeaderActionButton(
                  icon: Icons.south_west,
                  label: 'Withdraw টাকা তুলুন',
                  color: const Color(0xFF009E91),
                  onPressed: onWithdraw,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HeaderActionButton(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Enroll Course (কোর্স)',
                  color: const Color(0xFFF59A00),
                  onPressed: onEnroll,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1, color: Color(0xFFBFECE1)),
          ),
          const Row(
            children: [
              Expanded(
                child: _FinanceMetric(
                  label: 'BALANCE',
                  value: '৳18,400',
                  icon: Icons.currency_exchange,
                  color: Color(0xFF009E75),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _FinanceMetric(
                  label: 'WORK INCOME',
                  value: '৳39,100',
                  icon: Icons.trending_up,
                  color: Color(0xFF009E91),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Expanded(
                child: _FinanceMetric(
                  label: 'COURSE FEES',
                  value: '-৳5,700',
                  icon: Icons.workspace_premium_outlined,
                  color: Color(0xFFEA5265),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _FinanceMetric(
                  label: 'ACTIVE JOBS',
                  value: '3 Active',
                  icon: Icons.local_shipping_outlined,
                  color: Color(0xFFF28A00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ],
      ),
    );
  }
}

class _LiveTrackingBanner extends StatelessWidget {
  const _LiveTrackingBanner({required this.activeJobs});

  final int activeJobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 15,
              color: Color(0xFF009E91),
            ),
            const SizedBox(width: 6),
            const Text(
              'Job Live Tracking',
              style: TextStyle(
                color: Color(0xFF006B6A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD6FAF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeJobs Active',
                style: const TextStyle(
                  color: Color(0xFF008C75),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedJob {
  _AppliedJob({
    required this.id,
    required this.category,
    required this.title,
    required this.client,
    required this.location,
    required this.distance,
    required this.date,
    required this.pay,
    required this.statusIndex,
    required this.audit,
    this.urgent = false,
  });

  final String id;
  final String category;
  final String title;
  final String client;
  final String location;
  final String distance;
  final String date;
  final String pay;
  int statusIndex;
  final bool urgent;
  final List<_AuditEntry> audit;
}

class _AuditEntry {
  const _AuditEntry(this.title, this.time);

  final String title;
  final String time;
}

class _AppliedJobCard extends StatelessWidget {
  const _AppliedJobCard({
    required this.job,
    required this.stageLabel,
    required this.onTracking,
    this.onAddProject,
  });

  final _AppliedJob job;
  final String stageLabel;
  final VoidCallback onTracking;
  final VoidCallback? onAddProject;

  @override
  Widget build(BuildContext context) {
    final color = job.statusIndex == 5
        ? const Color(0xFF00A879)
        : job.statusIndex >= 3
        ? const Color(0xFF00BFA8)
        : const Color(0xFF00A99D);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _JobIdBadge(text: job.id),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF008C75), fontSize: 9),
                ),
              ),
              if (job.urgent) const _UrgentBadge(),
              if (!job.urgent)
                Text(
                  'Step ${job.statusIndex + 1}/6',
                  style: const TextStyle(color: Color(0xFF8290A6), fontSize: 9),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            job.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF91A2BC),
                size: 13,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  job.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                job.date,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 7),
            child: Divider(height: 1, color: Color(0xFFE8EDF2)),
          ),
          Row(
            children: [
              Flexible(child: _JobStagePill(text: stageLabel)),
              const SizedBox(width: 7),
              Text(
                job.pay,
                style: const TextStyle(
                  color: Color(0xFF10243B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: FilledButton.icon(
                  onPressed: onTracking,
                  icon: const Icon(Icons.local_shipping_outlined, size: 13),
                  label: const Text(
                    'Tracking',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF009E91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (onAddProject != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 30,
                child: FilledButton.icon(
                  onPressed: onAddProject,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Add Project',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF008C68),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobIdBadge extends StatelessWidget {
  const _JobIdBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontFamily: 'monospace',
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9EC),
        border: Border.all(color: const Color(0xFFFFB8C2)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: Color(0xFFDC2348), size: 11),
          Text(
            'Urgent',
            style: TextStyle(
              color: Color(0xFFDC2348),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobStagePill extends StatelessWidget {
  const _JobStagePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDone = text == 'Done';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFE8FFF4) : const Color(0xFFFFF8E8),
        border: Border.all(
          color: isDone ? const Color(0xFF9DEBC7) : const Color(0xFFFFD978),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDone ? const Color(0xFF008C68) : const Color(0xFFBA7600),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrackingDialog extends StatefulWidget {
  const _TrackingDialog({
    required this.job,
    required this.stages,
    required this.onAddCompletedProject,
  });

  final _AppliedJob job;
  final List<String> stages;
  final AddCompletedProjectCallback? onAddCompletedProject;

  @override
  State<_TrackingDialog> createState() => _TrackingDialogState();
}

class _TrackingDialogState extends State<_TrackingDialog> {
  bool _showAllAudit = false;

  Future<void> _addProject() async {
    final callback = widget.onAddCompletedProject;
    if (callback == null) return;
    final job = widget.job;
    Navigator.of(context).pop();
    await callback(
      title: job.title,
      client: job.client,
      category: job.category,
      description:
          'Completed ${job.title} for ${job.client} at ${job.location}.',
    );
  }

  void _setStage(int stage) {
    setState(() {
      widget.job.statusIndex = stage;
      if (stage == 0) {
        widget.job.audit
          ..clear()
          ..add(const _AuditEntry('Request Send', 'Just now'));
      } else {
        final newEntry = _AuditEntry(widget.stages[stage], 'Just now');
        if (widget.job.audit.isEmpty ||
            widget.job.audit.last.title != newEntry.title) {
          widget.job.audit.add(newEntry);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.job.statusIndex;
    final visibleEntries = _showAllAudit
        ? widget.job.audit.reversed.toList()
        : widget.job.audit.reversed.take(2).toList();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                children: [
                  Row(
                    children: [
                      _JobIdBadge(text: widget.job.id),
                      const SizedBox(width: 5),
                      _CategoryPill(text: widget.job.category),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Client: ${widget.job.client}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFEF476F),
                        size: 13,
                      ),
                      Expanded(
                        child: Text(
                          '${widget.job.location} (${widget.job.distance})',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    children: [
                      _TrackingContactButton(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        onPressed: () => _showActionMessage(context, 'Call'),
                      ),
                      _TrackingContactButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        onPressed: () => _showActionMessage(context, 'Chat'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFE8EDF2)),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'LIVE PROGRESS FLOW (এ-পার্টস লাইভ ট্র্যাকিং)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9FFF6),
                          border: Border.all(color: const Color(0xFF9BEBC9)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Step ${stage + 1} of ${widget.stages.length}',
                          style: const TextStyle(
                            color: Color(0xFF008C68),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      text: 'Current: ',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                      children: [
                        TextSpan(
                          text: widget.stages[stage],
                          style: const TextStyle(
                            color: Color(0xFF008C75),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' (কাজের বর্তমান অবস্থা)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (stage + 1) / widget.stages.length,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8EDF2),
                      color: const Color(0xFF00B990),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.stages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.1,
                        ),
                    itemBuilder: (context, index) {
                      final isPast = index < stage;
                      final isCurrent = index == stage;
                      return _TrackingStageTile(
                        number: index + 1,
                        label: widget.stages[index],
                        isPast: isPast,
                        isCurrent: isCurrent,
                        onTap: () => _setStage(index),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tap any stage to advance or test tracking simulation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: FilledButton(
                                  onPressed: stage < widget.stages.length - 1
                                      ? () => _setStage(stage + 1)
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF009E91),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    stage < widget.stages.length - 1
                                        ? 'Next: "${widget.stages[stage + 1]}"  ›'
                                        : 'Job Completed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 32,
                              child: TextButton(
                                onPressed: () => _setStage(0),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8EEF3),
                                  foregroundColor: const Color(0xFF475569),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (stage == widget.stages.length - 1 &&
                      widget.onAddCompletedProject != null) ...[
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: _addProject,
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text(
                          'Add Project to Portfolio',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF008C68),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF91A2BC),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'TIMELINE AUDIT LOG',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showAllAudit = !_showAllAudit),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _showAllAudit ? 'Show Less ⌃' : 'Show All ⌄',
                          style: const TextStyle(
                            color: Color(0xFF008C75),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (visibleEntries.isEmpty)
                    const Text(
                      'No tracking events yet.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    )
                  else
                    for (final entry in visibleEntries)
                      _AuditLogTile(entry: entry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionMessage(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action is not connected in this demo yet.')),
      );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5FBF5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF008C75),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrackingContactButton extends StatelessWidget {
  const _TrackingContactButton({
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
      height: 29,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 9)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF008C75),
          backgroundColor: const Color(0xFFF2F7F9),
          side: const BorderSide(color: Color(0xFFDCE4EC)),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

class _TrackingStageTile extends StatelessWidget {
  const _TrackingStageTile({
    required this.number,
    required this.label,
    required this.isPast,
    required this.isCurrent,
    required this.onTap,
  });

  final int number;
  final String label;
  final bool isPast;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isCurrent
        ? const Color(0xFF009E91)
        : isPast
        ? const Color(0xFFE8FFF5)
        : const Color(0xFFF7F9FC);
    final foreground = isCurrent
        ? Colors.white
        : isPast
        ? const Color(0xFF008C68)
        : const Color(0xFF64748B);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFF009E91)
                  : isPast
                  ? const Color(0xFF9BEBC9)
                  : const Color(0xFFDCE4EC),
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _JobIdBadge(text: '#$number'),
                  const Spacer(),
                  Icon(
                    isPast
                        ? Icons.check_circle_outline
                        : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.circle_outlined,
                    color: foreground,
                    size: 12,
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.white.withValues(alpha: 0.16)
                        : isPast
                        ? const Color(0xFFD3F8E8)
                        : const Color(0xFFEAF0F5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(_stageIcon(number), color: foreground, size: 27),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 8.5,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _stageIcon(int stage) {
    return switch (stage) {
      1 => Icons.send_outlined,
      2 => Icons.task_alt_outlined,
      3 => Icons.access_time,
      4 => Icons.local_shipping_outlined,
      5 => Icons.location_on_outlined,
      _ => Icons.check_circle_outline,
    };
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry});

  final _AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF00A98F),
            size: 15,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.title,
              style: const TextStyle(
                color: Color(0xFF10243B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            entry.time,
            style: const TextStyle(color: Color(0xFF8290A6), fontSize: 8),
          ),
        ],
      ),
    );
  }
}
