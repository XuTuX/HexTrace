part of 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';

class _EditNicknameDialogView extends StatelessWidget {
  const _EditNicknameDialogView({
    required this.title,
    required this.controller,
    required this.errorMessage,
    required this.isSaving,
    required this.isGenerating,
    required this.isInitialSetup,
    required this.onChanged,
    required this.onGenerateRandom,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final TextEditingController controller;
  final String? errorMessage;
  final bool isSaving;
  final bool isGenerating;
  final bool isInitialSetup;
  final ValueChanged<String> onChanged;
  final VoidCallback onGenerateRandom;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    Widget dialogContent = Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: charcoalBlack, width: 3),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: charcoalBlack,
              ),
            ),
            const SizedBox(height: 24),
            _NicknameInputField(
              controller: controller,
              isGenerating: isGenerating,
              onChanged: onChanged,
              onGenerateRandom: onGenerateRandom,
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _NicknameDialogActions(
              isSaving: isSaving,
              isInitialSetup: isInitialSetup,
              onCancel: onCancel,
              onSave: onSave,
            ),
          ],
        ),
      ),
    );

    if (isInitialSetup) {
      return PopScope(
        canPop: false,
        child: dialogContent,
      );
    }

    return dialogContent;
  }
}

class _NicknameInputField extends StatelessWidget {
  const _NicknameInputField({
    required this.controller,
    required this.isGenerating,
    required this.onChanged,
    required this.onGenerateRandom,
  });

  final TextEditingController controller;
  final bool isGenerating;
  final ValueChanged<String> onChanged;
  final VoidCallback onGenerateRandom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: charcoalBlack, width: 2),
      ),
      child: TextField(
        controller: controller,
        style: AppTypography.body,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '새 닉네임',
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: isGenerating
              ? Transform.scale(
                  scale: 0.5,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: charcoalBlack,
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: charcoalBlack,
                  ),
                  tooltip: '랜덤 닉네임 생성',
                  onPressed: onGenerateRandom,
                ),
        ),
      ),
    );
  }
}

class _NicknameDialogActions extends StatelessWidget {
  const _NicknameDialogActions({
    required this.isSaving,
    required this.isInitialSetup,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final bool isInitialSetup;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isInitialSetup) ...[
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F9FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: charcoalBlack, width: 2),
                  ),
                ),
                child: Text(
                  '취소',
                  style: AppTypography.button.copyWith(fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: charcoalBlack,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '저장',
                      style: AppTypography.button.copyWith(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
