import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services.dart';
import 'ui.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget page;
  _Tab(this.label, this.icon, this.page);
}

List<_Tab> tabsFor(String role) {
  final profile = _Tab('Profile', Icons.person_outline, const ProfileTab());
  switch (role) {
    case 'employer':
      return [
        _Tab('Dashboard', Icons.home_outlined, const EmployerHome()),
        _Tab('Search', Icons.search, const WorkerSearch()),
        _Tab('Jobs', Icons.work_outline, const EmployerJobs()),
        profile,
      ];
    case 'client':
      return [
        _Tab('Home', Icons.home_outlined, const ClientHome()),
        _Tab('Search', Icons.search, const WorkerSearch()),
        _Tab('Reviews', Icons.star_outline, const ReviewsPage()),
        profile,
      ];
    case 'trainer':
      return [
        _Tab('Home', Icons.home_outlined, const TrainerHome()),
        _Tab('Assess', Icons.assignment_outlined, const AssessmentsPage()),
        _Tab('Evidence', Icons.folder_open, const EvidencePage()),
        _Tab('Issue', Icons.workspace_premium_outlined, const IssueCredentialPage()),
        profile,
      ];
    default:
      return [
        _Tab('Home', Icons.home_outlined, const WorkerHome()),
        _Tab('Portfolio', Icons.photo_library_outlined, const PortfolioPage()),
        _Tab('Credentials', Icons.workspace_premium_outlined, const CredentialsPage()),
        _Tab('Safety', Icons.shield_outlined, const SafetyPage()),
        profile,
      ];
  }
}

class Shell extends StatefulWidget {
  final AppUser user;
  const Shell({super.key, required this.user});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  late final List<_Tab> tabs = tabsFor(widget.user.role);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tabs[i].label == 'Home' || tabs[i].label == 'Dashboard' ? 'TradeProof' : tabs[i].label)),
        body: tabs[i].page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (x) => setState(() => i = x),
          destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
        ),
      );
}

const EdgeInsets _pad = EdgeInsets.all(16);

/* ------------------------------ shared cards ------------------------------ */
class CredCard extends StatelessWidget {
  final Doc d;
  const CredCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final h = (d['hash'] ?? '').toString();
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${d['name']}', style: const TextStyle(fontWeight: FontWeight.w700))),
          StatusTag('${d['status']}'),
        ]),
        Text('${d['issuer']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text('Issued: ${d['date']}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
        if (h.length >= 12)
          Text('Seal: ${h.substring(0, 12)}...', style: const TextStyle(color: teal, fontSize: 11, fontFamily: 'monospace')),
      ]),
    );
  }
}

class SkillBars extends StatelessWidget {
  final Doc d;
  const SkillBars(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final skills = List<String>.from(d['skills'] ?? <String>[]);
    if (skills.isEmpty) return const Text('No verified skills yet.', style: TextStyle(color: Colors.grey));
    return Column(children: [
      for (final s in skills)
        Builder(builder: (c) {
          final parts = s.split(':');
          final pct = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(parts[0], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$pct%', style: const TextStyle(color: teal, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: pct / 100, minHeight: 7, color: teal, backgroundColor: line, borderRadius: BorderRadius.circular(8)),
            ]),
          );
        }),
    ]);
  }
}

class WorkerCard extends StatelessWidget {
  final Doc d;
  const WorkerCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(d['tags'] ?? <String>[]);
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(backgroundColor: teal, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('${d['role']} · ${d['exp']} yrs exp', style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
          Text('★ ${d['rating']}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        if (tags.isNotEmpty) Wrap(spacing: 6, children: [for (final t in tags) Chip(label: Text(t, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)]),
        OutlinedButton(onPressed: () => push(context, WorkerProfilePage(d)), child: const Text('View profile')),
      ]),
    );
  }
}

