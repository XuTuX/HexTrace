part of 'package:hexor/widgets/dialogs/tutorial_dialog.dart';

class _TutorialStepPage extends StatelessWidget {
  const _TutorialStepPage({
    required this.step,
    required this.index,
  });

  final _TutorialStepData step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accentColor = regionColors[index % regionColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Text(
              'STEP ${index + 1}',
              style: AppTypography.label.copyWith(
                fontSize: 12,
                color: charcoalBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.title,
            style: AppTypography.title.copyWith(fontSize: 24, height: 1.2),
          ),
          const SizedBox(height: 20),
          Text(
            step.description,
            style: AppTypography.body.copyWith(
              color: charcoalBlack87,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
