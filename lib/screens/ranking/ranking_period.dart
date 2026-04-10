enum RankingPeriod {
  weekly,
  allTime,
}

extension RankingPeriodX on RankingPeriod {
  String get tabLabel => switch (this) {
        RankingPeriod.weekly => 'WEEKLY',
        RankingPeriod.allTime => '명예의 전당',
      };

  String get topPlayersLabel => switch (this) {
        RankingPeriod.weekly => 'WEEKLY TOP 20',
        RankingPeriod.allTime => '명예의 전당 TOP 20',
      };

  String get emptyMessage => switch (this) {
        RankingPeriod.weekly => 'NO WEEKLY DATA YET',
        RankingPeriod.allTime => '아직 기록이 없습니다',
      };

  String get loggedInEmptyMessage => switch (this) {
        RankingPeriod.weekly => 'PLAY THIS WEEK TO JOIN',
        RankingPeriod.allTime => '내 기록을 남겨보세요',
      };

  String get guestEmptyMessage => switch (this) {
        RankingPeriod.weekly => 'LOG IN TO JOIN THE WEEKLY RANKING',
        RankingPeriod.allTime => '로그인하고 랭킹에 도전하세요',
      };

  String get statusLabel => switch (this) {
        RankingPeriod.weekly => 'MON 00:00 RESET',
        RankingPeriod.allTime => 'HALL OF FAME',
      };
}
