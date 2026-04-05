import 'package:hexor/constant.dart';
import 'package:hexor/screens/home_screen.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/services/settings_service.dart';
import 'package:hexor/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final settingsService = await SettingsService().init();

  runApp(RuneBloomApp(settingsService: settingsService));
}

class AppBinding extends Bindings {
  final SettingsService settingsService;

  AppBinding({required this.settingsService});

  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(DatabaseService(), permanent: true);
    Get.put(AdService(), permanent: true);
    Get.put<SettingsService>(settingsService, permanent: true);
  }
}

class RuneBloomApp extends StatelessWidget {
  final SettingsService settingsService;

  const RuneBloomApp({super.key, required this.settingsService});

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
