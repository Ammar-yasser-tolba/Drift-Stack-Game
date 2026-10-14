import 'dart:math' as math;
import 'dart:ui';

/// Section 1.3 gameplay constants + Part B world numbers (Section 19).
/// All lengths are dp. Block WIDTHS are fractions of the screen width.
class GameConst {
  GameConst._();

  // --- 1.3 blocks ---
  static const double blockHeight = 28; // pitch per floor
  static const double blockDrawHeight = 25; // drawn height (3 dp gap above)
  static const double blockGap = 3;
  static const double startWidthFrac = 0.60;
  static const double maxWidthFrac = 0.90;
  static const double perfectTolerance = 6;
  static const int comboToGrow = 3;
  static const double growthPerPerfect = 8;
  static const double minWidth = 4;
  static const double blockRadius = 6;

  // --- 1.3 speed ---
  static const double startSpeed = 220;
  static const double speedGain = 5;
  static const double maxSpeed = 520;

  // The whole tower drifts left/right while a block is in play; its speed is
  // a fraction of the block speed so the closing window stays readable.
  static const double stackDriftRatio = 0.55;

  // --- 1.3 events ---
  static const int eventEvery = 10;
  static const int eventLength = 5;
  static const double eventFadeOutSeconds = 0.5;
  static const double speedUpMultiplier = 1.35;
  static const double windSpeed = 60;
  static const double tiltAmplitude = 0.06; // rad
  static const double tiltPeriodSeconds = 4.2;

  // --- 1.3 timings ---
  static const Duration tapDebounce = Duration(milliseconds: 80);
  static const Duration gameOverAnim = Duration(milliseconds: 900);
  static const int resumeCountdownSeconds = 3;

  // --- 5.x rules ---
  static const int minScoreForQuitConfirm = 5; // D2 shown when score >= 5
  static const int maxPitchSteps = 8;
  static const int cameraStartFloor = 8;
  static const int cameraFloorsAboveBase = 8;
  static const double cameraSmoothing = 8; // exponential follow rate (1/s)

  // --- 19.1 world ---
  static const double baseLineFrac = 0.85; // first block top at 85% height
  static const double floorLineWidth = 2;
  static const double glowSigma = 12;
  static const double glowOpacity = 0.55;
  static const double highlightHeight = 4;
  static const double highlightOpacity = 0.25;
  static const double pharaohOutlineWidth = 2;

  // Falling piece
  static const double gravity = 1800; // dp/s²
  static const double fallMaxRotation = 15 * math.pi / 180;
  static const double fallFadeSeconds = 0.6;

  // Particles
  static const double particleRadius = 3;
  static const int burstCount = 18;
  static const double burstSpeed = 140;
  static const double burstLife = 0.6;
  static const int confettiSeconds = 2;

  // Ghost
  static const double ghostLineWidth = 1.5;
  static const double ghostOpacity = 0.25;

  // Shake
  static const double perfectShake = 12;
  static const double missShake = 25;
  static const double shakeSeconds = 0.4;

  // Event tint
  static const double eventTintOpacity = 0.08;
  static const double eventTintFadeIn = 0.3;
  static const double eventTintFadeOut = 0.5;

  // --- 19.2 / 19.3 HUD ---
  static const double pauseTapArea = 56;
  static const double bannerYFrac = 0.22;
  static const double tapToStartYFrac = 0.45;
  static const double scoreTop = 60;
  static const double dailyPillY = 140;
  static const double ghostPillYDaily = 176;
  static const double ghostPillYClassic = 140;
  static const double perfectTextRise = 40;
  static const double perfectTextSeconds = 0.8;
  static const double growTextOffset = 28;
  static const double growTextDelay = 0.1;
  static const double bannerFadeIn = 0.2;
  static const double bannerHold = 1.1;
  static const double bannerFadeOut = 0.2;
  static const double scorePopScale = 1.15;
  static const Duration scorePopDuration = Duration(milliseconds: 120);
  static const int countdownNumberMs = 1000;

  // --- 14 low-end device rule ---
  static const double slowFrameMs = 20;
  static const double slowFrameWindowSeconds = 2;

  // --- Colours of event tints (8%) ---
  static const Color windTint = Color(0xFF18FFFF);
  static const Color speedUpTint = Color(0xFFFF4081);
  static const Color tiltTint = Color(0xFFFFC107);
}
