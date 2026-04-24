import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/screens/ranking/weekly_reset_info.dart';
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
              ? dbService.getAllTimeLeaderboard(gameId, limit: 3)
              : dbService.getWeeklyLeaderboard(gameId, limit: 3))
          .catchError((e) {
        debugPrint('🔴 [WeeklyRankingPreview] Error: $e');
        return <Map<String, dynamic>>[];
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _topScores = List<Map<String, dynamic>>.from(scores.take(3));
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
    final weeklyResetInfo = WeeklyResetInfo.current();
    final title = widget.isAllTime ? '전체 랭킹 TOP3' : '주간 랭킹 TOP3';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            offset: Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GamePalette.colorFor(GameColor.amber)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: GamePalette.colorFor(GameColor.amber),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.blackHanSans(
                    fontSize: 17,
                    letterSpacing: 0,
                    color: charcoalBlack,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onViewAll,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '더 보기',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: charcoalBlack.withValues(alpha: 0.62),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: charcoalBlack.withValues(alpha: 0.48),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: charcoalBlack,
                  strokeWidth: 3,
                ),
              ),
            )
          else if (_topScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'NO DATA',
                style: GoogleFonts.blackHanSans(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.1),
                  letterSpacing: 2.0,
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: List.generate(_topScores.length, (index) {
                  return _RankRow(
                    rank: index + 1,
                    data: _topScores[index],
                    isLast: index == _topScores.length - 1,
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.isAllTime)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                '누적 최고 기록 기준',
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: charcoalBlack.withValues(alpha: 0.3),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: charcoalBlack38),
                  const SizedBox(width: 4),
                  Text(
                    weeklyResetInfo.koreanLabel,
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: charcoalBlack.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
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
      1 => GamePalette.colorFor(GameColor.amber),
      2 => charcoalBlack.withValues(alpha: 0.4),
      3 => GamePalette.colorFor(GameColor.coral),
      _ => charcoalBlack.withValues(alpha: 0.2),
    };

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nickname.toString(),
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: charcoalBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatScore(score),
            style: GoogleFonts.blackHanSans(
              fontSize: 15,
              color: charcoalBlack.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'P',
            style: GoogleFonts.notoSans(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: charcoalBlack.withValues(alpha: 0.2),
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
