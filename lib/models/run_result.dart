import 'game_mode.dart';
import 'ghost.dart';

/// Everything S3 hands to S5 when a run ends (Sections 5.2 and 7).
class RunResult {
  const RunResult({
    required this.mode,
    required this.score,
    required this.perfects,
    required this.maxCombo,
    required this.ghost,
  });

  final GameMode mode;
  final int score;
  final int perfects;
  final int maxCombo;

  /// The finished tower, in screen fractions.
  final Ghost ghost;
}
