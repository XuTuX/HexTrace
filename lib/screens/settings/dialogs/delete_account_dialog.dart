import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/services/auth_service.dart';
import 'package:linkagon/theme/app_typography.dart';

void showDeleteAccountDialog(AuthService authService) {
  Get.dialog(
    Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: charcoalBlack, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[400],
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'NEOREO GAMES 계정을\n삭제할까요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'NEOREO GAMES와 관련된 계정인\nOverlap, Fill Your Area, Honey Boo 등의\n게임 데이터가 모두 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.grey[500],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: Get.back,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTypography.button.copyWith(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          final error = await authService.deleteAccount();
                          if (error != null) {
                            Get.snackbar(
                              '삭제 실패',
                              error,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                            );
                          } else {
                            Get.until((route) => route.isFirst);
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                Get.snackbar(
                                  '삭제 완료',
                                  'NEOREO GAMES 계정이 삭제되었습니다.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: charcoalBlack,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          '삭제',
                          style: AppTypography.button.copyWith(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
