import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hexor/services/database_service.dart';

class PendingDailySubmission {
  const PendingDailySubmission({
    required this.gameId,
    required this.dateKey,
    required this.seed,
    required this.score,
    required this.replayCode,
    required this.summaryJson,
  });

  final String gameId;
  final String dateKey;
  final int seed;
  final int score;
  final String replayCode;
  final String summaryJson;

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'date_key': dateKey,
      'seed': seed,
      'score': score,
      'replay_code': replayCode,
      'summary_json': summaryJson,
    };
  }

  static PendingDailySubmission? fromJsonString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      return null;
    }

    final map = decoded.map(
      (key, entryValue) => MapEntry(key.toString(), entryValue),
    );

    final gameId = map['game_id']?.toString();
    final dateKey = map['date_key']?.toString();
    final replayCode = map['replay_code']?.toString();
    final summaryJson = map['summary_json']?.toString();
    final seed = map['seed'] is int
        ? map['seed'] as int
        : int.tryParse(map['seed']?.toString() ?? '');
    final score = map['score'] is int
        ? map['score'] as int
        : int.tryParse(map['score']?.toString() ?? '');

    if (gameId == null ||
        dateKey == null ||
        replayCode == null ||
        summaryJson == null ||
        seed == null ||
        score == null) {
      return null;
    }

    return PendingDailySubmission(
      gameId: gameId,
      dateKey: dateKey,
      seed: seed,
      score: score,
      replayCode: replayCode,
      summaryJson: summaryJson,
    );
  }
}

class DailySubmissionService extends GetxService {
  static const String _pendingSubmissionKey = 'pending_daily_submission_v1';

  Future<void> savePendingSubmission({
    required String gameId,
    required String dateKey,
    required int seed,
    required int score,
    required String replayCode,
    required Map<String, dynamic> summary,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = PendingDailySubmission(
      gameId: gameId,
      dateKey: dateKey,
      seed: seed,
      score: score,
      replayCode: replayCode,
      summaryJson: jsonEncode(summary),
    );
    await prefs.setString(
      _pendingSubmissionKey,
      jsonEncode(pending.toJson()),
    );
  }

  Future<PendingDailySubmission?> loadPendingSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    return PendingDailySubmission.fromJsonString(
      prefs.getString(_pendingSubmissionKey),
    );
  }

  Future<void> clearPendingSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSubmissionKey);
  }

  Future<int?> retryPendingSubmissionIfMatches({
    required String gameId,
    required String dateKey,
  }) async {
    final pending = await loadPendingSubmission();
    if (pending == null ||
        pending.gameId != gameId ||
        pending.dateKey != dateKey) {
      return null;
    }

    final dbService = Get.find<DatabaseService>();
    final storedScore = await dbService.submitDailyScore(
      gameId: pending.gameId,
      dateKey: pending.dateKey,
      seed: pending.seed,
      score: pending.score,
      replayCode: pending.replayCode,
      summary: jsonDecode(pending.summaryJson) as Map<String, dynamic>,
    );
    await clearPendingSubmission();
    return storedScore;
  }
}
