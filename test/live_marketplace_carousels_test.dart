import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/screens/common_interface_page.dart';
import 'package:tradeproof/services/connection_service.dart';

void main() {
  testWidgets('published jobs and courses appear newest-first in View More', (
    tester,
  ) async {
    addTearDown(ConnectionService.endDemoSession);

    ConnectionService.beginDemoSession('Employer');
    await ConnectionService.publishPost(
      type: 'job',
      title: 'Older carousel test job',
      category: 'Plumbing',
      description: 'Earlier employer job post.',
    );
    await ConnectionService.publishPost(
      type: 'job',
      title: 'Latest carousel test job',
      category: 'Electrical',
      description: 'Newest employer job post.',
    );

    ConnectionService.beginDemoSession('Trainer');
    await ConnectionService.publishPost(
      type: 'course',
      title: 'Older carousel test course',
      category: 'Plumbing',
      description: 'Earlier trainer course.',
      priceBdt: 1200,
    );
    await ConnectionService.publishPost(
      type: 'course',
      title: 'Latest carousel test course',
      category: 'Electrical',
      description: 'Newest trainer course.',
      priceBdt: 1800,
    );

    ConnectionService.beginDemoSession('Tradesperson');
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

    Future<void> expectLatestFirst({
      required int carouselIndex,
      required String latestTitle,
      required String olderTitle,
    }) async {
      final viewMore = find.widgetWithText(FilledButton, 'View More');
      await tester.ensureVisible(viewMore.at(carouselIndex));
      await tester.tap(viewMore.at(carouselIndex));
      await tester.pumpAndSettle();

      final list = find.byType(ListView).last;
      final latest = find.descendant(
        of: list,
        matching: find.text(latestTitle),
      );
      final older = find.descendant(of: list, matching: find.text(olderTitle));
      expect(latest, findsOneWidget);
      expect(older, findsOneWidget);
      expect(
        tester.getTopLeft(latest).dy,
        lessThan(tester.getTopLeft(older).dy),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await expectLatestFirst(
      carouselIndex: 0,
      latestTitle: 'Latest carousel test job',
      olderTitle: 'Older carousel test job',
    );
    await expectLatestFirst(
      carouselIndex: 1,
      latestTitle: 'Latest carousel test course',
      olderTitle: 'Older carousel test course',
    );
  });
}
