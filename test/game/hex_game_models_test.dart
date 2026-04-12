import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/game/hex_game_controller.dart';

void main() {
  group('BestMoveSummary.isBetterThan', () {
    test('prefers higher score first', () {
      const low = BestMoveSummary(pathLength: 6, scoreGained: 800, combo: 3);
      const high = BestMoveSummary(pathLength: 4, scoreGained: 900, combo: 1);

      expect(high.isBetterThan(low), isTrue);
      expect(low.isBetterThan(high), isFalse);
    });

    test('uses longer path as the first tie breaker', () {
      const shorter =
          BestMoveSummary(pathLength: 5, scoreGained: 900, combo: 4);
      const longer = BestMoveSummary(pathLength: 7, scoreGained: 900, combo: 2);

      expect(longer.isBetterThan(shorter), isTrue);
    });

    test('uses combo as the second tie breaker', () {
      const lowerCombo =
          BestMoveSummary(pathLength: 7, scoreGained: 900, combo: 2);
      const higherCombo =
          BestMoveSummary(pathLength: 7, scoreGained: 900, combo: 3);

      expect(higherCombo.isBetterThan(lowerCombo), isTrue);
    });
  });
}
