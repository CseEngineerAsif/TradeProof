import 'package:flutter/material.dart';

import 'employer_tabs/employer_connections_tab.dart';
import 'employer_tabs/employer_dashboard_tab.dart';
import 'employer_tabs/employer_home_tab.dart';
import 'employer_tabs/employer_jobs_tab.dart';
import 'employer_tabs/employer_profile_tab.dart';
import 'employer_tabs/employer_worker_search_tab.dart';

class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  State<EmployerDashboardPage> createState() => _EmployerDashboardPageState();
}

class _EmployerDashboardPageState extends State<EmployerDashboardPage> {
  static const _teal = Color(0xFF00999D);
  static const _background = Color(0xFFF3F5F8);

  int _selectedIndex = 0;
  String _workerSearch = '';

  void _openTab(int index) => setState(() => _selectedIndex = index);

  void _searchWorkers(String query) {
    setState(() {
      _workerSearch = query;
      _selectedIndex = 2;
    });
  }

  void _updateWorkerSearch(String query) {
    setState(() => _workerSearch = query);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      EmployerHomeTab(onSearchWorkers: _searchWorkers),
      const EmployerJobsTab(),
      EmployerWorkerSearchTab(
        initialQuery: _workerSearch,
        onQueryChanged: _updateWorkerSearch,
      ),
      const EmployerConnectionsTab(),
      EmployerDashboardTab(
        onSearchWorkers: () => _openTab(2),
        onOpenJobs: () => _openTab(1),
        onOpenConnections: () => _openTab(3),
      ),
      EmployerProfileTab(isDemo: widget.isDemo),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _openTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _teal,
        unselectedItemColor: const Color(0xFF91A2BC),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.manage_search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Connections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
