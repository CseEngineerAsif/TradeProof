import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';

class PrivateClientDashboardPage extends StatelessWidget {
  const PrivateClientDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  Widget build(BuildContext context) => AdminDashboardPage(isDemo: isDemo);
}
