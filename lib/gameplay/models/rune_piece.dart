import 'package:flutter/material.dart';

import 'rune_type.dart';

class RunePiece {
  final String id;
  final RuneType type;
  final List<Offset> shape;

  const RunePiece({
    required this.id,
    required this.type,
    required this.shape,
  });

  int get cellCount => shape.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'shape': shape
          .map((cell) => {
                'dx': cell.dx,
                'dy': cell.dy,
              })
          .toList(),
    };
  }

  factory RunePiece.fromJson(Map<String, dynamic> json) {
    return RunePiece(
      id: json['id'] as String,
      type: RuneType.values[json['type'] as int],
      shape: List<Map<String, dynamic>>.from(json['shape'] as List<dynamic>)
          .map(
            (cell) => Offset(
              (cell['dx'] as num).toDouble(),
              (cell['dy'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
