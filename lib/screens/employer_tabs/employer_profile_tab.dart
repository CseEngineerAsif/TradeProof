import 'package:flutter/material.dart';

import '../account_profile_tab.dart';

class EmployerProfileTab extends StatelessWidget {
  const EmployerProfileTab({super.key, required this.isDemo});

  final bool isDemo;

  @override
  Widget build(BuildContext context) => AccountProfileTab(
    role: 'Employer / Contractor',
    isDemo: isDemo,
  );
}
