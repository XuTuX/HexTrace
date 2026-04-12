import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/services/database_models.dart';

void main() {
  group('SeasonTier.fromRank', () {
    test('maps percentile thresholds into the expected tiers', () {
      expect(
        SeasonTier.fromRank(rank: 1, participantCount: 100),
        SeasonTier.diamond,
      );
      expect(
        SeasonTier.fromRank(rank: 5, participantCount: 100),
        SeasonTier.platinum,
      );
      expect(
        SeasonTier.fromRank(rank: 20, participantCount: 100),
        SeasonTier.gold,
      );
      expect(
        SeasonTier.fromRank(rank: 50, participantCount: 100),
        SeasonTier.silver,
      );
      expect(
        SeasonTier.fromRank(rank: 80, participantCount: 100),
        SeasonTier.bronze,
      );
    });
  });
}
