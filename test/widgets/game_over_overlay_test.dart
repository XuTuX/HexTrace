import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/widgets/game/game_over_overlay.dart';

void main() {
  testWidgets('renders run summary and daily result information',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameOverOverlay(
            runSummary: const GameRunSummary(
              mode: GameMode.dailyOfficial,
              score: 4321,
              maxCombo: 5,
              longestPathLength: 7,
              matchCount: 8,
              invalidAttemptCount: 0,
              remainingTime: 16,
              bestMove: BestMoveSummary(
                pathLength: 7,
                scoreGained: 900,
                combo: 3,
              ),
            ),
            bestScore: 5000,
            isNewHighScore: false,
            onRestart: () {},
            onReplay: () {},
            onShare: () {},
            onHome: () {},
            onRanking: () {},
            isSharing: false,
            dailyStatusLabel: '오늘의 퍼즐 등록 완료',
            dailyStatusDetail: '공식 기록 4321점이 오늘의 랭킹에 반영되었어요.',
            completedMissionTitles: const ['콤보 러시'],
            unlockedAchievementTitles: const ['5000점 돌파'],
          ),
        ),
      ),
    );

    expect(find.text('4321'), findsOneWidget);
    expect(find.text('최대 콤보'), findsOneWidget);
    expect(find.text('최장 경로'), findsOneWidget);
    expect(find.text('7칸 / 900점 / x3'), findsOneWidget);
    expect(find.text('오늘의 퍼즐 등록 완료'), findsOneWidget);
    expect(find.text('콤보 러시'), findsOneWidget);
    expect(find.text('5000점 돌파'), findsOneWidget);
  });
}
