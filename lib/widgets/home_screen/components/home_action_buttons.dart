import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';

const double _borderWidth = 2.5;

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Container(
      width: double.infinity,
      height: isTablet ? 88 : 80,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(5, 5),
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
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isTablet ? 32 : 30, color: Colors.white),
              SizedBox(width: isTablet ? 14 : 12),
            ],
            Text(
              label,
              style: GoogleFonts.blackHanSans(
                fontSize: isTablet ? 28 : 25,
                letterSpacing: 1.2,
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
  const RankingButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

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

class RankingCard extends StatelessWidget {
  const RankingCard({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: charcoalBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '랭킹',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 16,
                    color: charcoalBlack,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: charcoalBlack.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

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

class LoginButton extends StatelessWidget {
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

  final String label;
  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

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
