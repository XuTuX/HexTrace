import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/database_models.dart';

class DailyChallengeLaunchDecision {
  const DailyChallengeLaunchDecision({
    required this.sessionConfig,
    this.noticeMessage,
  });

  final GameSessionConfig sessionConfig;
  final String? noticeMessage;
}

DailyChallengeLaunchDecision resolveDailyChallengeLaunch({
  required DailyChallengeInfo challenge,
  required bool isLoggedIn,
}) {
  if (isLoggedIn && !challenge.hasUsedOfficialAttempt) {
    return DailyChallengeLaunchDecision(
      sessionConfig: GameSessionConfig(
        mode: GameMode.dailyOfficial,
        seed: challenge.seed,
        dateKey: challenge.dateKey,
        isOfficialScoreSubmission: true,
      ),
    );
  }

  return DailyChallengeLaunchDecision(
    sessionConfig: GameSessionConfig(
      mode: GameMode.dailyPractice,
      seed: challenge.seed,
      dateKey: challenge.dateKey,
      isOfficialScoreSubmission: false,
    ),
    noticeMessage: isLoggedIn
        ? '오늘의 공식 기록은 이미 제출되어 연습 모드로 시작합니다.'
        : '로그인하면 오늘의 퍼즐 공식 랭킹에 참여할 수 있어요. 연습 모드로 시작합니다.',
  );
}
