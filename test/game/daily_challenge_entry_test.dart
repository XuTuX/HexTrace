import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/game/daily_challenge_entry.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/database_models.dart';

void main() {
  group('resolveDailyChallengeLaunch', () {
    const challenge = DailyChallengeInfo(
      dateKey: '2026-04-12',
      seed: 123456,
      hasUsedEntry: false,
    );

    test('returns official mode for logged in users with an unused attempt',
        () {
      final decision = resolveDailyChallengeLaunch(
        challenge: challenge,
        isLoggedIn: true,
      );

      expect(decision.sessionConfig!.mode, GameMode.dailyOfficial);
      expect(decision.sessionConfig!.seed, 123456);
      expect(decision.sessionConfig!.dateKey, '2026-04-12');
      expect(decision.sessionConfig!.isOfficialScoreSubmission, isTrue);
      expect(decision.noticeMessage, isNull);
    });

    test('blocks launch when the daily entry is already used', () {
      final decision = resolveDailyChallengeLaunch(
        challenge: const DailyChallengeInfo(
          dateKey: '2026-04-12',
          seed: 123456,
          hasUsedEntry: true,
          myScore: 4200,
        ),
        isLoggedIn: true,
      );

      expect(decision.canLaunch, isFalse);
      expect(decision.sessionConfig, isNull);
      expect(decision.noticeMessage, isNotNull);
    });

    test('blocks launch for guests', () {
      final decision = resolveDailyChallengeLaunch(
        challenge: challenge,
        isLoggedIn: false,
      );

      expect(decision.canLaunch, isFalse);
      expect(decision.sessionConfig, isNull);
      expect(decision.noticeMessage, isNotNull);
    });
  });
}
