part of 'package:linkagon/widgets/dialogs/tutorial_dialog.dart';

class _TutorialFooter extends StatelessWidget {
  const _TutorialFooter({
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          _TutorialIndicators(
            currentPage: currentPage,
            totalPages: totalPages,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (currentPage > 0) ...[
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 56,
                    child: TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: charcoalBlack.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style:
                            AppTypography.button.copyWith(color: charcoalBlack),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: charcoalBlack,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      currentPage == totalPages - 1 ? 'Start' : 'Next',
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TutorialIndicators extends StatelessWidget {
  const _TutorialIndicators({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.only(right: 6),
          width: currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? charcoalBlack
                : charcoalBlack.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
