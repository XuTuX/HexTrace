import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hexor/config/app_config.dart';
import 'package:hexor/theme/app_typography.dart';

part 'login/login_sheet_view.dart';
part 'login/login_sheet_legal.dart';
part 'login/login_sheet_social.dart';

class LoginSheet extends StatefulWidget {
  const LoginSheet({
    super.key,
    this.isRankingAction = false,
    this.initialError,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.onLoginSuccess,
  });

  final bool isRankingAction;
  final String? initialError;
  final Future<String?> Function() onGoogleSignIn;
  final Future<String?> Function() onAppleSignIn;
  final VoidCallback? onLoginSuccess;

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  Future<void> _handleSignIn(Future<String?> Function() signInMethod) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await signInMethod();

      if (!mounted) {
        return;
      }

      if (error == null) {
        Get.back();
        widget.onLoginSuccess?.call();
        return;
      }

      if (error == 'cancelled') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인에 실패했어요. 다시 시도해 주세요.';
        });
      }
      debugPrint('🔴 Sign-in error: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('🔴 Could not open URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LoginSheetView(
      title: widget.isRankingAction ? '랭킹 참여' : '로그인',
      description: widget.isRankingAction
          ? '로그인하면 랭킹에 참여할 수 있어요'
          : '로그인하면 기록 저장과 랭킹에\n참여할 수 있어요',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      showAppleButton: GetPlatform.isIOS,
      onGoogleTap: () => _handleSignIn(widget.onGoogleSignIn),
      onAppleTap: () => _handleSignIn(widget.onAppleSignIn),
      onOpenTerms: () => _openUrl(AppConfig.termsOfServiceUrl),
      onOpenPrivacy: () => _openUrl(AppConfig.privacyPolicyUrl),
    );
  }
}
