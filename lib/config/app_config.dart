import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String termsOfServiceUrl = 'https://www.neoreo.org/terms';
  static const String privacyPolicyUrl =
      'https://www.neoreo.org/privacy-policy';

  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get supportsAds => isAndroid || isIos;

  static void validateRequired() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required --dart-define values: ${missing.join(', ')}',
      );
    }
  }
}
