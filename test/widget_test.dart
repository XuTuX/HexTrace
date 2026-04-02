import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/app.dart';

void main() {
  testWidgets('loads the puzzle prototype shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('점수'), findsOneWidget);
    expect(find.text('색 흐름'), findsOneWidget);
    expect(find.text('새 게임'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
