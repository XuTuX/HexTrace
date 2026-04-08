part of 'package:hexor/services/auth_service.dart';

void _bindAuthStateChanges(AuthService service) {
  service._supabase.auth.onAuthStateChange.listen((data) {
    service.user.value = data.session?.user;

    if (data.event == AuthChangeEvent.tokenRefreshed) {
      debugPrint('🔵 [AuthService] Token refreshed successfully');
    }

    if (service.user.value != null) {
      service.fetchUserProfile();
    } else {
      _resetProfileState(service);
    }
  });
}

void _resetProfileState(AuthService service) {
  service.userNickname.value = null;
  service.hasProfileLoadError.value = false;
  service.isProfileLoaded.value = true;
}

Future<void> _tryRecoverSession(AuthService service) async {
  try {
    final session = service._supabase.auth.currentSession;
    if (session == null) {
      return;
    }

    if (session.isExpired) {
      debugPrint('🟡 [AuthService] Session expired, attempting refresh...');
      try {
        await service._supabase.auth.refreshSession();
        debugPrint('🟢 [AuthService] Session refreshed successfully');
      } catch (e) {
        debugPrint('🔴 [AuthService] Session refresh failed, signing out: $e');
        await service._supabase.auth.signOut();
        service.user.value = null;
      }
    } else {
      debugPrint('🟢 [AuthService] Valid session found on startup');
    }

    if (service.user.value != null) {
      await service.fetchUserProfile();
    }
  } catch (e) {
    debugPrint('🔴 [AuthService] Session recovery error: $e');
  }
}
