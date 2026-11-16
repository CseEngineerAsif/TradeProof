import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/connection_service.dart';
import 'common_interface_page.dart';
import 'connections_page.dart';
import 'credentials_page.dart';
import 'portfolio_page.dart';
import 'worker_dashboard_page.dart';

// Holds the main tradesperson pages and the bottom navigation bar.
class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({super.key, this.isDemo = false, this.demoRole});

  final bool isDemo;
  final String? demoRole;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  final _portfolioKey = GlobalKey<PortfolioPageState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Create a marketplace profile after a real user opens the app.
    if (!widget.isDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureMarketplaceProfile();
      });
    }
  }

  // Makes sure the signed-in tradesperson can appear in the marketplace.
  Future<void> _ensureMarketplaceProfile() async {
    try {
      await ConnectionService.ensureWorkerPost();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not publish tradesperson profile: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep each tab in one place and show the selected tab.
    final pages = <Widget>[
      const DashboardPage(showHeader: false, showTradespeople: false),
      PortfolioPage(key: _portfolioKey),
      const CredentialsPage(),
      WorkerDashboardPage(
        isDemo: widget.isDemo,
        onAddCompletedProject:
            ({
              required String title,
              required String client,
              required String category,
              required String description,
            }) async {
              final added = await _portfolioKey.currentState
                  ?.addCompletedJobProject(
                    title: title,
                    client: client,
                    category: category,
                    description: description,
                  );
              if (added == true && mounted) {
                setState(() => _selectedIndex = 1);
              }
            },
      ),
      const ConnectionsPage(),
      _ProfileTab(
        isDemo: widget.isDemo,
        demoRole: widget.demoRole,
        onSwitchMarketplace: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/dashboard', (_) => false);
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF009E9A),
        unselectedItemColor: const Color(0xFF91A2BC),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_outlined),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'Credentials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Asif',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Displays profile information and account actions for the current user.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.isDemo,
    this.demoRole,
    required this.onSwitchMarketplace,
  });

  final bool isDemo;
  final String? demoRole;
  final VoidCallback onSwitchMarketplace;

  // Signs out a real user or exits the demo profile.
  Future<void> _signOut(BuildContext context) async {
    if (isDemo) {
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
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = isDemo ? null : FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'MD. ASIF HASAN';
    final email = user?.email ?? 'asif.hasan@tradeproof.com';
    final profileId = user?.uid ?? 'TP-BD-884920';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(11, 12, 11, 20),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDCE4EC)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080D1B2E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00A99D),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F1F4),
                        child: Icon(
                          Icons.person,
                          size: 38,
                          color: Color(0xFF29485C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF10243B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF00B8A9),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDemo
                                ? '${demoRole ?? 'Tradesperson'} · Demo Account'
                                : 'Master Electrician & Automation Specialist',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TradeProof ID: $profileId',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF008C75),
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Divider(height: 1, color: Color(0xFFE8EDF2)),
                ),
                _ProfileInfoRow(label: 'Email:', value: email),
                const SizedBox(height: 9),
                _ProfileInfoRow(
                  label: 'Experience:',
                  value: '8+ Years Commercial & Industrial',
                ),
                const SizedBox(height: 9),
                _ProfileInfoRow(
                  label: 'Hourly Rate:',
                  value: '৳1,200 / hr · ৳8,500 / day',
                ),
                const SizedBox(height: 9),
                const _ProfileInfoRow(
                  label: 'Verified Skills:',
                  value: '3-Phase, PLC, Smart DB, Solar',
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _ProfileActionTile(
            icon: Icons.qr_code_2,
            label: 'Show Verifiable QR Code',
            onTap: () => _showProfileCode(
              context,
              displayName: displayName,
              profileId: profileId,
              email: email,
            ),
          ),
          const SizedBox(height: 9),
          _ProfileActionTile(
            icon: Icons.home_outlined,
            label: 'Switch to Customer Marketplace',
            onTap: onSwitchMarketplace,
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, size: 17),
              label: Text(
                isDemo ? 'Exit TradeProof Demo' : 'Log Out of TradeProof',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE31B45),
                backgroundColor: const Color(0xFFFFF3F4),
                side: const BorderSide(color: Color(0xFFFFC4CC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Opens a dialog with the user's profile details.
  void _showProfileCode(
    BuildContext context, {
    required String displayName,
    required String profileId,
    required String email,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.qr_code_2, size: 48, color: Color(0xFF008C95)),
        title: const Text('TradeProof Profile ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SelectableText(
              profileId,
              style: const TextStyle(
                color: Color(0xFF008C75),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'A scannable verification QR code is not configured yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Displays one labeled value in the profile.
class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 98,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF8290A6), fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF10243B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Displays a tappable action on the profile page.
class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDCE4EC)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00A99D), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF10243B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF91A2BC),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
