import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  final RxBool isHapticsOn = true.obs;
  final RxBool isSoundOn = true.obs;

  static const String _hapticsKey = 'haptics_enabled';
  static const String _soundKey = 'sound_enabled';

  Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isHapticsOn.value = prefs.getBool(_hapticsKey) ?? true;
    isSoundOn.value = prefs.getBool(_soundKey) ?? true;
    return this;
  }

  Future<void> toggleHaptics() async {
    isHapticsOn.value = !isHapticsOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, isHapticsOn.value);
  }

  Future<void> toggleSound() async {
    isSoundOn.value = !isSoundOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, isSoundOn.value);
  }
}
