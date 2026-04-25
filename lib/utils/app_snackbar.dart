import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar({
  required String message,
  String? title,
  Color backgroundColor = const Color(0xFF2D2D2D),
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) {
    debugPrint('SnackBar skipped because ScaffoldMessenger is not ready.');
    return;
  }

  final snackText =
      title == null || title.trim().isEmpty ? message : '$title\n$message';
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          snackText,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

void clearAppSnackBars() {
  appScaffoldMessengerKey.currentState?.clearSnackBars();
}
