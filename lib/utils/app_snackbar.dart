import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexor/constant.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar({
  required String message,
  String? title,
  Color backgroundColor = charcoalBlack,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) {
    debugPrint('SnackBar skipped because ScaffoldMessenger is not ready.');
    return;
  }

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: charcoalBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title.trim().isNotEmpty) ...[
                Text(
                  title,
                  style: GoogleFonts.blackHanSans(
                    fontSize: 17,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
}
