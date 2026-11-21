import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/connection_service.dart';

class EmployerProfileTab extends StatelessWidget {
  const EmployerProfileTab({super.key, required this.isDemo});

  final bool isDemo;

  Future<void> _signOut(BuildContext context) async {
    if (isDemo) {
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
      if (context.mounted) _showMessage(context, authErrorMessage(error));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final name = ConnectionService.currentUserName?.trim();
    final companyName = name == null || name.isEmpty
        ? isDemo
              ? 'Demo employer account'
              : 'Employer account'
        : name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      children: [
        const Text(
          'Company profile',
          style: TextStyle(
            color: Color(0xFF10243B),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE0F4F2),
                child: Icon(Icons.business_outlined, color: Color(0xFF00999D)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: Color(0xFF10243B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ConnectionService.currentUserEmail ??
                          (isDemo ? 'Demo mode' : 'Not signed in'),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF00999D)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your employer account can publish jobs, review requests, '
                  'and message other accounts after a request is accepted.',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout, size: 17),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF10243B),
            side: const BorderSide(color: Color(0xFFDCE4EC)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  border: Border.all(color: const Color(0xFFDCE4EC)),
  borderRadius: BorderRadius.circular(12),
);
