part of 'package:linkagon/widgets/dialogs/tutorial_dialog.dart';

class _TutorialDialogView extends StatelessWidget {
  const _TutorialDialogView({
    required this.pageController,
    required this.currentPage,
    required this.steps,
    required this.onClose,
    required this.onNext,
    required this.onBack,
    required this.onPageChanged,
  });

  final PageController pageController;
  final int currentPage;
  final List<_TutorialStepData> steps;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: charcoalBlack, width: 3),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(8, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TutorialHeader(onClose: onClose),
            Flexible(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return _TutorialStepPage(
                    step: steps[index],
                    index: index,
                  );
                },
              ),
            ),
            _TutorialFooter(
              currentPage: currentPage,
              totalPages: steps.length,
              onBack: onBack,
              onNext: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialHeader extends StatelessWidget {
  const _TutorialHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '게임 방법',
            style: AppTypography.label.copyWith(
              fontSize: 14,
              letterSpacing: 2.0,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: charcoalBlack, width: 2),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: charcoalBlack,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
