import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../game/hex_game_models.dart';

class ReplayShareService {
  const ReplayShareService._();

  static const String _shareImageName = 'bee-house-replay.png';

  static String buildReplayCode({
    required int seed,
    required List<RecordedMove> recordedMoves,
  }) {
    final payload = jsonEncode({
      'v': 2,
      'seed': seed,
      'moves': recordedMoves
          .map(
            (move) => {
              'p': move.path
                  .map((coord) => <int>[coord.col, coord.row])
                  .toList(growable: false),
              'c': move.combo,
            },
          )
          .toList(growable: false),
    });

    return 'HTR2:${base64UrlEncode(utf8.encode(payload))}';
  }

  static String buildShareText({
    required int score,
    required int bestScore,
    required bool isNewHighScore,
    required int seed,
    required List<RecordedMove> recordedMoves,
  }) {
    final replayCode = buildReplayCode(
      seed: seed,
      recordedMoves: recordedMoves,
    );

    final bestScoreLine =
        isNewHighScore ? '최고 기록: $bestScore점 (NEW)' : '최고 기록: $bestScore점';

    return [
      'Bee House 리플레이',
      '점수: $score점',
      bestScoreLine,
      '매치 수: ${recordedMoves.length}',
      '시드: $seed',
      '',
      '리플레이 코드',
      replayCode,
    ].join('\n');
  }

  static Future<XFile?> captureReplayCard({
    required GlobalKey repaintBoundaryKey,
    required double pixelRatio,
  }) async {
    await WidgetsBinding.instance.endOfFrame;

    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return captureReplayCard(
        repaintBoundaryKey: repaintBoundaryKey,
        pixelRatio: pixelRatio,
      );
    }

    final image = await boundary.toImage(
      pixelRatio: pixelRatio.clamp(2.0, 4.0),
    );

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      return XFile.fromData(
        _asBytes(byteData),
        mimeType: 'image/png',
        name: _shareImageName,
      );
    } finally {
      image.dispose();
    }
  }

  static Uint8List _asBytes(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
