import 'package:flutter/material.dart';

import 'services/firebase_service.dart';
import 'screens/tradeworker.dart';
import 'screens/common_interface_page.dart';
import 'screens/create_account_page.dart';
import 'screens/get_started_page.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  // Prepare Flutter and Firebase before showing the app.
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const TradeProofApp());
}

// Sets the app's theme, first page, and named navigation routes.
class TradeProofApp extends StatelessWidget {
  const TradeProofApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        useMaterial3: true,
      ),
      home: const GetStartedPage(),
      // Convert route names into the pages the app should open.
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute<void>(builder: (_) => const DashboardPage());
        }
        if (settings.name == '/login') {
          return MaterialPageRoute<void>(builder: (_) => const LoginPage());
        }
        if (settings.name == '/register') {
          return MaterialPageRoute<void>(
            builder: (_) => const CreateAccountPage(),
          );
        }
        if (settings.name == '/home') {
          return MaterialPageRoute<void>(
            builder: (_) => const AuthenticatedShell(),
          );
        }
        return null;
      },
    );
  }
}
