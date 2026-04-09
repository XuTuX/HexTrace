part of 'package:linkagon/services/auth_service.dart';

void _bindAuthStateChanges(AuthService service) {
  service._authStateSubscription?.cancel();
  service._authStateSubscription =
      service._supabase.auth.onAuthStateChange.listen(
    (data) {
      service.user.value = data.session?.user;
      service._invalidateProfileLoadRequests();

      if (data.event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔵 [AuthService] Token refreshed successfully');
      }

      if (service.user.value != null) {
        unawaited(service.fetchUserProfile());
      } else {
        _resetProfileState(service);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      debugPrint('🔴 [AuthService] Auth state listener error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
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
      service._invalidateProfileLoadRequests();
      return;
    }

    if (session.isExpired) {
      debugPrint('🟡 [AuthService] Session expired, attempting refresh...');
      try {
        await service._supabase.auth.refreshSession();
        debugPrint('🟢 [AuthService] Session refreshed successfully');
      } catch (e) {
        debugPrint('🔴 [AuthService] Session refresh failed, signing out: $e');
        service._invalidateProfileLoadRequests();
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
