import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/database_service.dart';

class WeeklyRankingPreview extends StatefulWidget {
  const WeeklyRankingPreview({
    super.key,
    required this.onViewAll,
    this.isAllTime = false,
  });

  final VoidCallback onViewAll;
  final bool isAllTime;

  @override
  State<WeeklyRankingPreview> createState() => _WeeklyRankingPreviewState();
}

class _WeeklyRankingPreviewState extends State<WeeklyRankingPreview> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _topScores = [];

  @override
  void initState() {
    super.initState();
    _loadTopScores();
  }

  Future<void> _loadTopScores() async {
    try {
      final dbService = Get.find<DatabaseService>();
      final scores = await (widget.isAllTime
              ? dbService.getAllTimeLeaderboard(gameId, limit: 5)
              : dbService.getWeeklyLeaderboard(gameId, limit: 5))
          .catchError((e) {
        debugPrint('🔴 [WeeklyRankingPreview] Error: $e');
        return <Map<String, dynamic>>[];
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _topScores = List<Map<String, dynamic>>.from(scores.take(5));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: widget.onViewAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  '랭킹',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 16,
                    color: charcoalBlack,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  '전체 보기',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: charcoalBlack.withValues(alpha: 0.32),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: charcoalBlack.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Content
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: charcoalBlack.withValues(alpha: 0.2),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_topScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '아직 기록이 없습니다',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: charcoalBlack.withValues(alpha: 0.18),
                ),
              ),
            )
          else
            ...List.generate(_topScores.length, (index) {
              return _CleanRankRow(
                rank: index + 1,
                data: _topScores[index],
                isLast: index == _topScores.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _CleanRankRow extends StatelessWidget {
  const _CleanRankRow({
    required this.rank,
    required this.data,
    this.isLast = false,
  });

  final int rank;
  final Map<String, dynamic> data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final profileData = data['profiles'];
    Map<String, dynamic> profiles = {};
    if (profileData is Map<String, dynamic>) {
      profiles = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      profiles = profileData[0] as Map<String, dynamic>;
    }

    final nickname = profiles['nickname'] ?? 'Player';
    final score = data['score'] ?? 0;

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFB7185), // Coral Red
      2 => const Color(0xFFFB923C), // Orange
      3 => const Color(0xFFFBBF24), // Amber Yellow
      _ => charcoalBlack.withValues(alpha: 0.2),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: GoogleFonts.blackHanSans(
                fontSize: 16,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nickname.toString(),
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: charcoalBlack.withValues(alpha: 0.65),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatScore(score),
            style: GoogleFonts.blackHanSans(
              fontSize: 14,
              color: charcoalBlack.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(dynamic score) {
    final value = score is int ? score : int.tryParse(score.toString()) ?? 0;
    if (value < 1000) {
      return value.toString();
    }

    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}
