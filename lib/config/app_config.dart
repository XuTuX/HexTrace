import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// dart-define 값이 있으면 우선 사용, 없으면 .env 파일에서 읽기
  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty
          ? const String.fromEnvironment('SUPABASE_URL')
          : (dotenv.env['SUPABASE_URL'] ?? '');

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
          ? const String.fromEnvironment('SUPABASE_ANON_KEY')
          : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

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
        'Missing required values: ${missing.join(', ')}. '
        'Make sure .env file exists with SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }
}
