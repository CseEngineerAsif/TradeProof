import 'package:flutter/material.dart';

// Shows a sample portal for a selected account role.
class RoleDemoPage extends StatelessWidget {
  const RoleDemoPage({
    super.key,
    required this.role,
    required this.icon,
    required this.description,
    required this.features,
  });

  final String role;
  final IconData icon;
  final String description;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text('$role Portal'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10243B),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'DEMO',
                style: TextStyle(
                  color: Color(0xFF008C96),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Introduce this role and explain what its portal is for.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 34, color: const Color(0xFF009E9A)),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to your $role portal',
                    style: const TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          // List the example tools available to this role.
          const SizedBox(height: 16),
          const Text(
            'PORTAL FEATURES',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF009E9A),
                ),
                title: Text(feature),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/dashboard', (_) => false),
            icon: const Icon(Icons.logout),
            label: const Text('Exit demo'),
          ),
        ],
      ),
    );
  }
}