class WorkerProfilePage extends StatelessWidget {
  final Doc d;
  const WorkerProfilePage(this.d, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Worker profile')),
        body: ListView(padding: _pad, children: [
          HeaderBar('${d['name']}', '${d['role']} · ${d['loc']}'),
          const Section('About'),
          Box(child: Text('${d['about']}')),
          const Section('Verified skills'),
          Box(child: SkillBars(d)),
          Row(children: [
            Expanded(child: Box(child: Text('Experience\n${d['exp']} years', style: const TextStyle(fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: Box(child: Text('Rating\n★ ${d['rating']}', style: const TextStyle(fontWeight: FontWeight.w700)))),
          ]),
          ElevatedButton(onPressed: () => toast(context, 'Quote request sent to ${d['name']}.'), child: const Text('Request quote')),
        ]),
      );
}

class WorkerSearch extends StatefulWidget {
  const WorkerSearch({super.key});
  @override
  State<WorkerSearch> createState() => _WorkerSearchState();
}

class _WorkerSearchState extends State<WorkerSearch> {
  String q = '';
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        TextField(
          onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search trades, skills, or names...'),
        ),
        const SizedBox(height: 12),
        CollectionView(
          col: 'workers',
          empty: 'No workers found.',
          where: (d) => '${d['name']} ${d['role']} ${((d['tags'] as List?) ?? []).join(' ')}'.toLowerCase().contains(q),
          item: (c, d) => WorkerCard(d),
        ),
      ]);
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final u = repo.session.value;
    return ListView(padding: _pad, children: [
      HeaderBar(u?.name ?? '', u?.role ?? ''),
      const SizedBox(height: 12),
      Box(child: Text('Email: ${u?.email ?? ''}')),
      Box(child: Text(repo.isFirebase ? 'Mode: Firebase (live backend)' : 'Mode: Demo (data resets when the app closes)')),
      if (u?.role == 'worker') ...[
        const Section('My verified skills'),
        CollectionView(col: 'workers', where: (d) => d['name'] == me, empty: 'No skills recorded yet.', item: (c, d) => Box(child: SkillBars(d))),
      ],
      const SizedBox(height: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: navy),
        onPressed: () => repo.signOut(),
        child: const Text('Log out'),
      ),
    ]);
  }
}

/* -------------------------------- Tradesperson ------------------------------ */
class WorkerHome extends StatelessWidget {
  const WorkerHome({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        HeaderBar(me, 'Tradesperson'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CountStat('Verified credentials', 'credentials', where: (d) => d['holder'] == me && d['status'] == 'VERIFIED')),
          const SizedBox(width: 10),
          Expanded(child: CountStat('My applications', 'applications', where: (d) => d['applicant'] == me)),
        ]),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () => push(context, const JobsPage()), child: const Text('Find work'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: () => push(context, const SkillGapPage()), child: const Text('Skill analysis'))),
        ]),
        const Section('Verification timeline'),
        CollectionView(col: 'credentials', where: (d) => d['holder'] == me, empty: 'No credentials yet.', item: (c, d) => CredCard(d)),
      ]);
}

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  Future<void> _photo(BuildContext context) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (x == null) return;
      final url = await repo.uploadImage(x.path);
      if (url == null) {
        if (context.mounted) toast(context, 'Photo upload needs Firebase Storage (not available in demo mode).');
        return;
      }
      await repo.add('portfolio', {'holder': me, 'title': 'Work photo', 'client': 'Awaiting verification', 'status': 'PENDING', 'imageUrl': url});
      if (context.mounted) toast(context, 'Photo uploaded for verification.');
    } catch (e) {
      if (context.mounted) toast(context, 'Upload failed: ${errText(e)}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add project'),
          onPressed: () => showForm(context, 'Add project', ['Project title', 'Client / site'],
              (v) => repo.add('portfolio', {'holder': me, 'title': v[0], 'client': v[1], 'status': 'PENDING'})),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
          const Text('Visual proof of compliance and workmanship.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _photo(context), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Upload work photo')),
          const SizedBox(height: 10),
          CollectionView(
            col: 'portfolio',
            where: (d) => d['holder'] == me,
            empty: 'No projects yet. Tap "Add project".',
            item: (c, d) {
              final url = d['imageUrl'];
              return Box(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (url is String && url.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Image.network(url, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  Row(children: [
                    Expanded(child: Text('${d['title']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                    StatusTag('${d['status']}'),
                  ]),
                  Text('${d['client']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ]),
              );
            },
          ),
        ]),
      );
}

class CredentialsPage extends StatelessWidget {
  const CredentialsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        const Text('Official licensing, registrations & stamps.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        CollectionView(col: 'credentials', where: (d) => d['holder'] == me, empty: 'No credentials yet. A trainer can issue one after your assessment.', item: (c, d) => CredCard(d)),
        OutlinedButton(onPressed: () => push(context, const SkillGapPage()), child: const Text('View skill gap analysis')),
      ]);
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add certificate'),
          onPressed: () => showForm(context, 'Add safety certificate', ['Certificate name', 'Issuing body', 'Validity note (e.g. Valid until 2027)'],
              (v) => repo.add('safety', {'holder': me, 'name': v[0], 'issuer': v[1], 'note': v[2], 'status': 'PENDING'})),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
          StreamBuilder<List<Doc>>(
            stream: repo.watch('safety'),
            builder: (c, s) {
              final n = (s.data ?? <Doc>[]).where((d) => d['holder'] == me && d['status'] == 'EXPIRED').length;
              if (n == 0) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x1ADC2626), borderRadius: BorderRadius.circular(10)),
                child: Text('Action required: $n safety certificate(s) have lapsed.', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
              );
            },
          ),
          CollectionView(
            col: 'safety',
            where: (d) => d['holder'] == me,
            empty: 'No safety certificates yet.',
            item: (c, d) => Box(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${d['name']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  StatusTag('${d['status']}'),
                ]),
                Text('${d['issuer']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                Text('${d['note']}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ]),
            ),
          ),
        ]),
      );
}

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Find work')),
        body: ListView(padding: _pad, children: [
          const Text('Compliance-matched roles for your verified skills.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          CollectionView(
            col: 'jobs',
            empty: 'No jobs posted yet.',
            item: (c, d) => InkWell(
              onTap: () => push(c, JobDetail(d)),
              child: Box(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['match']}% match', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 12)),
                  Text('${d['title']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${d['company']} · ${d['location']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  Text('${d['pay']}', style: const TextStyle(color: teal, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ]),
      );
}

class JobDetail extends StatelessWidget {
  final Doc d;
  const JobDetail(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final req = List<String>.from(d['req'] ?? <String>[]);
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity details')),
      body: ListView(padding: _pad, children: [
        HeaderBar('${d['title']}', '${d['company']} · ${d['location']}'),
        const SizedBox(height: 12),
        Box(child: Text('Pay: ${d['pay']}    Match: ${d['match']}%', style: const TextStyle(fontWeight: FontWeight.w700))),
        const Section('Required skills & certs'),
        Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final r in req) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('• $r'))])),
        ElevatedButton(
          onPressed: () async {
            try {
              await repo.add('applications', {'jobId': d['id'], 'jobTitle': d['title'], 'applicant': me, 'match': d['match'] ?? 0, 'status': 'NEW'});
              if (context.mounted) {
                toast(context, 'Applied. Your verified profile was shared.');
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) toast(context, 'Could not apply: ${errText(e)}');
            }
          },
          child: const Text('Verify & apply now'),
        ),
      ]),
    );
  }
}

