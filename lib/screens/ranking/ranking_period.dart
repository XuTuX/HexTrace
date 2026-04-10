enum RankingPeriod {
  weekly,
  allTime,
}

extension RankingPeriodX on RankingPeriod {
  String get tabLabel => switch (this) {
        RankingPeriod.weekly => 'WEEKLY',
        RankingPeriod.allTime => 'ALL-TIME',
      };

  String get topPlayersLabel => switch (this) {
        RankingPeriod.weekly => 'WEEKLY TOP 20',
        RankingPeriod.allTime => 'ALL-TIME TOP 20',
      };

  String get emptyMessage => switch (this) {
        RankingPeriod.weekly => 'NO WEEKLY DATA YET',
        RankingPeriod.allTime => 'NO ALL-TIME DATA',
      };

  String get loggedInEmptyMessage => switch (this) {
        RankingPeriod.weekly => 'PLAY THIS WEEK TO JOIN',
        RankingPeriod.allTime => 'PLAY TO RANK UP',
      };

  String get guestEmptyMessage => switch (this) {
        RankingPeriod.weekly => 'LOG IN TO JOIN THE WEEKLY RANKING',
        RankingPeriod.allTime => 'LOG IN TO JOIN THE RANKING',
      };

  String get statusLabel => switch (this) {
        RankingPeriod.weekly => 'MON 00:00 RESET',
        RankingPeriod.allTime => 'BEST RECORDS EVER',
      };
}
