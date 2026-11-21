import 'package:flutter/material.dart';

import '../../services/connection_service.dart';

const _employerNavy = Color(0xFF10243B);
const _employerTeal = Color(0xFF00999D);

class EmployerDashboardTab extends StatelessWidget {
  const EmployerDashboardTab({
    super.key,
    required this.onSearchWorkers,
    required this.onOpenJobs,
    required this.onOpenConnections,
  });

  final VoidCallback onSearchWorkers;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenConnections;

  @override
  Widget build(BuildContext context) {
    if (!ConnectionService.isSignedIn) {
      return const _EmployerNotice(
        message: 'Sign in to see live jobs, applicants, and account activity.',
      );
    }

    return StreamBuilder<List<MarketplacePost>>(
      stream: ConnectionService.watchMyPosts(type: 'job'),
      builder: (context, jobsSnapshot) {
        if (jobsSnapshot.hasError) {
          return _EmployerNotice(
            message: 'Could not load your jobs: ${jobsSnapshot.error}',
          );
        }
        if (!jobsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = jobsSnapshot.data!;
        final openJobs = jobs.where((job) => job.status == 'published').length;
        return StreamBuilder<List<ConnectionRequest>>(
          stream: ConnectionService.watchRequests(incoming: true),
          builder: (context, requestsSnapshot) {
            if (requestsSnapshot.hasError) {
              return _EmployerNotice(
                message:
                    'Could not load incoming requests: '
                    '${requestsSnapshot.error}',
              );
            }
            if (!requestsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = requestsSnapshot.data!;
            final pending = requests
                .where((request) => request.status == 'pending')
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
              children: [
                const Text(
                  'Employer overview',
                  style: TextStyle(
                    color: _employerNavy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Live activity from your TradeProof account.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Open jobs',
                        value: '$openJobs',
                        icon: Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricCard(
                        label: 'Pending requests',
                        value: '$pending',
                        icon: Icons.mark_email_unread_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricCard(
                        label: 'Total requests',
                        value: '${requests.length}',
                        icon: Icons.people_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _OverviewAction(
                  icon: Icons.search,
                  title: 'Find verified workers',
                  subtitle: 'Browse worker profiles and contact them.',
                  onTap: onSearchWorkers,
                ),
                const SizedBox(height: 9),
                _OverviewAction(
                  icon: Icons.post_add_outlined,
                  title: 'Manage job posts',
                  subtitle: 'Publish an opportunity and review its status.',
                  onTap: onOpenJobs,
                ),
                const SizedBox(height: 9),
                _OverviewAction(
                  icon: Icons.forum_outlined,
                  title: 'Review requests and messages',
                  subtitle: 'Respond to requests and continue accepted chats.',
                  onTap: onOpenConnections,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Recent job posts',
                  style: TextStyle(
                    color: _employerNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (jobs.isEmpty)
                  const _EmployerNotice(
                    message: 'No jobs posted yet. Create your first job post.',
                  )
                else
                  for (final job in jobs.take(5)) _JobSummaryCard(job: job),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _employerTeal, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _employerNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _OverviewAction extends StatelessWidget {
  const _OverviewAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(icon, color: _employerTeal),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _employerNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF91A2BC)),
          ],
        ),
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.job});

  final MarketplacePost job;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.work_outline, color: _employerTeal),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    color: _employerNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  job.category,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            job.status == 'published' ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: _employerTeal,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployerNotice extends StatelessWidget {
  const _EmployerNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  border: Border.all(color: const Color(0xFFDCE4EC)),
  borderRadius: BorderRadius.circular(12),
);
