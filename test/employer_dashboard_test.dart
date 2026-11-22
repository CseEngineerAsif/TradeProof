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

    final navigation = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigation.items.map((item) => item.label).toList(), [
      'Home',
      'Jobs',
      'Search',
      'Connections',
      'Dashboard',
      'Profile',
    ]);
    expect(find.text('Featured workers'), findsOneWidget);
    expect(find.text('Contractor experts'), findsOneWidget);
    expect(find.text('Training for your team'), findsOneWidget);
    expect(find.text('Workers & courses'), findsOneWidget);
    expect(find.text('Enroll · checkout'), findsOneWidget);
    expect(find.text('Top Trade Skill Courses'), findsNothing);

    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('Job posts'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Find workers').first, findsOneWidget);
    expect(
      find.text('Review worker profiles and contact qualified candidates.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    expect(find.text('Applications & messages'), findsOneWidget);
    expect(
      find.text('Review worker requests and manage conversations.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Hiring overview'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Business profile'), findsOneWidget);
    expect(find.text('David Carter'), findsOneWidget);
  });
}
