enum RuneType {
  ember,
  tide,
  grove,
  storm,
  voidRune,
}

extension RuneTypeX on RuneType {
  String get label {
    switch (this) {
      case RuneType.ember:
        return 'Ember';
      case RuneType.tide:
        return 'Tide';
      case RuneType.grove:
        return 'Grove';
      case RuneType.storm:
        return 'Storm';
      case RuneType.voidRune:
        return 'Void';
    }
  }

  String get shortLabel {
    switch (this) {
      case RuneType.ember:
        return 'E';
      case RuneType.tide:
        return 'T';
      case RuneType.grove:
        return 'G';
      case RuneType.storm:
        return 'S';
      case RuneType.voidRune:
        return 'V';
    }
  }
}
