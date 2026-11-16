import 'package:flutter/material.dart';
import 'services.dart';

const Color teal = Color(0xFF00919A);
const Color navy = Color(0xFF0B1B2B);
const Color mist = Color(0xFFF4F6FA);
const Color line = Color(0xFFE2E8F0);

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: teal),
      scaffoldBackgroundColor: mist,
      appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );

void push(BuildContext c, Widget w) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class Box extends StatelessWidget {
  final Widget child;
  const Box({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: line),
        ),
        child: child,
      );
}

class Section extends StatelessWidget {
  final String t;
  const Section(this.t, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: navy)),
      );
}

class HeaderBar extends StatelessWidget {
  final String title, sub;
  const HeaderBar(this.title, this.sub, {super.key});
  @override
  Widget build(BuildContext context) {
    final initials = title.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: teal,
          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(sub, style: const TextStyle(color: Color(0xFF7FD6DC), fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

class StatusTag extends StatelessWidget {
  final String s;
  const StatusTag(this.s, {super.key});
  Color get _c {
    if (const ['VERIFIED', 'PASSED', 'APPROVED', 'SHORTLISTED'].contains(s)) return const Color(0xFF16A34A);
    if (const ['EXPIRED', 'FAILED', 'REJECTED', 'DECLINED'].contains(s)) return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _c.withAlpha(30), borderRadius: BorderRadius.circular(6)),
        child: Text(s, style: TextStyle(color: _c, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class CountStat extends StatelessWidget {
  final String label, col;
  final bool Function(Doc)? where;
  const CountStat(this.label, this.col, {super.key, this.where});
  @override
  Widget build(BuildContext context) => Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          StreamBuilder<List<Doc>>(
            stream: repo.watch(col),
            builder: (c, s) {
              final f = where;
              final l = s.data ?? <Doc>[];
              final n = f == null ? l.length : l.where(f).length;
              return Text('$n', style: const TextStyle(color: teal, fontSize: 24, fontWeight: FontWeight.w800));
            },
          ),
        ]),
      );
}

class CollectionView extends StatefulWidget {
  final String col;
  final Widget Function(BuildContext, Doc) item;
  final bool Function(Doc)? where;
  final String empty;
  const CollectionView({super.key, required this.col, required this.item, this.where, this.empty = 'Nothing here yet.'});
  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  late final Stream<List<Doc>> _s = repo.watch(widget.col);
  @override
  Widget build(BuildContext context) => StreamBuilder<List<Doc>>(
        stream: _s,
        builder: (c, snap) {
          if (snap.hasError) return Text('Could not load data: ${snap.error}');
          if (!snap.hasData) {
            return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          }
          final f = widget.where;
          final l = f == null ? snap.data! : snap.data!.where(f).toList();
          if (l.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.empty, style: const TextStyle(color: Colors.grey)),
            );
          }
          return Column(children: [for (final d in l) widget.item(c, d)]);
        },
      );
}

class StarRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarRow({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Icon(i <= value ? Icons.star : Icons.star_border, color: Colors.amber, size: 26),
          ),
      ]);
}

/// Simple dialog form: every field is required.
Future<void> showForm(BuildContext ctx, String title, List<String> labels,
    Future<void> Function(List<String>) onSubmit) async {
  final cs = labels.map((_) => TextEditingController()).toList();
  String? err;
  await showDialog<void>(
    context: ctx,
    builder: (dc) => StatefulBuilder(
      builder: (dc, setS) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(controller: cs[i], decoration: InputDecoration(labelText: labels[i])),
              ),
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(err!, style: const TextStyle(color: Colors.red)),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final v = cs.map((c) => c.text.trim()).toList();
              if (v.any((x) => x.isEmpty)) {
                setS(() => err = 'Fill in every field.');
                return;
              }
              try {
                await onSubmit(v);
                if (dc.mounted) Navigator.pop(dc);
              } catch (e) {
                setS(() => err = 'Could not save: ${errText(e)}');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