class SkillGapPage extends StatelessWidget {
  const SkillGapPage({super.key});
  Widget _course(BuildContext c, String t, String sub, String price) => Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Row(children: [
            Expanded(child: Text(price, style: const TextStyle(fontWeight: FontWeight.w800))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(110, 40), backgroundColor: navy),
              onPressed: () => toast(c, 'Enrolled in $t.'),
              child: const Text('Enroll now'),
            ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Skill analysis')),
        body: ListView(padding: _pad, children: [
          Row(children: const [
            Expanded(child: Box(child: Text('Met\n3 skills', style: TextStyle(fontWeight: FontWeight.w800)))),
            SizedBox(width: 10),
            Expanded(child: Box(child: Text('Gaps\n2 gaps', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706))))),
          ]),
          const Section('Identified competency gaps'),
          const Box(child: Text('Solar Installation Level 2 (gap 15%)\nRecommended: Solar Grid Systems Cert')),
          const Box(child: Text('High Voltage Substation Safety (missing)\nRequired: Substation Safety Seminar L1')),
          const Section('Upskilling courses'),
          _course(context, 'Solar Grid Systems Integration L2', 'Silicon Valley Training Board · Online & Lab', r'$250 · 4 weeks'),
          _course(context, 'High Voltage Substation Safety L1', 'PG&E Safety Institute · In-person', r'$400 · 2 days'),
        ]),
      );
}

/* --------------------------------- Employer --------------------------------- */
class ApplicantCard extends StatelessWidget {
  final Doc d;
  final bool actions;
  const ApplicantCard(this.d, {super.key, this.actions = false});
  Future<void> _set(BuildContext c, String s) async {
    try {
      await repo.update('applications', d['id'], {'status': s});
      if (c.mounted) toast(c, 'Candidate ${s.toLowerCase()}.');
    } catch (e) {
      if (c.mounted) toast(c, 'Could not update: ${errText(e)}');
    }
  }

