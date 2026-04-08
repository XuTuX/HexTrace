import 'dart:math';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexor/widgets/home_screen/nickname_sticker_card.dart';

// ──────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS (shared across all home screen widgets)
// ──────────────────────────────────────────────────────────────────────

const double _borderWidth = 2.5;
const double _cardRadius = 20.0;
const Offset _shadowOffset = Offset(3, 3);

BoxDecoration _cardDecoration({
  Color fill = Colors.white,
  double radius = _cardRadius,
}) =>
    BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: charcoalBlack, width: _borderWidth),
      boxShadow: const [
        BoxShadow(
          color: charcoalBlack,
          offset: _shadowOffset,
          blurRadius: 0,
        ),
      ],
    );

// ──────────────────────────────────────────────────────────────────────
//  TOP ICON BUTTON (settings gear, etc.)
// ──────────────────────────────────────────────────────────────────────

class TopIconButton extends StatelessWidget {
  const TopIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: charcoalBlack.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: charcoalBlack.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  1. LOGO (HEX TRACE text)
// ──────────────────────────────────────────────────────────────────────

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Small hex decoration row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniHex(color: GamePalette.colorFor(GameColor.coral)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.azure)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.mint)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.amber)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.violet)),
          ],
        ),
        const SizedBox(height: 14),
        // Title
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'HEX',
              style: GoogleFonts.blackHanSans(
                fontSize: 48,
                color: charcoalBlack,
                height: 1.0,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TRACE',
              style: GoogleFonts.blackHanSans(
                fontSize: 48,
                color: const Color(0xFF0095FF),
                height: 1.0,
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniHex extends StatelessWidget {
  const _MiniHex({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _HexPainter(color)),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  HEX PAINTER (shared)
// ──────────────────────────────────────────────────────────────────────

class _HexPainter extends CustomPainter {
  _HexPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = charcoalBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _hexPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────────────
//  2. SCORE DISPLAY (centered, clean)
// ──────────────────────────────────────────────────────────────────────

class ScoreDisplay extends StatelessWidget {
  final ScoreController scoreController;
  final AuthService authService;

  const ScoreDisplay({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading =
          authService.isLoading.value || scoreController.isSyncing.value;

      return NicknameStickerCard(
        nickname: authService.userNickname.value,
        score: scoreController.highscore.value,
        isLoading: isLoading,
      );
    });
  }
}

// ──────────────────────────────────────────────────────────────────────
//  3. PRIMARY ACTION BUTTONS
// ──────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0095FF),
          foregroundColor: Colors.white,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: _borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 26, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: GoogleFonts.blackHanSans(
                fontSize: 22,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RankingButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: charcoalBlack,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: _borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              '랭킹',
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: charcoalBlack.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  4. WEEKLY RANKING PREVIEW (compact)
// ──────────────────────────────────────────────────────────────────────

class WeeklyRankingPreview extends StatefulWidget {
  final VoidCallback onViewAll;

  const WeeklyRankingPreview({
    super.key,
    required this.onViewAll,
  });

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
      final scores = await dbService.getLeaderboard(gameId).catchError((e) {
        debugPrint('🔴 [WeeklyRankingPreview] Error: $e');
        return <Map<String, dynamic>>[];
      });
      if (!mounted) return;
      setState(() {
        _topScores = List<Map<String, dynamic>>.from(scores.take(3));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  '주간 랭킹',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 14,
                    color: charcoalBlack,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '전체 보기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: charcoalBlack.withValues(alpha: 0.4),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: charcoalBlack.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: charcoalBlack.withValues(alpha: 0.2),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_topScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'NO DATA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: charcoalBlack.withValues(alpha: 0.15),
                  letterSpacing: 1.5,
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(
                color: charcoalBlack.withValues(alpha: 0.06),
                height: 16,
              ),
            ),
            ...List.generate(_topScores.length, (i) {
              return _RankRow(
                rank: i + 1,
                data: _topScores[i],
                isLast: i == _topScores.length - 1,
              );
            }),
          ],

          const SizedBox(height: 6),
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

    final Color rankBg;
    final Color rankFg;
    switch (rank) {
      case 1:
        rankBg = const Color(0xFFFFB300);
        rankFg = Colors.white;
        break;
      case 2:
        rankBg = const Color(0xFFB0BEC5);
        rankFg = Colors.white;
        break;
      case 3:
        rankBg = const Color(0xFFBF8040);
        rankFg = Colors.white;
        break;
      default:
        rankBg = charcoalBlack.withValues(alpha: 0.08);
        rankFg = charcoalBlack;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rankBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: rankFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              nickname.toString(),
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: charcoalBlack.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Score
          Text(
            _formatScore(score),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: charcoalBlack.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(dynamic score) {
    final n = score is int ? score : int.tryParse(score.toString()) ?? 0;
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return n.toString();
  }
}

// ──────────────────────────────────────────────────────────────────────
//  LEGACY WIDGETS (kept for backward compatibility)
// ──────────────────────────────────────────────────────────────────────

class SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SettingsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: _cardDecoration(radius: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_rounded,
              color: charcoalBlack.withValues(alpha: 0.65),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '설정',
              style: GoogleFonts.blackHanSans(
                fontSize: 15,
                color: charcoalBlack.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameplayTip extends StatelessWidget {
  const GameplayTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '게임 방법',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: charcoalBlack.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '같은 색 육각형을 연결하여\n선을 만들면 사용한 구간이 사라집니다.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: charcoalBlack.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: charcoalBlack,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: _borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  PROFILE BUTTON (reused from original — settings circle)
// ──────────────────────────────────────────────────────────────────────

class ProfileButton extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onProfileTap;
  final VoidCallback onLoginTap;

  const ProfileButton({
    super.key,
    required this.authService,
    required this.onProfileTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (authService.isLoading.value) {
        return Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const CircularProgressIndicator(
              color: Colors.black, strokeWidth: 2),
        );
      }

      if (authService.loginSuccess.value) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.5 + (value * 0.5),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        );
      }

      return GestureDetector(
        onTap: onProfileTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.black,
          ),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────────────────
//  LOGIN BUTTON (reused from original)
// ──────────────────────────────────────────────────────────────────────

class LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          side: BorderSide(color: borderColor, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  HIGH SCORE CARD (legacy — kept for backwards compat if needed)
// ──────────────────────────────────────────────────────────────────────

class HighScoreCard extends StatelessWidget {
  final ScoreController scoreController;
  final AuthService authService;

  const HighScoreCard({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreDisplay(
      scoreController: scoreController,
      authService: authService,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  INFO CARDS ROW (legacy — kept for backwards compat)
// ──────────────────────────────────────────────────────────────────────

class InfoCardsRow extends StatelessWidget {
  final ScoreController scoreController;
  final AuthService authService;

  const InfoCardsRow({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreDisplay(
      scoreController: scoreController,
      authService: authService,
    );
  }
}

class ColorBarPreview extends StatelessWidget {
  const ColorBarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
