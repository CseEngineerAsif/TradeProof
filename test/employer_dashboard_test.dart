import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/services/connection_service.dart';
import 'package:tradeproof/screens/employer_dashboard_page.dart';

void main() {
  testWidgets('employer navigation opens each account tab', (tester) async {
    ConnectionService.beginDemoSession('Employer');
    addTearDown(ConnectionService.endDemoSession);
    await tester.pumpWidget(
      const MaterialApp(home: EmployerDashboardPage(isDemo: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(find.text('Employer overview'), findsOneWidget);

    await tester.tap(find.text('Find workers'));
    await tester.pumpAndSettle();
    expect(find.text('Find workers').first, findsOneWidget);
    expect(
      find.text(
        'Search published tradesperson profiles and send a service request.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('Job posts'), findsOneWidget);

    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    expect(find.text('Messages & requests'), findsOneWidget);

    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();
    expect(find.text('Company profile'), findsOneWidget);
    expect(find.text('David Carter'), findsOneWidget);
  });
}
