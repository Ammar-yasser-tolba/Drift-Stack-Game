enum GameMode { classic, daily }

enum GhostSource {
  off,
  mine,
  friend;

  static GhostSource fromName(String? name) {
    for (final GhostSource s in GhostSource.values) {
      if (s.name == name) return s;
    }
    return GhostSource.off;
  }
}
