import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/screens/common_interface_page.dart';

void main() {
  testWidgets('tradesperson home can hide account posts but keep carousels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardPage(
          showHeader: false,
          showTradespeople: false,
          showMarketplacePosts: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Posts from TradeProof accounts'), findsNothing);
    expect(find.text('Posted Trade Work'), findsOneWidget);
    expect(find.text('Top Trade Skill Courses'), findsOneWidget);
  });
}
