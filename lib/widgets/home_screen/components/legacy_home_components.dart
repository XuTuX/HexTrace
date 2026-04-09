import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/services/auth_service.dart';

const double _borderWidth = 2.5;
const double _cardRadius = 20.0;
const Offset _shadowOffset = Offset(3, 3);

BoxDecoration _cardDecoration({
  Color fill = Colors.white,
  double radius = _cardRadius,
}) {
  return BoxDecoration(
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
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

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

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    required this.authService,
    required this.onProfileTap,
    required this.onLoginTap,
  });

  final AuthService authService;
  final VoidCallback onProfileTap;
  final VoidCallback onLoginTap;

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
            color: Colors.black,
            strokeWidth: 2,
          ),
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
