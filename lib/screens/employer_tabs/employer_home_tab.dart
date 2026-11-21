import 'package:flutter/material.dart';

import '../common_interface_page.dart';

class EmployerHomeTab extends StatelessWidget {
  const EmployerHomeTab({super.key, required this.onSearchWorkers});

  final ValueChanged<String> onSearchWorkers;

  @override
  Widget build(BuildContext context) {
    return DashboardPage(
      showHeader: false,
      employerHome: true,
      onEmployerSearch: onSearchWorkers,
    );
  }
}
