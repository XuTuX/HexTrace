part of 'package:linkagon/services/auth_service.dart';

Future<String?> _signInWithGoogle(AuthService service) async {
  try {
    service.isLoading.value = true;
    debugPrint('🔵 [AuthService] Google Sign In process started');

    final googleSignIn = GoogleSignIn();
    debugPrint('🔵 [AuthService] Requesting Google Sign In...');
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      debugPrint('🟡 [AuthService] User cancelled Google Sign In');
      return 'cancelled';
    }

    debugPrint('🔵 [AuthService] Getting authentication tokens...');
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    debugPrint('🔵 [AuthService] Signing in to Supabase...');
    await service._supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    debugPrint('🟢 [AuthService] Google Sign In Success!');
    _triggerLoginSuccess(service);
    await service.fetchUserProfile();
    return null;
  } catch (e) {
    debugPrint('🔴 [AuthService] Google Sign In Failed: $e');
    return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
  } finally {
    service.isLoading.value = false;
    debugPrint(
        '🔵 [AuthService] Login process finished. isLoading set to false.');
  }
}

Future<String?> _signInWithApple(AuthService service) async {
  try {
    service.isLoading.value = true;
    debugPrint('🔵 [AuthService] Apple Sign In process started');

    final rawNonce = service._supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    debugPrint('🔵 [AuthService] Requesting Apple ID Credential...');
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw 'Could not find ID Token from Apple.';
    }

    debugPrint('🔵 [AuthService] Signing in to Supabase...');
    await service._supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    debugPrint('🟢 [AuthService] Apple Sign In Success!');
    _triggerLoginSuccess(service);
    await service.fetchUserProfile();
    return null;
  } catch (e) {
    debugPrint('🔴 [AuthService] Apple Sign In Failed: $e');
    return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
  } finally {
    service.isLoading.value = false;
    debugPrint(
        '🔵 [AuthService] Login process finished. isLoading set to false.');
  }
}

void _triggerLoginSuccess(AuthService service) {
  service.loginSuccess.value = true;
  Future.delayed(const Duration(seconds: 1), () {
    service.loginSuccess.value = false;
  });
}
