import 'dart:ui';

import 'package:linkagon/constant.dart';
import 'package:linkagon/config/app_config.dart';
import 'package:linkagon/screens/home_screen.dart';
import 'package:linkagon/services/auth_service.dart';
import 'package:linkagon/services/database_service.dart';
import 'package:linkagon/services/settings_service.dart';
import 'package:linkagon/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();
  final settingsService = await SettingsService().init();
  try {
    await dotenv.load(fileName: '.env');
    AppConfig.validateRequired();

    if (AppConfig.supportsAds) {
      await MobileAds.instance.initialize();
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    runApp(HoneyBooApp(settingsService: settingsService));
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize app: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      ConfigurationErrorApp(
        message: error is StateError ? error.message : error.toString(),
      ),
    );
  }
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 [FlutterError] ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('🔴 [PlatformDispatcher] $error');
    debugPrintStack(stackTrace: stackTrace);
    return true;
  };
}

class AppBinding extends Bindings {
  final SettingsService settingsService;

  AppBinding({required this.settingsService});

  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(DatabaseService(), permanent: true);
    if (AppConfig.supportsAds) {
      Get.put(AdService(), permanent: true);
    }
    Get.put<SettingsService>(settingsService, permanent: true);
  }
}

class HoneyBooApp extends StatelessWidget {
  final SettingsService settingsService;

  const HoneyBooApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      initialBinding: AppBinding(settingsService: settingsService),
      navigatorKey: Get.key, // GetX 글로벌 키 설정
      home: const HomeScreen(),
    );
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  final String message;

  const ConfigurationErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: charcoalBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: charcoalBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: charcoalBlack,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'APP CONFIGURATION NEEDED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Run the app with --dart-define values for Supabase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
