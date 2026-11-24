import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/screens/common_interface_page.dart';
import 'package:tradeproof/services/connection_service.dart';

void main() {
  testWidgets('trainer home shows skill and trainer carousels', (tester) async {
    ConnectionService.beginDemoSession('Trainer');
    addTearDown(ConnectionService.endDemoSession);

    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardPage(showHeader: false, trainerHome: true),
      ),
    );
    await tester.pump();

    expect(find.text('Top Skills'), findsOneWidget);
    expect(find.text('Top Trainers'), findsOneWidget);
    expect(find.text('Top Trade Skill Courses'), findsNothing);
  });

  testWidgets('non-trainer home does not show trainer-only carousels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardPage(showHeader: false, employerHome: true),
      ),
    );
    await tester.pump();

    expect(find.text('Top Skills'), findsNothing);
    expect(find.text('Top Trainers'), findsNothing);
  });
}
