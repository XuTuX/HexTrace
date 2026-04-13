import 'package:flutter/material.dart';

enum GameColor { coral, amber, mint, azure, violet, rainbow }

extension GameColorKey on GameColor {
  String get key => switch (this) {
        GameColor.coral => 'coral',
        GameColor.amber => 'amber',
        GameColor.mint => 'mint',
        GameColor.azure => 'azure',
        GameColor.violet => 'violet',
        GameColor.rainbow => 'rainbow',
      };

  bool get isRainbow => this == GameColor.rainbow;

  static List<GameColor> get baseColors => const [
        GameColor.coral,
        GameColor.amber,
        GameColor.mint,
        GameColor.azure,
        GameColor.violet,
      ];
}

enum DragState { idle, building, valid, invalid }

enum GameMessageTone { info, success, warning, error }

enum GameMode { normal, dailyPractice, dailyOfficial, replay }

@immutable
class GameSessionConfig {
  const GameSessionConfig({
    required this.mode,
    this.seed,
    this.dateKey,
    this.weekKey,
    this.isOfficialScoreSubmission = false,
  });

  const GameSessionConfig.normal()
      : mode = GameMode.normal,
        seed = null,
        dateKey = null,
        weekKey = null,
        isOfficialScoreSubmission = false;

  final GameMode mode;
  final int? seed;
  final String? dateKey;
  final String? weekKey;
  final bool isOfficialScoreSubmission;

  bool get isDailyMode =>
      mode == GameMode.dailyPractice || mode == GameMode.dailyOfficial;

  bool get isReplayMode => mode == GameMode.replay;

  String get modeLabel => switch (mode) {
        GameMode.normal => '일반 모드',
        GameMode.dailyPractice => '오늘의 퍼즐 연습',
        GameMode.dailyOfficial => '오늘의 퍼즐',
        GameMode.replay => '리플레이',
      };
}

@immutable
class ColorBarEntry {
  const ColorBarEntry({required this.id, required this.color});

  final int id;
  final GameColor color;
}

@immutable
class HexCoord {
  const HexCoord(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) {
    return other is HexCoord && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);
}

@immutable
class BarWindow {
  const BarWindow(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start + 1;

  bool containsIndex(int index) => index >= start && index <= end;
}

@immutable
class RecordedMove {
  const RecordedMove({
    required this.path,
    required this.combo,
  });

  final List<HexCoord> path;
  final int combo;
}

@immutable
class BestMoveSummary {
  const BestMoveSummary({
    required this.pathLength,
    required this.scoreGained,
    required this.combo,
  });

  final int pathLength;
  final int scoreGained;
  final int combo;

  bool isBetterThan(BestMoveSummary other) {
    if (scoreGained != other.scoreGained) {
      return scoreGained > other.scoreGained;
    }
    if (pathLength != other.pathLength) {
      return pathLength > other.pathLength;
    }
    return combo > other.combo;
  }

  Map<String, dynamic> toJson() {
    return {
      'path_length': pathLength,
      'score_gained': scoreGained,
      'combo': combo,
    };
  }
}

@immutable
class GameRunSummary {
  const GameRunSummary({
    required this.mode,
    required this.score,
    required this.maxCombo,
    required this.longestPathLength,
    required this.matchCount,
    required this.invalidAttemptCount,
    required this.remainingTime,
    required this.bestMove,
    this.dateKey,
    this.seed,
  });

  final GameMode mode;
  final int score;
  final int maxCombo;
  final int longestPathLength;
  final int matchCount;
  final int invalidAttemptCount;
  final double remainingTime;
  final BestMoveSummary? bestMove;
  final String? dateKey;
  final int? seed;

  bool get isDailyMode =>
      mode == GameMode.dailyPractice || mode == GameMode.dailyOfficial;

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'score': score,
      'max_combo': maxCombo,
      'longest_path_length': longestPathLength,
      'match_count': matchCount,
      'invalid_attempt_count': invalidAttemptCount,
      'remaining_time': remainingTime,
      'date_key': dateKey,
      'seed': seed,
      'best_move': bestMove?.toJson(),
    };
  }
}