  @override
  Widget build(BuildContext context) => Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${d['applicant']}', style: const TextStyle(fontWeight: FontWeight.w800))),
            StatusTag('${d['status']}'),
          ]),
          Text('${d['jobTitle']} · ${d['match']}% match', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          if (actions)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Expanded(child: ElevatedButton(onPressed: () => _set(context, 'SHORTLISTED'), child: const Text('Shortlist'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: () => _set(context, 'DECLINED'), child: const Text('Decline'))),
              ]),
            ),
        ]),
      );
}

class EmployerHome extends StatelessWidget {
  const EmployerHome({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        HeaderBar('Employer Portal', me),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: CountStat('Active jobs', 'jobs')),
          SizedBox(width: 10),
          Expanded(child: CountStat('Applicants', 'applications')),
        ]),
        const Section('Recent applicants'),
        CollectionView(col: 'applications', empty: 'No applicants yet.', item: (c, d) => ApplicantCard(d)),
      ]);
}

class EmployerJobs extends StatelessWidget {
  const EmployerJobs({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        ElevatedButton(
          onPressed: () => showForm(context, 'Post new job', ['Job title', 'Trade category', 'Verification level (e.g. Gold L3)', 'Location'],
              (v) => repo.add('jobs', {'title': v[0], 'company': me, 'location': v[3], 'pay': 'Negotiable', 'match': 90, 'tags': [v[2]], 'req': [v[1], v[2]]})),
          child: const Text('Post new job'),
        ),
        const Section('Applications'),
        CollectionView(col: 'applications', empty: 'No applications yet.', item: (c, d) => ApplicantCard(d, actions: true)),
        const Section('Job posts'),
        CollectionView(
          col: 'jobs',
          empty: 'No jobs posted.',
          item: (c, d) => Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${d['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${d['company']} · ${d['location']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ])),
        ),
      ]);
}

/* ---------------------------------- Client ---------------------------------- */
class ClientHome extends StatelessWidget {
  const ClientHome({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        HeaderBar(me, 'Private client'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CountStat('Reviews given', 'reviews', where: (d) => d['reviewer'] == me)),
          const SizedBox(width: 10),
          const Expanded(child: CountStat('Workers available', 'workers')),
        ]),
        ElevatedButton(
          onPressed: () => push(context, Scaffold(appBar: AppBar(title: const Text('Find workers')), body: const WorkerSearch())),
          child: const Text('Find workers'),
        ),
      ]);
}

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});
  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final worker = TextEditingController(), text = TextEditingController();
  final Map<String, int> ratings = {'Quality of work': 5, 'Timeliness': 5, 'Communication': 5, 'Professionalism': 5, 'Safety standards': 5};
  String err = '';

  Future<void> _submit() async {
    final w = worker.text.trim(), t = text.text.trim();
    if (w.isEmpty || t.length < 5) { setState(() => err = 'Enter the worker name and a short review.'); return; }
    final avg = ratings.values.fold<int>(0, (a, b) => a + b) / ratings.length;
    try {
      await repo.add('reviews', {'reviewer': me, 'worker': w, 'rating': double.parse(avg.toStringAsFixed(1)), 'text': t, 'ratings': ratings});
      worker.clear();
      text.clear();
      if (!mounted) return;
      setState(() => err = '');
      toast(context, 'Review submitted. Thank you!');
    } catch (e) {
      if (mounted) setState(() => err = errText(e));
    }
  }

  @override
  void dispose() { worker.dispose(); text.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        TextField(controller: worker, decoration: const InputDecoration(labelText: 'Worker name (e.g. Jack Carter)')),
        const Section('Rate by category'),
        Box(child: Column(children: [
          for (final k in ratings.keys)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(k),
              StarRow(value: ratings[k]!, onChanged: (v) => setState(() => ratings[k] = v)),
            ]),
        ])),
        TextField(controller: text, maxLines: 4, decoration: const InputDecoration(labelText: 'Write a review')),
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _submit, child: const Text('Submit review')),
        const Section('Reviews'),
        CollectionView(
          col: 'reviews',
          empty: 'No reviews yet.',
          item: (c, d) => Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('★ ${d['rating']}  ${d['worker']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${d['text']}', style: const TextStyle(color: Colors.black54)),
          ])),
        ),
      ]);
}

/* ---------------------------------- Trainer --------------------------------- */
class TrainerHome extends StatelessWidget {
  const TrainerHome({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        HeaderBar(me, 'Trainer / Assessor'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CountStat('Pending assessments', 'assessments', where: (d) => d['status'] == 'SCHEDULED' || d['status'] == 'IN PROGRESS')),
          const SizedBox(width: 10),
          Expanded(child: CountStat('Evidence to review', 'portfolio', where: (d) => d['status'] == 'PENDING')),
        ]),
        const Row(children: [Expanded(child: CountStat('Credentials issued', 'credentials'))]),
      ]);
}

