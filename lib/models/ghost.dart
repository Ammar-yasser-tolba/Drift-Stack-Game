/// One floor of a ghost tower. Both values are fractions (0..1) of the
/// screen width so the ghost looks the same on any phone (Section 1.4).
class GhostFloor {
  const GhostFloor(this.x, this.w);

  /// Left edge ÷ screen width.
  final double x;

  /// Block width ÷ screen width.
  final double w;
}

enum GhostParseError { damaged, tooLong }

class GhostParseResult {
  const GhostParseResult.ok(this.ghost) : error = null;
  const GhostParseResult.fail(this.error) : ghost = null;

  final Ghost? ghost;
  final GhostParseError? error;

  bool get isOk => ghost != null;
}

/// A saved or imported tower.
/// Code format (Section 12): `DS1|score|seed|x1,w1;x2,w2;...`
/// The number of floors must equal score + 1 (base block + one per point).
class Ghost {
  const Ghost({required this.score, required this.seed, required this.floors});

  final int score;
  final int seed;
  final List<GhostFloor> floors;

  static const String prefix = 'DS1';
  static const int maxFloors = 500;

  String encode() {
    final StringBuffer b = StringBuffer('$prefix|$score|$seed|');
    for (int i = 0; i < floors.length; i++) {
      if (i > 0) b.write(';');
      b
        ..write(_fmt(floors[i].x))
        ..write(',')
        ..write(_fmt(floors[i].w));
    }
    return b.toString();
  }

  static String _fmt(double v) {
    final double c = v.isFinite ? v.clamp(0.0, 1.0).toDouble() : 0.0;
    String s = c.toStringAsFixed(5);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Validates and parses a ghost code.
  /// [enforceMax] is true for user imports (max 500 floors) and false when
  /// reading the player's own saved ghosts back from storage.
  static GhostParseResult parse(String raw, {bool enforceMax = true}) {
    const GhostParseResult damaged = GhostParseResult.fail(GhostParseError.damaged);
    final String code = raw.replaceAll(RegExp(r'\s+'), '');
    final List<String> parts = code.split('|');
    if (parts.length != 4 || parts[0] != prefix) return damaged;

    final int? score = int.tryParse(parts[1]);
    final int? seed = int.tryParse(parts[2]);
    if (score == null || score < 0 || seed == null) return damaged;
    if (parts[3].isEmpty) return damaged;

    final List<String> segments = parts[3].split(';');
    if (enforceMax && segments.length > maxFloors) {
      return const GhostParseResult.fail(GhostParseError.tooLong);
    }

    final List<GhostFloor> floors = <GhostFloor>[];
    for (final String seg in segments) {
      final List<String> xy = seg.split(',');
      if (xy.length != 2) return damaged;
      final double? x = double.tryParse(xy[0]);
      final double? w = double.tryParse(xy[1]);
      if (x == null || w == null) return damaged;
      if (!x.isFinite || !w.isFinite) return damaged;
      if (x < 0 || x > 1 || w < 0 || w > 1) return damaged;
      floors.add(GhostFloor(x, w));
    }
    if (floors.length != score + 1) return damaged;

    return GhostParseResult.ok(Ghost(score: score, seed: seed, floors: floors));
  }

  /// Reads a ghost stored by this app; returns null if empty or unreadable.
  static Ghost? fromStored(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return parse(raw, enforceMax: false).ghost;
  }
}
