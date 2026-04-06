import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class DatabaseService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  // 특정 게임의 내 최고 점수 가져오기
  Future<int?> getMyBestScore(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase.rpc(
      'get_my_best_score',
      params: {'p_game_id': gameId},
    );

    return _coerceInt(response);
  }

  // 점수 저장 (최고 점수 갱신 로직)
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

  // 나의 순위 가져오기
  Future<int?> getMyRank(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase.rpc(
      'get_my_rank',
      params: {'p_game_id': gameId},
    );

    if (response == null) {
      return null;
    }

    if (response is int) {
      return response;
    }

    return _coerceInt(response);
  }

  // 리더보드 가져오기 (클라이언트 사이드 중복 제거 포함)
  Future<List<Map<String, dynamic>>> getLeaderboard(String gameId) async {
    try {
      final response = await _supabase.rpc(
        'get_leaderboard',
        params: {
          'p_game_id': gameId,
          'p_limit': 50,
        },
      );

      final rows = List<Map<String, dynamic>>.from(response as List);
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
    } catch (e) {
      debugPrint('🔴 Error fetching leaderboard: $e');
      return [];
    }
  }

  // 닉네임 설정/업데이트
  Future<String?> updateNickname(String nickname) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return '로그인이 필요합니다.';

    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'nickname': nickname,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return null; // Success
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return '이미 사용 중인 닉네임입니다. \n다른 닉네임을 선택해주세요.';
      }
      return '닉네임 업데이트 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// Check if a nickname is available (not taken by another user)
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
    } catch (e) {
      return false;
    }
  }

  // 내 프로필 가져오기
  Future<Map<String, dynamic>?> getMyProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // Hexor 게임 데이터 삭제
  Future<void> deleteMyData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.rpc('delete_my_account_data');
  }
}
