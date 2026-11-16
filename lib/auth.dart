import 'package:flutter/material.dart';
import 'services.dart';
import 'ui.dart';

const Map<String, List<String>> roles = {
  'worker': ['Tradesperson', 'Prove competency, store licenses, share work portfolio.'],
  'employer': ['Employer / Contractor', 'Audit site compliance and verify worker credentials.'],
  'trainer': ['Trainer / Assessor', 'Evaluate practical competency and issue verified stamps.'],
  'client': ['Private Client', 'Hire with peace of mind by checking verified badges.'],
};

final RegExp _emailRe = RegExp(r'^\S+@\S+\.\S+$');

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});
  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  String page = 'splash';
  void go(String p) => setState(() => page = p);
  @override
  Widget build(BuildContext context) {
    if (page == 'login') return LoginPage(onNav: go);
    if (page == 'reg') return RegisterPage(onNav: go);
    return SplashPage(onNav: go);
  }
}

class SplashPage extends StatelessWidget {
  final void Function(String) onNav;
  const SplashPage({super.key, required this.onNav});

  Widget _card(String t, String d) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E2D42), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const CircleAvatar(radius: 20, backgroundColor: teal, child: Icon(Icons.check_circle_outline, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 3),
              Text(d, style: const TextStyle(color: Color(0xFF9FB0C6), fontSize: 12.5)),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), children: [
            Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: teal, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TradeProof', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  Text('Verified Skills. Trusted Trades.',
                      style: TextStyle(color: teal, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ]),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/splash.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            _card('Prove Your Skills', 'Digitize and authenticate your practical credentials and safety cards.'),
            _card('Find Verified Workers', 'Instant visual compliance audits for employers and contractors.'),
            _card('Build Civic Trust', 'Raise industry standards through direct proof of on-site competence.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => onNav('reg'), child: const Text('Get Started')),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already verified? '),
              GestureDetector(
                onTap: () => onNav('login'),
                child: const Text('Login here', style: TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
              ),
            ]),
          ]),
        ),
      );
}

class LoginPage extends StatefulWidget {
  final void Function(String) onNav;
  const LoginPage({super.key, required this.onNav});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final em = TextEditingController(), pw = TextEditingController();
  String err = '';
  bool busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() { busy = true; err = ''; });
    try {
      await job();
    } catch (e) {
      if (mounted) setState(() => err = errText(e));
    }
    if (mounted) setState(() => busy = false);
  }

  void _login() {
    final e = em.text.trim(), p = pw.text;
    if (!_emailRe.hasMatch(e)) { setState(() => err = 'Enter a valid email address.'); return; }
    if (p.length < 6) { setState(() => err = 'Password must be at least 6 characters.'); return; }
    _run(() => repo.signIn(e, p));
  }

  @override
  void dispose() { em.dispose(); pw.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Login'), leading: BackButton(onPressed: () => widget.onNav('splash'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Verify identity to access your compliance locker.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          TextField(controller: em, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')),
          const SizedBox(height: 12),
          TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(err, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: busy ? null : _login, child: Text(busy ? 'Please wait...' : 'Secure Login')),
          if (!repo.isFirebase) ...[
            const Section('Demo mode: quick access'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in roles.keys)
                OutlinedButton(onPressed: busy ? null : () => _run(() => repo.demoLogin(r)), child: Text(roles[r]![0].split(' /')[0])),
            ]),
          ],
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('New to TradeProof? '),
            GestureDetector(
              onTap: () => widget.onNav('reg'),
              child: const Text('Create Account', style: TextStyle(color: teal, fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
      );
}

class RegisterPage extends StatefulWidget {
  final void Function(String) onNav;
  const RegisterPage({super.key, required this.onNav});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nm = TextEditingController(), em = TextEditingController(), pw = TextEditingController();
  String role = 'worker', err = '';
  bool busy = false;

  Future<void> _submit() async {
    final n = nm.text.trim(), e = em.text.trim(), p = pw.text;
    if (n.length < 2) { setState(() => err = 'Enter your full name.'); return; }
    if (!_emailRe.hasMatch(e)) { setState(() => err = 'Enter a valid email address.'); return; }
    if (p.length < 6) { setState(() => err = 'Password must be at least 6 characters.'); return; }
    setState(() { busy = true; err = ''; });
    try {
      await repo.register(n, e, p, role);
    } catch (x) {
      if (mounted) setState(() => err = errText(x));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() { nm.dispose(); em.dispose(); pw.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Account'), leading: BackButton(onPressed: () => widget.onNav('splash'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Step 1 of 2: Select your portal role', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          for (final r in roles.keys)
            GestureDetector(
              onTap: () => setState(() => role = r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: role == r ? teal : line, width: role == r ? 2 : 1),
                ),
                child: Row(children: [
                  Icon(role == r ? Icons.radio_button_checked : Icons.radio_button_off, color: teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(roles[r]![0], style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(roles[r]![1], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          TextField(controller: nm, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: em, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')),
          const SizedBox(height: 12),
          TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'Password (min 6 characters)')),
          if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(err, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: busy ? null : _submit, child: Text(busy ? 'Please wait...' : 'Register Trade Profile')),
        ]),
      );
}
