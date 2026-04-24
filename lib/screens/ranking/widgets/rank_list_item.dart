import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

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

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFB7185), // Coral Red
      2 => const Color(0xFFFB923C), // Orange
      3 => const Color(0xFFFBBF24), // Amber Yellow
      _ => charcoalBlack.withValues(alpha: 0.25),
    };

    Color itemBgColor = const Color(0xFFF8FAFC);
    Color borderColor = charcoalBlack.withValues(alpha: 0.08);

    if (isMe) {
      itemBgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF2563EB).withValues(alpha: 0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
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
                      color: const Color(0xFF2563EB),
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatScore(scoreVal),
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
