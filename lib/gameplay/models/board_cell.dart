import 'rune_type.dart';

class BoardCell {
  final RuneType type;
  final int level;

  const BoardCell({
    required this.type,
    required this.level,
  });

  BoardCell copyWith({
    RuneType? type,
    int? level,
  }) {
    return BoardCell(
      type: type ?? this.type,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'level': level,
    };
  }

  factory BoardCell.fromJson(Map<String, dynamic> json) {
    return BoardCell(
      type: RuneType.values[json['type'] as int],
      level: json['level'] as int,
    );
  }
}
