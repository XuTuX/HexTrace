import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: charcoalBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: charcoalBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: charcoalBlack,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'SETTINGS',
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                fontSize: 22,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
