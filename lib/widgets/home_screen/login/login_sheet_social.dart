part of 'package:hexor/widgets/home_screen/login_sheet.dart';

class _SocialSignInRow extends StatelessWidget {
  const _SocialSignInRow({
    required this.isLoading,
    required this.showAppleButton,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  final bool isLoading;
  final bool showAppleButton;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleSignInButton(
                  isLoading: isLoading,
                  onTap: onGoogleTap,
                ),
                if (showAppleButton) ...[
                  const SizedBox(width: 20),
                  _AppleSignInButton(
                    isLoading: isLoading,
                    onTap: onAppleTap,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
        if (isLoading)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SocialCircleButton(
      isLoading: isLoading,
      onTap: onTap,
      backgroundColor: Colors.white,
      border: Border.all(
        color: const Color(0xFFDADCE0),
        width: 1,
      ),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset(
          'assets/icons/google_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SocialCircleButton(
      isLoading: isLoading,
      onTap: onTap,
      backgroundColor: const Color(0xFF1A1A1A),
      child: const Icon(
        Icons.apple,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    required this.isLoading,
    required this.onTap,
    required this.backgroundColor,
    required this.child,
    this.border,
  });

  final bool isLoading;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Widget child;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isLoading ? 0.3 : 1.0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
