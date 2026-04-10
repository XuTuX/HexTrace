import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/theme/app_typography.dart';
import 'package:linkagon/game/game_palette.dart';
import 'package:linkagon/game/hex_game_controller.dart';

class RankListItem extends StatelessWidget {
  const RankListItem({
    super.key,
    required this.scoreData,
    required this.index,
    required this.myId,
  });

  final Map<String, dynamic> scoreData;
  final int index;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final profileData = scoreData['profiles'];
    Map<String, dynamic> profiles = {};
    if (profileData is Map<String, dynamic>) {
      profiles = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      profiles = profileData[0] as Map<String, dynamic>;
    }

    final nickname = profiles['nickname'] ?? 'Player';
    final scoreVal = scoreData['score'];
    final userId = scoreData['user_id'];
    final isMe = userId != null && userId == myId;
    final rankValue = scoreData['rank'];
    final rank = switch (rankValue) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? (index + 1),
      _ => index + 1,
    };
    final isTopThree = rank <= 3;

    Color itemBgColor = Colors.white;
    Color borderColor = charcoalBlack.withValues(alpha: 0.08);
    double borderWith = 1.0;
    
    if (isTopThree) {
      itemBgColor = switch (rank) {
        1 => GamePalette.colorFor(GameColor.amber).withValues(alpha: 0.1),
        2 => charcoalBlack.withValues(alpha: 0.04),
        3 => GamePalette.colorFor(GameColor.coral).withValues(alpha: 0.08),
        _ => Colors.white,
      };
      borderColor = charcoalBlack;
      borderWith = 2.0;
    }

    if (isMe && !isTopThree) {
      itemBgColor = GamePalette.colorFor(GameColor.azure).withValues(alpha: 0.05);
      borderColor = GamePalette.colorFor(GameColor.azure).withValues(alpha: 0.3);
      borderWith = 1.5;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: borderWith,
        ),
        boxShadow: isTopThree ? [
          const BoxShadow(
            color: charcoalBlack,
            offset: Offset(0, 3),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$rank',
                  style: GoogleFonts.blackHanSans(
                    fontSize: isTopThree ? 22 : 18,
                    color: isTopThree ? charcoalBlack : charcoalBlack.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '위',
                  style: AppTypography.body.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: charcoalBlack.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: GoogleFonts.notoSans(
                    fontSize: isTopThree ? 15 : 14,
                    fontWeight: isMe || isTopThree
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: charcoalBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isMe) 
                  Text(
                    'YOU',
                    style: AppTypography.label.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: GamePalette.colorFor(GameColor.azure),
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$scoreVal',
                style: GoogleFonts.blackHanSans(
                  fontSize: isTopThree ? 20 : 16,
                  color: charcoalBlack,
                ),
              ),
              Text(
                'PTS',
                style: AppTypography.label.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: charcoalBlack.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
