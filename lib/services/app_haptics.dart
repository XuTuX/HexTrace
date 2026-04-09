import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'settings_service.dart';

class AppHaptics {
  static Future<void> selection() {
    return _trigger(HapticFeedback.selectionClick);
  }

  static Future<void> success() {
    return _trigger(HapticFeedback.mediumImpact);
  }

  static Future<void> warning() {
    return _trigger(HapticFeedback.heavyImpact);
  }

  static Future<void> gameOver() {
    return _trigger(HapticFeedback.vibrate);
  }

  static bool get _isEnabled {
    if (!Get.isRegistered<SettingsService>()) {
      return false;
    }

    return Get.find<SettingsService>().isHapticsOn.value;
  }

  static Future<void> _trigger(Future<void> Function() action) async {
    if (!_isEnabled) {
      return;
    }

    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Haptic feedback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
