import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';

class SettingsService extends GetxService {
  final RxBool isHapticsOn = true.obs;
  final RxBool isBgmOn = true.obs;
  final RxBool isSfxOn = true.obs;

  static const String _hapticsKey = 'haptics_enabled';
  static const String _bgmKey = 'bgm_enabled';
  static const String _sfxKey = 'sfx_enabled';

  Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isHapticsOn.value = prefs.getBool(_hapticsKey) ?? true;
    isBgmOn.value = prefs.getBool(_bgmKey) ?? true;
    isSfxOn.value = prefs.getBool(_sfxKey) ?? true;
    return this;
  }

  Future<void> toggleHaptics() async {
    isHapticsOn.value = !isHapticsOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, isHapticsOn.value);
  }

  Future<void> toggleBgm() async {
    isBgmOn.value = !isBgmOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmKey, isBgmOn.value);
    await AudioService().setBgmEnabled(isBgmOn.value);
  }

  Future<void> toggleSfx() async {
    isSfxOn.value = !isSfxOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, isSfxOn.value);
    await AudioService().setSfxEnabled(isSfxOn.value);
  }
}