class AssessmentsPage extends StatelessWidget {
  const AssessmentsPage({super.key});
  Future<void> _set(BuildContext c, Doc d, String s) async {
    try {
      await repo.update('assessments', d['id'], {'status': s});
    } catch (e) {
      if (c.mounted) toast(c, 'Could not update: ${errText(e)}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New assessment'),
          onPressed: () => showForm(context, 'New assessment', ['Candidate name', 'Trade (e.g. Electrical)', 'Assessment title', 'Date & time'],
              (v) => repo.add('assessments', {'candidate': v[0], 'trade': v[1], 'title': v[2], 'when': v[3], 'status': 'SCHEDULED'})),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
          CollectionView(
            col: 'assessments',
            empty: 'No assessments scheduled.',
            item: (c, d) {
              final s = '${d['status']}';
              return Box(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${d['candidate']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                    StatusTag(s),
                  ]),
                  Text('${d['trade']} · ${d['title']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  Text('${d['when']}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  if (s == 'SCHEDULED')
                    Padding(padding: const EdgeInsets.only(top: 10), child: ElevatedButton(onPressed: () => _set(c, d, 'IN PROGRESS'), child: const Text('Start assessment'))),
                  if (s == 'IN PROGRESS')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(children: [
                        Expanded(child: ElevatedButton(onPressed: () => _set(c, d, 'PASSED'), child: const Text('Pass'))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: () => _set(c, d, 'FAILED'), child: const Text('Fail'))),
                      ]),
                    ),
                ]),
              );
            },
          ),
        ]),
      );
}

class EvidencePage extends StatelessWidget {
  const EvidencePage({super.key});
  Future<void> _set(BuildContext c, Doc d, String s) async {
    try {
      await repo.update('portfolio', d['id'], {'status': s});
      if (c.mounted) toast(c, 'Evidence ${s.toLowerCase()}.');
    } catch (e) {
      if (c.mounted) toast(c, 'Could not update: ${errText(e)}');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        const Text('Verify practical field evidence submitted by workers.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        CollectionView(
          col: 'portfolio',
          where: (d) => d['status'] == 'PENDING',
          empty: 'No evidence waiting for review.',
          item: (c, d) {
            final url = d['imageUrl'];
            return Box(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (url is String && url.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.network(url, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                Text('${d['holder']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${d['title']} · ${d['client']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: () => _set(c, d, 'REJECTED'), child: const Text('Reject'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: () => _set(c, d, 'VERIFIED'), child: const Text('Approve'))),
                ]),
              ]),
            );
          },
        ),
      ]);
}

class IssueCredentialPage extends StatefulWidget {
  const IssueCredentialPage({super.key});
  @override
  State<IssueCredentialPage> createState() => _IssueCredentialPageState();
}

class _IssueCredentialPageState extends State<IssueCredentialPage> {
  final cand = TextEditingController(),
      name = TextEditingController(text: 'Domestic Electrician (Level 3 Practical)'),
      auth = TextEditingController(text: 'City & Guilds'),
      date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String err = '';

  Future<void> _issue() async {
    final h = cand.text.trim(), n = name.text.trim(), a = auth.text.trim(), d = date.text.trim();
    if (h.isEmpty || n.isEmpty || a.isEmpty || d.isEmpty) { setState(() => err = 'Fill in every field.'); return; }
    try {
      await repo.add('credentials', {'holder': h, 'name': n, 'issuer': a, 'date': d, 'status': 'VERIFIED', 'hash': credHash(n, h, a, d)});
      cand.clear();
      if (!mounted) return;
      setState(() => err = '');
      toast(context, 'Credential issued and sealed.');
    } catch (e) {
      if (mounted) setState(() => err = errText(e));
    }
  }

  @override
  void dispose() { cand.dispose(); name.dispose(); auth.dispose(); date.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: _pad, children: [
        const Text('Mint authorized digital credentials. Each one gets a SHA-256 seal so changes can be detected.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        TextField(controller: cand, decoration: const InputDecoration(labelText: 'Candidate full name (must match their profile)')),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Credential name')),
        const SizedBox(height: 12),
        TextField(controller: auth, decoration: const InputDecoration(labelText: 'Certification authority')),
        const SizedBox(height: 12),
        TextField(controller: date, decoration: const InputDecoration(labelText: 'Issue date (YYYY-MM-DD)')),
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _issue, child: const Text('Issue digital credential')),
      ]);
}
