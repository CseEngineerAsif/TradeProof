import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/screens/login_page.dart';
import 'package:tradeproof/services/connection_service.dart';

void main() {
  testWidgets('demo user portal opens an isolated admin dashboard', (
    tester,
  ) async {
    addTearDown(ConnectionService.endDemoSession);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.ensureVisible(find.text('Admin'));
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(ConnectionService.demoAccount?.role, 'Admin');
    expect(find.textContaining('Admin overview · Demo'), findsOneWidget);

    await tester.tap(find.text('Applications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rafiq Hasan'));
    await tester.pumpAndSettle();
    expect(find.text('Trade: Electrician'), findsOneWidget);
    expect(find.text('Preview rafiq-work-history.pdf'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsOneWidget);
  });
}
