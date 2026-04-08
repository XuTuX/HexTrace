part of 'package:hexor/services/auth_service.dart';

Future<void> _fetchUserProfile(AuthService service) async {
  service.isProfileLoaded.value = false;
  service.hasProfileLoadError.value = false;

  try {
    final currentUser = service._supabase.auth.currentUser;
    if (currentUser == null) {
      service.isProfileLoaded.value = true;
      return;
    }

    final dbService = Get.find<DatabaseService>();
    var profile = await dbService.getMyProfile();

    if (profile == null) {
      debugPrint('🟡 [AuthService] Profile not found, retrying in 500ms...');
      await Future.delayed(const Duration(milliseconds: 500));
      profile = await dbService.getMyProfile();
    }

    if (profile != null) {
      final nickname = profile['nickname'];
      if (nickname != null) {
        service.userNickname.value = nickname.toString();
        debugPrint(
            '🟢 [AuthService] Nickname fetched: ${service.userNickname.value}');
      } else {
        debugPrint('🟡 [AuthService] Nickname is null, generating new one...');
        await _generateAndSaveRandomNickname(service);
      }
    } else {
      debugPrint('🟡 [AuthService] Profile still null after retry');
      service.userNickname.value = null;
    }

    service.hasProfileLoadError.value = false;
    service.isProfileLoaded.value = true;
    debugPrint(
      '🔵 [AuthService] Profile load/check finished. Nickname: ${service.userNickname.value}',
    );
  } catch (e) {
    debugPrint('🔴 [AuthService] Failed to fetch profile: $e');
    service.hasProfileLoadError.value = true;
    service.isProfileLoaded.value = true;
  }
}

Future<void> _generateAndSaveRandomNickname(AuthService service) async {
  try {
    final dbService = Get.find<DatabaseService>();
    String candidate = '';
    bool available = false;
    int attempts = 0;

    while (attempts < 5 && !available) {
      candidate = RandomNicknameGenerator.generate();
      available = await dbService.checkNicknameAvailable(candidate);
      attempts++;
    }

    if (available) {
      final error = await service.updateNickname(candidate);
      if (error == null) {
        debugPrint('🟢 [AuthService] Auto-assigned nickname: $candidate');
      } else {
        debugPrint('🔴 [AuthService] Failed to save auto nickname: $error');
      }
    } else {
      debugPrint(
          '🔴 [AuthService] Failed to generate unique nickname after retries');
    }
  } catch (e) {
    debugPrint('🔴 [AuthService] Error in auto nickname generation: $e');
  }
}

Future<String?> _updateNickname(AuthService service, String newNickname) async {
  try {
    final dbService = Get.find<DatabaseService>();
    final error = await dbService.updateNickname(newNickname);
    if (error == null) {
      service.userNickname.value = newNickname;
    }
    return error;
  } catch (_) {
    return '업데이트 중 오류가 발생했습니다.';
  }
}
