import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/utils/random_nickname_generator.dart';

part 'nickname/edit_nickname_dialog_view.dart';

class EditNicknameDialog extends StatefulWidget {
  const EditNicknameDialog({
    super.key,
    required this.currentNickname,
    required this.onSave,
    this.isInitialSetup = false,
  });

  final String currentNickname;
  final Future<String?> Function(String) onSave;
  final bool isInitialSetup;

  @override
  State<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<EditNicknameDialog> {
  late final TextEditingController controller;
  String? errorMessage;
  bool isSaving = false;
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentNickname);

    if (widget.currentNickname.isEmpty) {
      _generateRandom();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _generateRandom() async {
    if (isGenerating) {
      return;
    }

    setState(() {
      isGenerating = true;
      errorMessage = null;
    });

    final candidate = await _generateAvailableNickname();

    if (!mounted) {
      return;
    }

    setState(() {
      isGenerating = false;
      if (candidate != null) {
        controller.text = candidate;
      } else {
        errorMessage = '랜덤 닉네임 생성에 실패했습니다. 다시 시도해주세요.';
      }
    });
  }

  Future<String?> _generateAvailableNickname() async {
    final dbService = Get.find<DatabaseService>();
    String candidate = '';
    bool available = false;
    int attempts = 0;

    while (attempts < 10 && !available) {
      candidate = RandomNicknameGenerator.generate();
      available = await dbService.checkNicknameAvailable(candidate);
      attempts++;
    }

    return available ? candidate : null;
  }

  Future<void> _handleSave() async {
    final newNickname = controller.text.trim();
    if (newNickname.isEmpty) {
      if (mounted) {
        setState(() => errorMessage = '닉네임을 입력해주세요');
      }
      return;
    }

    if (!widget.isInitialSetup && newNickname == widget.currentNickname) {
      Get.back();
      return;
    }

    if (mounted) {
      setState(() => isSaving = true);
    }

    final error = await widget.onSave(newNickname);

    if (!mounted) {
      return;
    }

    if (error != null) {
      setState(() {
        errorMessage = error;
        isSaving = false;
      });
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditNicknameDialogView(
      title: widget.isInitialSetup ? '닉네임 설정' : '닉네임 변경',
      controller: controller,
      errorMessage: errorMessage,
      isSaving: isSaving,
      isGenerating: isGenerating,
      isInitialSetup: widget.isInitialSetup,
      onChanged: (_) {
        if (errorMessage != null) {
          setState(() => errorMessage = null);
        }
      },
      onGenerateRandom: _generateRandom,
      onCancel: Get.back,
      onSave: _handleSave,
    );
  }
}
