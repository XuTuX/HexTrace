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
      title: '컬러 바 확인하기',
      description:
          '상단 바에는 색상 시퀀스가 표시됩니다. 첫 번째 칸뿐만 아니라 바의 어느 부분이든 연속된 색상 조합을 사용할 수 있습니다.',
    ),
    _TutorialStepData(
      title: '인접한 타일 드래그',
      description:
          '아무 타일에서 시작하여 인접한 타일로만 드래그하세요. 한 경로에서 같은 타일을 두 번 사용할 수 없습니다.',
    ),
    _TutorialStepData(
      title: '연속된 색상 맞추기',
      description:
          '드래그한 타일의 색상이 상단 바의 연속된 부분과 정확히 일치해야 하며, 경로는 최소 3개 이상의 타일로 구성되어야 합니다.',
    ),
    _TutorialStepData(
      title: '제거, 리필, 점수 획득',
      description:
          '유효한 경로를 선택하면 타일이 제거되고 보드가 채워집니다. 상단 바의 색상이 소모되면서 점수와 추가 시간을 획득합니다.',
    ),
    _TutorialStepData(
      title: '시간 제한',
      description:
          '타이머가 0이 되거나 더 이상 유효한 경로가 없으면 라운드가 종료됩니다.',
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
