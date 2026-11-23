import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/screens/create_account_page.dart';

void main() {
  testWidgets('professional registration collects a review application', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountPage()));

    expect(find.text('Tradesperson'), findsOneWidget);
    expect(find.text('Employer / Contractor'), findsOneWidget);
    expect(find.text('Trainer / Assessor'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);

    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'Taylor Worker');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'taylor@example.com');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'secure-password');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register Trade Profile'));
    await tester.tap(find.text('Register Trade Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Trade / occupation'), findsOneWidget);
    expect(find.text('Relevant work experience'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Choose document'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Submit application for review'), findsOneWidget);
  });

  testWidgets('trainer applications ask for training credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountPage()));

    await tester.tap(find.text('Trainer / Assessor'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'Trainer Example');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'trainer@example.com');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'secure-password');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register Trade Profile'));
    await tester.tap(find.text('Register Trade Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Training specialty'), findsOneWidget);
    expect(find.text('Certifications and accreditations'), findsOneWidget);
    expect(find.text('Training and assessment experience'), findsOneWidget);
  });
}
