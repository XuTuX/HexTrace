import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:linkagon/services/database_service.dart';
import 'package:linkagon/utils/random_nickname_generator.dart';

part 'auth/auth_account.dart';
part 'auth/auth_profile.dart';
part 'auth/auth_session.dart';
part 'auth/auth_sign_in.dart';

class AuthService extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final user = Rxn<User>();
  final isLoading = false.obs;
  final loginSuccess = false.obs;
  final userNickname = RxnString();
  final isProfileLoaded = false.obs;
  final hasProfileLoadError = false.obs;
  StreamSubscription<AuthState>? _authStateSubscription;
  int _profileLoadRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    user.value = _supabase.auth.currentUser;
    isProfileLoaded.value = user.value == null;
    hasProfileLoadError.value = false;

    _bindAuthStateChanges(this);
    _tryRecoverSession(this);
  }

  Future<void> fetchUserProfile() => _fetchUserProfile(this);

  Future<String?> updateNickname(String newNickname) =>
      _updateNickname(this, newNickname);

  Future<String?> signInWithGoogle() => _signInWithGoogle(this);

  Future<String?> signInWithApple() => _signInWithApple(this);

  Future<void> signOut() => _signOut(this);

  Future<String?> deleteBeeHouseData() => _deleteBeeHouseData(this);

  Future<String?> deleteAccount() => _deleteAccount(this);

  int _beginProfileLoadRequest() => ++_profileLoadRequestId;

  void _invalidateProfileLoadRequests() {
    _profileLoadRequestId++;
  }

  bool _canApplyProfileLoad({
    required int requestId,
    required String userId,
  }) {
    return !isClosed &&
        requestId == _profileLoadRequestId &&
        _supabase.auth.currentUser?.id == userId &&
        user.value?.id == userId;
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }
}
