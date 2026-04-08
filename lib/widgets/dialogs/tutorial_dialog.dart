import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';

part 'tutorial/tutorial_dialog_view.dart';
part 'tutorial/tutorial_footer.dart';
part 'tutorial/tutorial_step_page.dart';

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  static const List<_TutorialStepData> _steps = [
    _TutorialStepData(
      title: 'Read The Color Bar',
      description:
          'The top bar shows a sequence of colors. You may use any contiguous run from that bar, not only the first slots.',
    ),
    _TutorialStepData(
      title: 'Drag Adjacent Hexes',
      description:
          'Start from any hex tile and drag only through adjacent hexes. The same tile cannot be used twice in one route.',
    ),
    _TutorialStepData(
      title: 'Match A Contiguous Run',
      description:
          'Your dragged tile colors must exactly match one contiguous subsequence from the bar, and every valid path must be at least 3 tiles long.',
    ),
    _TutorialStepData(
      title: 'Clear, Refill, Score',
      description:
          'A valid release removes the path, collapses and refills the board, consumes that run from the bar, adds score, and grants bonus time.',
    ),
    _TutorialStepData(
      title: 'Beat The Clock',
      description:
          'The round ends when the timer reaches zero or when no valid path of length 3 or more remains after your shuffle is gone.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Get.back();
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleClose();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TutorialDialogView(
      pageController: _pageController,
      currentPage: _currentPage,
      steps: _steps,
      onClose: _handleClose,
      onNext: _nextPage,
      onBack: _prevPage,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
    );
  }
}

class _TutorialStepData {
  const _TutorialStepData({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
