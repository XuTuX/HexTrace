part of 'package:hexor/game/hex_game_controller.dart';

void _beginDrag(HexGameController controller, HexCoord? coord) {
  if (!controller.canInteract || coord == null) {
    return;
  }

  unawaited(AppHaptics.selection());
  controller.dragPath = [coord];
  controller.invalidPulse = false;
  _refreshDragState(controller);
  _updateStatusForDrag(controller);
  controller._notify();
}

void _extendDrag(HexGameController controller, HexCoord? coord) {
  if (!controller.canInteract || coord == null || controller.dragPath.isEmpty) {
    return;
  }

  if (coord == controller.dragPath.last) {
    return;
  }

  if (controller.dragPath.length > 1 &&
      coord == controller.dragPath[controller.dragPath.length - 2]) {
    controller.dragPath = List<HexCoord>.from(controller.dragPath)
      ..removeLast();
    controller.invalidPulse = false;
    _refreshDragState(controller);
    _updateStatusForDrag(controller);
    controller._notify();
    return;
  }

  if (controller.dragPath.contains(coord)) {
    _showInvalidPulse(controller, '같은 드래그에서 같은 타일은 다시 지날 수 없어요.');
    return;
  }

  if (!_isAdjacent(controller, controller.dragPath.last, coord)) {
    _showInvalidPulse(controller, '인접한 육각 타일만 이어서 드래그할 수 있어요.');
    return;
  }

  final candidatePath = [...controller.dragPath, coord];
  final candidateColors = _colorsForPath(controller, candidatePath);

  if (!_sequenceMatchesAnyBarWindow(controller, candidateColors)) {
    _showInvalidPulse(controller, '색 흐름 안의 연속 구간과 정확히 맞아야 해요.');
    return;
  }

  controller.dragPath = candidatePath;
  controller.invalidPulse = false;
  _refreshDragState(controller);
  _updateStatusForDrag(controller);
  controller._notify();
}

void _endDrag(HexGameController controller) {
  if (!controller.canInteract || controller.dragPath.isEmpty) {
    return;
  }

  if (controller.dragState == DragState.valid) {
    _resolveCurrentMatch(controller);
    return;
  }

  controller.statusText =
      controller.dragState == DragState.invalid ? '현재 경로가 색 흐름과 맞지 않아요.' : '';
  controller.statusTone = GameMessageTone.warning;
  _clearDrag(controller);
  controller._notify();
}

void _cancelDrag(HexGameController controller) {
  if (controller.dragPath.isEmpty) {
    return;
  }

  _clearDrag(controller);
  controller._notify();
}

void _refreshDragState(HexGameController controller) {
  if (controller.dragPath.isEmpty) {
    controller.dragState = DragState.idle;
    return;
  }

  final matchesBar = _sequenceMatchesAnyBarWindow(
      controller, _colorsForPath(controller, controller.dragPath));

  if (!matchesBar) {
    controller.dragState = DragState.invalid;
    return;
  }

  controller.dragState =
      controller.dragPath.length >= 3 ? DragState.valid : DragState.building;
}

void _updateStatusForDrag(HexGameController controller) {
  switch (controller.dragState) {
    case DragState.idle:
    case DragState.building:
      controller.statusText = '';
      controller.statusTone = GameMessageTone.info;
      break;
    case DragState.valid:
      controller.statusText = '지금 손을 떼면 이 구간이 제거돼요.';
      controller.statusTone = GameMessageTone.success;
      break;
    case DragState.invalid:
      controller.statusText = '이 경로는 더 이상 연속 구간과 맞지 않아요.';
      controller.statusTone = GameMessageTone.error;
      break;
  }
}

void _showInvalidPulse(HexGameController controller, String message) {
  unawaited(AppHaptics.warning());
  controller.invalidPulse = true;
  controller.statusText = message;
  controller.statusTone = GameMessageTone.error;
  controller._notify();

  final pulseVersion = ++controller._invalidPulseVersion;

  Future<void>.delayed(const Duration(milliseconds: 220)).then((_) {
    if (controller._disposed ||
        pulseVersion != controller._invalidPulseVersion) {
      return;
    }

    controller.invalidPulse = false;
    controller._notify();
  });
}

void _clearDrag(HexGameController controller) {
  controller.dragPath = const [];
  controller.dragState = DragState.idle;
  controller.invalidPulse = false;
}
