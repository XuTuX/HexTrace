import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/screens/ranking/ranking_period.dart';
import 'package:hexor/screens/ranking/widgets/ranking_chrome.dart';

void main() {
  testWidgets('renders daily, weekly, and all-time ranking tabs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RankingHeader(
            period: RankingPeriod.weekly,
            onPeriodChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('WEEKLY'), findsOneWidget);
    expect(find.text('명예의 전당'), findsOneWidget);
  });
}
