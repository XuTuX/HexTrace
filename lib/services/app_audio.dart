import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'dart:math';

import 'settings_service.dart';

class AppAudio {
  static final AudioPlayer _player = AudioPlayer();
  
  static bool get _isEnabled {
    if (!Get.isRegistered<SettingsService>()) {
      return false;
    }
    return Get.find<SettingsService>().isSoundOn.value;
  }

  static Future<void> playMatch(int combo) async {
    if (!_isEnabled) return;

    try {
      // Base pitch is 1.0. Increases by 0.05 per combo, max 2.0.
      final pitch = min(2.0, 1.0 + (combo - 1) * 0.05);
      await _player.setPlaybackRate(pitch);
      
      // We use a short chime sound. 
      // Note: The user needs to ensure this file exists in assets/sounds/chime.mp3
      await _player.play(AssetSource('sounds/chime.mp3'));
    } catch (e) {
      // Silently fail if audio play fails
    }
  }
}
