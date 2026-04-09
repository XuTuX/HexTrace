part of 'package:linkagon/services/auth_service.dart';

Future<void> _signOut(AuthService service) async {
  service._invalidateProfileLoadRequests();
  await _signOutSocialProviders(service);
  await service._supabase.auth.signOut();
  _resetProfileState(service);
}

Future<String?> _deleteLinkagonData(AuthService service) async {
  try {
    service.isLoading.value = true;
    debugPrint('🔵 [AuthService] Linkagon data deletion started');
    final deletingUserId = service._supabase.auth.currentUser?.id;

    try {
      final dbService = Get.find<DatabaseService>();
      await dbService.deleteMyLinkagonData();
      debugPrint('🟢 [AuthService] User data deleted from DB');
    } catch (e) {
      debugPrint('🔴 [AuthService] DB data deletion failed: $e');
      return 'Linkagon 기록 삭제 중 오류가 발생했습니다. 다시 시도해주세요.';
    }

    if (deletingUserId != null) {
      await _clearLocalUserCache(deletingUserId);
    }

    await _signOutSocialProviders(service);
    await service._supabase.auth.signOut();
    service.user.value = null;
    service.userNickname.value = null;

    debugPrint('🟢 [AuthService] Linkagon data deletion completed');
    return null;
  } catch (e) {
    debugPrint('🔴 [AuthService] Linkagon data deletion failed: $e');
    return 'Linkagon 기록 삭제 중 오류가 발생했습니다. 다시 시도해주세요.';
  } finally {
    if (!service.isClosed) {
      service.isLoading.value = false;
    }
  }
}

Future<String?> _deleteAccount(AuthService service) async {
  service.isLoading.value = true;
  service._invalidateProfileLoadRequests();

  try {
    debugPrint('🔵 [AuthService] NEOREO GAMES account deletion started');
    final deletingUserId = service._supabase.auth.currentUser?.id;

    try {
      final dbService = Get.find<DatabaseService>();
      await dbService.deleteMyAccount();
      debugPrint('🟢 [AuthService] Account completely deleted from server');
    } catch (e) {
      debugPrint('🔴 [AuthService] Account deletion failed: $e');
      return '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.';
    }

    if (deletingUserId != null) {
      try {
        await _clearLocalUserCache(deletingUserId);
      } catch (e, stackTrace) {
        debugPrint('🟡 [AuthService] Local cache clear failed: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    try {
      await _signOutSocialProviders(service);
    } catch (e, stackTrace) {
      debugPrint('🟡 [AuthService] Not crucial if social sign out fails: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await service._supabase.auth.signOut(scope: SignOutScope.local);
      debugPrint('🟢 [AuthService] Local sign out successful');
    } catch (e, stackTrace) {
      debugPrint('🟡 [AuthService] Local sign out failed, ignoring: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    service.user.value = null;
    _resetProfileState(service);
    service._invalidateProfileLoadRequests();

    debugPrint('🟢 [AuthService] NEOREO GAMES account deletion completed');
    return null;
  } catch (e, stackTrace) {
    debugPrint('🔴 [AuthService] Account deletion failed: $e');
    debugPrintStack(stackTrace: stackTrace);
    return '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.';
  } finally {
    if (!service.isClosed) {
      service.isLoading.value = false;
    }
  }
}

Future<void> _clearLocalUserCache(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('high_score_$userId');
    await prefs.remove('guest_merged_$userId');
  } catch (_) {}
}

Future<void> _signOutSocialProviders(AuthService service) async {
  final provider = _currentAuthProvider(service);
  if (provider != 'google') {
    debugPrint(
      '🔵 [AuthService] Social sign out skipped. Current provider: ${provider ?? 'unknown'}',
    );
    return;
  }

  try {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut().timeout(const Duration(seconds: 2));
  } catch (_) {
    debugPrint('🟡 [AuthService] Social sign out timeout or error ignored.');
  }
}

String? _currentAuthProvider(AuthService service) {
  final currentUser = service._supabase.auth.currentUser;
  final provider = currentUser?.appMetadata['provider'];
  return provider is String ? provider : null;
}
