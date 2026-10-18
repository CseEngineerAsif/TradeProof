import 'package:flutter/material.dart';
import 'auth.dart';
import 'screens.dart';
import 'services.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repo = await createRepo();
  runApp(const TradeProofApp());
}

class TradeProofApp extends StatelessWidget {
  const TradeProofApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeProof',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: ValueListenableBuilder<AppUser?>(
        valueListenable: repo.session,
        builder: (context, u, _) =>
            u == null ? const AuthFlow() : Shell(key: ValueKey(u.id), user: u),
      ),
    );
  }
}
