part of 'package:linkagon/widgets/home_screen/login_sheet.dart';

class _LoginLegalLinks extends StatelessWidget {
  const _LoginLegalLinks({
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegalLink(
            label: '이용약관',
            onTap: onOpenTerms,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '·',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          _LegalLink(
            label: '개인정보 처리방침',
            onTap: onOpenPrivacy,
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.grey[400],
        ),
      ),
    );
  }
}
