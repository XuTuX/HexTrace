import 'package:flutter_test/flutter_test.dart';
import 'package:hexor/game/daily_challenge_entry.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/database_models.dart';

void main() {
  test('already scored daily challenge is blocked with notice', () {
    const challenge = DailyChallengeInfo(
      dateKey: '2026-04-25',
      seed: 459315,
      hasUsedEntry: true,
      myScore: 11550,
    );

    final decision = resolveDailyChallengeLaunch(
      challenge: challenge,
      isLoggedIn: true,
    );

    expect(decision.canLaunch, isFalse);
    expect(decision.sessionConfig, isNull);
    expect(decision.noticeMessage, '오늘의 퍼즐은 하루에 한 번만 가능해요.');
  });

  test('incomplete daily challenge keeps official submission enabled', () {
    const challenge = DailyChallengeInfo(
      dateKey: '2026-04-25',
      seed: 459315,
      hasUsedEntry: true,
    );

    final decision = resolveDailyChallengeLaunch(
      challenge: challenge,
      isLoggedIn: true,
    );

    expect(decision.canLaunch, isTrue);
    expect(decision.sessionConfig?.mode, GameMode.dailyOfficial);
    expect(decision.sessionConfig?.isOfficialScoreSubmission, isTrue);
  });
}
