import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hexor/services/database_models.dart';
import 'package:hexor/utils/kst_clock.dart';

class DatabaseService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool _coerceBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == 't' || normalized == '1';
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _coerceMap(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return _coerceMap(value.first);
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic entryValue) => MapEntry(key.toString(), entryValue),
      );
    }
    return <String, dynamic>{};
  }

  int? _coerceNullableIntResponse(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is int) {
      return response;
    }
    return _coerceInt(response);
  }

  List<Map<String, dynamic>> _mapLeaderboardRows(dynamic response) {
    final rows = List<Map<String, dynamic>>.from(response as List? ?? []);
    return rows
        .map(
          (row) => {
            'user_id': row['user_id'],
            'score': _coerceInt(row['score']) ?? 0,
            'rank': _coerceInt(row['rank']) ?? 0,
            'profiles': {
              'nickname':
                  (row['nickname'] as String?)?.trim().isNotEmpty == true
                      ? row['nickname']
                      : 'Player',
              'avatar_url': row['avatar_url'],
            },
          },
        )
        .toList();
  }

  DailyChallengeInfo _mapDailyChallenge(dynamic response) {
    final row = _coerceMap(response);
    return DailyChallengeInfo(
      dateKey: _coerceString(row['date_key']) ?? KstClock.currentDateKey(),
      seed: _coerceInt(row['seed']) ?? 0,
      hasUsedEntry: _coerceBool(
        row['has_used_entry'] ?? row['has_used_official_attempt'],
      ),
      myScore: _coerceInt(row['my_score']),
    );
  }

  WeeklySeasonSummary? _mapWeeklySeasonSummary(dynamic response) {
    if (response == null) {
      return null;
    }

    final row = _coerceMap(response);
    if (row.isEmpty) {
      return null;
    }

    final participantCount = _coerceInt(row['participant_count']) ?? 0;
    final rank = _coerceInt(row['rank']);
    final score = _coerceInt(row['score']) ?? 0;
    final tierValue = _coerceString(row['tier']);
    final tier = tierValue != null
        ? SeasonTier.fromValue(tierValue)
        : SeasonTier.fromScore(score);

    return WeeklySeasonSummary(
      weekKey: _coerceString(row['week_key']) ?? KstClock.currentWeekKey(),
      participantCount: participantCount,
      tier: tier,
      rank: rank,
      score: score,
    );
  }

  Future<int?> getMyBestScore(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase.rpc(
      'get_my_best_score',
      params: {'p_game_id': gameId},
    );

    return _coerceNullableIntResponse(response);
  }

  Future<int> saveScore(String gameId, int newScore) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final response = await _supabase.rpc(
      'submit_score',
      params: {
        'p_game_id': gameId,
        'p_score': newScore,
      },
    );

    final bestScore = _coerceInt(response);
    if (bestScore == null) {
      throw StateError('submit_score 응답이 비정상적입니다.');
    }

    debugPrint(
      '🟢 [DatabaseService] Score upserted: gameId=$gameId userId=$userId submitted=$newScore best=$bestScore',
    );
    return bestScore;
  }

  Future<int> saveWeeklyScore(String gameId, int newScore) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final response = await _supabase.rpc(
      'submit_weekly_score',
      params: {
        'p_game_id': gameId,
        'p_score': newScore,
      },
    );

    final bestScore = _coerceInt(response);
    if (bestScore == null) {
      throw StateError('submit_weekly_score 응답이 비정상적입니다.');
    }

    debugPrint(
      '🟢 [DatabaseService] Weekly score upserted: gameId=$gameId userId=$userId submitted=$newScore best=$bestScore',
    );
    return bestScore;
  }

  Future<DailyChallengeInfo> getDailyChallenge(String gameId) async {
    final response = await _supabase.rpc(
      'get_daily_challenge',
      params: {'p_game_id': gameId},
    );
    return _mapDailyChallenge(response);
  }

  Future<DailyChallengeInfo> claimDailyChallengeEntry(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final response = await _supabase.rpc(
      'claim_daily_challenge_entry',
      params: {'p_game_id': gameId},
    );
    return _mapDailyChallenge(response);
  }

  Future<int> submitDailyScore({
    required String gameId,
    required String dateKey,
    required int seed,
    required int score,
    required String replayCode,
    required Map<String, dynamic> summary,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final response = await _supabase.rpc(
      'submit_daily_score',
      params: {
        'p_game_id': gameId,
        'p_date_key': dateKey,
        'p_seed': seed,
        'p_score': score,
        'p_replay_code': replayCode,
        'p_summary_json': jsonEncode(summary),
      },
    );

    final storedScore = _coerceInt(response);
    if (storedScore == null) {
      throw StateError('submit_daily_score 응답이 비정상적입니다.');
    }

    return storedScore;
  }

  Future<int?> getMyRank(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase.rpc(
      'get_my_rank',
      params: {'p_game_id': gameId},
    );

    return _coerceNullableIntResponse(response);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(
    String gameId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_leaderboard',
        params: {
          'p_game_id': gameId,
          'p_limit': limit,
        },
      );

      return _mapLeaderboardRows(response);
    } catch (e) {
      debugPrint('🔴 Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<int?> getMyDailyRank(String gameId, {String? dateKey}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc(
        'get_my_daily_rank',
        params: {
          'p_game_id': gameId,
          if (dateKey != null) 'p_date_key': dateKey,
        },
      );
      return _coerceNullableIntResponse(response);
    } catch (e) {
      debugPrint('🔴 Error fetching daily rank: $e');
      return null;
    }
  }

  Future<int?> getMyDailyBestScore(String gameId, {String? dateKey}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc(
        'get_my_daily_best_score',
        params: {
          'p_game_id': gameId,
          if (dateKey != null) 'p_date_key': dateKey,
        },
      );
      return _coerceNullableIntResponse(response);
    } catch (e) {
      debugPrint('🔴 Error fetching daily best score: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDailyLeaderboard(
    String gameId, {
    int limit = 20,
    String? dateKey,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_daily_leaderboard',
        params: {
          'p_game_id': gameId,
          'p_limit': limit,
          if (dateKey != null) 'p_date_key': dateKey,
        },
      );
      return _mapLeaderboardRows(response);
    } catch (e) {
      debugPrint('🔴 Error fetching daily leaderboard: $e');
      return [];
    }
  }

  Future<int?> getMyWeeklyRank(String gameId, {String? weekKey}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc(
        weekKey == null ? 'get_my_weekly_rank' : 'get_my_weekly_rank_by_week',
        params: {
          'p_game_id': gameId,
          if (weekKey != null) 'p_week_key': weekKey,
        },
      );
      return _coerceNullableIntResponse(response);
    } catch (e) {
      debugPrint('🔴 Error fetching weekly rank: $e');
      return null;
    }
  }

  Future<int?> getMyWeeklyBestScore(String gameId, {String? weekKey}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc(
        weekKey == null
            ? 'get_my_weekly_best_score'
            : 'get_my_weekly_best_score_by_week',
        params: {
          'p_game_id': gameId,
          if (weekKey != null) 'p_week_key': weekKey,
        },
      );
      return _coerceNullableIntResponse(response);
    } catch (e) {
      debugPrint('🔴 Error fetching weekly best score: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard(
    String gameId, {
    int limit = 20,
    String? weekKey,
  }) async {
    try {
      final response = await _supabase.rpc(
        weekKey == null
            ? 'get_weekly_leaderboard'
            : 'get_weekly_leaderboard_by_week',
        params: {
          'p_game_id': gameId,
          'p_limit': limit,
          if (weekKey != null) 'p_week_key': weekKey,
        },
      );
      return _mapLeaderboardRows(response);
    } catch (e) {
      debugPrint('🔴 Error fetching weekly leaderboard: $e');
      return [];
    }
  }

  Future<WeeklySeasonSummary?> getWeeklySeasonSummary(String gameId) async {
    try {
      final response = await _supabase.rpc(
        'get_my_weekly_season_summary',
        params: {'p_game_id': gameId},
      );
      return _mapWeeklySeasonSummary(response);
    } catch (e) {
      debugPrint('🔴 Error fetching weekly season summary: $e');
      return null;
    }
  }

  Future<int?> getMyAllTimeRank(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc(
        'get_my_all_time_rank',
        params: {'p_game_id': gameId},
      );
      return _coerceNullableIntResponse(response);
    } catch (e) {
      debugPrint('🟡 Error fetching all-time rank, falling back: $e');
      return getMyRank(gameId);
    }
  }

  Future<int?> getMyAllTimeBestScore(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc(
        'get_my_all_time_best_score',
        params: {'p_game_id': gameId},
      );
      return _coerceNullableIntResponse(response);
    } catch (e) {
      debugPrint('🟡 Error fetching all-time best score, falling back: $e');
      return getMyBestScore(gameId);
    }
  }

  Future<List<Map<String, dynamic>>> getAllTimeLeaderboard(
    String gameId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_all_time_leaderboard',
        params: {
          'p_game_id': gameId,
          'p_limit': limit,
        },
      );
      return _mapLeaderboardRows(response);
    } catch (e) {
      debugPrint('🟡 Error fetching all-time leaderboard, falling back: $e');
      return getLeaderboard(gameId, limit: limit);
    }
  }

  Future<String?> updateNickname(String nickname) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return '로그인이 필요합니다.';

    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'nickname': nickname,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return '이미 사용 중인 닉네임입니다. \n다른 닉네임을 선택해주세요.';
      }
      return '닉네임 업데이트 중 오류가 발생했습니다: ${e.message}';
    } catch (_) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<bool> checkNicknameAvailable(String nickname) async {
    try {
      final response = await _supabase.rpc(
        'is_nickname_available',
        params: {'p_nickname': nickname},
      );

      if (response is bool) {
        return response;
      }

      return response?.toString() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return _supabase.from('profiles').select().eq('id', userId).maybeSingle();
  }

  Future<void> deleteMyHexorData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.rpc('delete_my_account_data');
  }

  Future<void> deleteMyAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.rpc('delete_my_account_completely');
  }
}
