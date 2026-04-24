import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/database_models.dart';

class DailyChallengeLaunchDecision {
  const DailyChallengeLaunchDecision({
    required this.canLaunch,
    this.sessionConfig,
    this.noticeMessage,
  });

  final bool canLaunch;
  final GameSessionConfig? sessionConfig;
  final String? noticeMessage;
}

DailyChallengeLaunchDecision resolveDailyChallengeLaunch({
  required DailyChallengeInfo challenge,
  required bool isLoggedIn,
}) {
  if (!isLoggedIn) {
    return const DailyChallengeLaunchDecision(
      canLaunch: false,
      noticeMessage: '오늘의 퍼즐은 로그인 후 하루 한 번만 참여할 수 있어요.',
    );
  }

  if (challenge.hasUsedEntry) {
    if (challenge.myScore == null) {
      return DailyChallengeLaunchDecision(
        canLaunch: true,
        sessionConfig: GameSessionConfig(
          mode: GameMode.dailyOfficial,
          seed: challenge.seed,
          dateKey: challenge.dateKey,
          isOfficialScoreSubmission: true,
        ),
      );
    }

    return const DailyChallengeLaunchDecision(
      canLaunch: false,
      noticeMessage: '오늘의 퍼즐은 이미 플레이했어요. 내일 다시 도전해 주세요.',
    );
  }

  return DailyChallengeLaunchDecision(
    canLaunch: true,
    sessionConfig: GameSessionConfig(
      mode: GameMode.dailyOfficial,
      seed: challenge.seed,
      dateKey: challenge.dateKey,
      isOfficialScoreSubmission: true,
    ),
  );
}
