import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar({
  required String message,
  String? title,
  Color backgroundColor = Colors.black87,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) {
    debugPrint('SnackBar skipped because ScaffoldMessenger is not ready.');
    return;
  }

  final text =
      title == null || title.trim().isEmpty ? message : '$title\n$message';
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text,
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
