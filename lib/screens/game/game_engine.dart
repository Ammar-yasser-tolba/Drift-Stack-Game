import 'dart:math' as math;
import 'dart:ui';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/skins.dart';
import '../../core/utils/utc_date.dart';
import '../../models/game_mode.dart';
import '../../models/ghost.dart';
import '../../models/run_result.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';

enum GamePhase { ready, playing, over }

enum GameEventType { wind, speedUp, tilt }

class PlacedBlock {
  const PlacedBlock({required this.x, required this.w, required this.floor});

  /// Left edge in dp.
  final double x;

  /// Width in dp.
  final double w;

  /// 0 = base block.
  final int floor;
}

class FallingPiece {
  FallingPiece({
    required this.x,
    required this.y,
    required this.w,
    required this.color,
  });

  double x;
  double y;
  final double w;
  final Color color;
  double vy = 0;
  double rot = 0;
  double rotV = 0;
  double age = 0;
}

class BurstParticle {
  BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  double age = 0;
}

class FloatText {
  FloatText({
    required this.text,
    required this.color,
    required this.x,
    required this.y,
    required this.fontSize,
    this.delay = 0,
  });

  final String text;
  final Color color;
  final double x;
  final double y;
  final double fontSize;
  final double delay;
  double age = 0;

  bool get done => age >= GameConst.perfectTextSeconds + delay;
}

class ActiveEvent {
  ActiveEvent({required this.type, required this.windDir});

  final GameEventType type;
  final int windDir;
  int floorsLeft = GameConst.eventLength;
  double fade = 1;

  Color get color => switch (type) {
        GameEventType.wind => GameConst.windTint,
        GameEventType.speedUp => GameConst.speedUpTint,
        GameEventType.tilt => GameConst.tiltTint,
      };

  String get label => switch (type) {
        GameEventType.wind => windDir > 0 ? 'WIND →' : 'WIND ←',
        GameEventType.speedUp => 'SPEED UP',
        GameEventType.tilt => 'TILT',
      };
}

/// S3 rules: ready / playing / game over (Sections 5 and 19).
class GameEngine {
  GameEngine({
    required this.mode,
    required this.skin,
    required this.size,
    this.ghost,
  }) : baseTop = size.height * GameConst.baseLineFrac {
    seed = mode == GameMode.daily
        ? UtcDate.todaySeed
        : DateTime.now().millisecondsSinceEpoch;
    _rng = math.Random(seed);
    blocks.add(
      PlacedBlock(
        x: size.width * (1 - GameConst.startWidthFrac) / 2,
        w: size.width * GameConst.startWidthFrac,
        floor: 0,
      ),
    );
    _recomputeStackBounds();
  }

  final GameMode mode;
  final SkinDef skin;
  final Size size;
  final Ghost? ghost;
  final double baseTop;

  late final int seed;
  late final math.Random _rng;

  final List<PlacedBlock> blocks = <PlacedBlock>[];
  final List<FallingPiece> pieces = <FallingPiece>[];
  final List<BurstParticle> particles = <BurstParticle>[];
  final List<FloatText> floats = <FloatText>[];

  GamePhase phase = GamePhase.ready;
  ActiveEvent? event;

  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int perfects = 0;
  double speed = GameConst.startSpeed;

  double camera = 0;
  double movingX = 0;
  double movingW = 0;
  int movingDir = 1;

  /// Horizontal drift of the whole tower (all placed blocks) in dp.
  double stackX = 0;
  int stackDir = 1;
  double _stackLo = 0;
  double _stackHi = 0;

  double scorePulse = 0;
  double overT = 0;
  bool lowEnd = false;

  String? bannerText;
  Color bannerColor = AppColors.amber;
  double bannerAge = 0;
  double bannerHold = 1.1;

  double _time = 0;
  double _lastDrop = -10;
  double _shake = 0;
  double _shakeAge = 0;
  bool _recordShown = false;

  double get baseBottom => baseTop + GameConst.blockDrawHeight;

  /// Drift speed of the tower; scales with the block speed so late runs keep
  /// roughly the same relative timing window.
  double get stackSpeed => speed * GameConst.stackDriftRatio;

  /// Top of the moving block in world coordinates.
  double get movingTopY => baseTop - blocks.length * GameConst.blockHeight;

  /// Keeps the whole tower on screen: the drift range is the free space left
  /// around the union of every block.
  void _recomputeStackBounds() {
    double minX = blocks.first.x;
    double maxRight = blocks.first.x + blocks.first.w;
    for (final PlacedBlock b in blocks) {
      if (b.x < minX) minX = b.x;
      if (b.x + b.w > maxRight) maxRight = b.x + b.w;
    }
    _stackLo = -minX;
    _stackHi = size.width - maxRight;
    if (_stackHi < _stackLo) {
      _stackLo = 0;
      _stackHi = 0;
    }
    stackX = stackX.clamp(_stackLo, _stackHi).toDouble();
  }

  double get overProgress => phase == GamePhase.over ? overT : 0;

  double get shakeOffsetX => _shake <= 0
      ? 0
      : math.sin(_shakeAge * 70) * _shake * (1 - _shakeAge / GameConst.shakeSeconds);

  double get tiltAngle {
    final ActiveEvent? e = event;
    if (e == null || e.type != GameEventType.tilt) return 0;
    return GameConst.tiltAmplitude *
        math.sin(2 * math.pi * _time / GameConst.tiltPeriodSeconds) *
        e.fade;
  }

  double get tapToStartOpacity =>
      0.4 + 0.6 * (0.5 + 0.5 * math.sin(2 * math.pi * _time / 1.2));

  double get bannerAlpha {
    if (bannerText == null) return 0;
    const double inT = GameConst.bannerFadeIn;
    const double outT = GameConst.bannerFadeOut;
    if (bannerAge < inT) return bannerAge / inT;
    if (bannerAge < inT + bannerHold) return 1;
    if (bannerAge < inT + bannerHold + outT) {
      return 1 - (bannerAge - inT - bannerHold) / outT;
    }
    return 0;
  }

  // ---------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------

  void start() {
    if (phase != GamePhase.ready) return;
    phase = GamePhase.playing;
    _spawnMoving();
  }

  void tapDrop() {
    if (phase != GamePhase.playing) return;
    if (_time - _lastDrop < GameConst.tapDebounce.inMilliseconds / 1000) return;
    _lastDrop = _time;

    final PlacedBlock top = blocks.last;
    final double topX = top.x + stackX;
    if ((movingX - topX).abs() <= GameConst.perfectTolerance) {
      _placePerfect(top);
      return;
    }
    final double left = math.max(movingX, topX);
    final double right = math.min(movingX + movingW, topX + top.w);
    final double overlap = right - left;
    if (overlap < GameConst.minWidth) {
      _miss();
    } else {
      _placeNormal(top, left - stackX, overlap);
    }
  }

  // ---------------------------------------------------------------------
  // Results
  // ---------------------------------------------------------------------

  void _placePerfect(PlacedBlock top) {
    combo += 1;
    perfects += 1;
    maxCombo = math.max(maxCombo, combo);

    double w = top.w;
    double x = top.x;
    bool grew = false;
    if (combo >= GameConst.comboToGrow) {
      final double maxW = size.width * GameConst.maxWidthFrac;
      final double grown = math.min(maxW, w + GameConst.growthPerPerfect);
      if (grown > w) {
        grew = true;
        w = grown;
        x = (top.x + top.w / 2 - w / 2)
            .clamp(0.0, size.width - w)
            .toDouble();
      }
    }

    blocks.add(PlacedBlock(x: x, w: w, floor: blocks.length));
    _recomputeStackBounds();
    score += 1;
    _bumpSpeed();

    final double cx = x + w / 2 + stackX;
    final double topY = baseTop - (blocks.length - 1) * GameConst.blockHeight;
    _burst(cx, topY + GameConst.blockDrawHeight / 2);
    _shakeBy(GameConst.perfectShake);
    _addFloat(
      combo >= 2 ? 'PERFECT x$combo' : 'PERFECT',
      AppColors.amber,
      cx,
      topY - 6,
      22,
    );
    if (grew) {
      _addFloat(
        'GROW',
        AppColors.cyan,
        cx,
        topY - 6 + GameConst.growTextOffset,
        16,
        delay: GameConst.growTextDelay,
      );
    }
    AudioService.instance.playPerfect(combo);
    HapticsService.instance.heavy();
    _afterDrop();
  }

  void _placeNormal(PlacedBlock top, double left, double overlap) {
    final double topX = top.x + stackX;
    final double topRight = topX + top.w;
    final double movingRight = movingX + movingW;
    final Color color = skin.colorAt(blocks.length);

    if (movingX < topX) {
      _spawnCut(movingX, topX - movingX, color);
    } else if (movingRight > topRight) {
      _spawnCut(topRight, movingRight - topRight, color);
    }

    blocks.add(PlacedBlock(x: left, w: overlap, floor: blocks.length));
    _recomputeStackBounds();
    combo = 0;
    score += 1;
    _bumpSpeed();
    AudioService.instance.play(Sfx.tap);
    HapticsService.instance.light();
    _afterDrop();
  }

  void _miss() {
    _spawnCut(movingX, movingW, skin.colorAt(blocks.length));
    _shakeBy(GameConst.missShake);
    AudioService.instance.play(Sfx.over);
    HapticsService.instance.heavy();
    phase = GamePhase.over;
    overT = 0;
  }

  void _spawnCut(double x, double w, Color color) {
    if (w <= 0) return;
    pieces.add(
      FallingPiece(x: x, y: movingTopY, w: w, color: color)
        ..rotV = (_rng.nextDouble() - 0.5) * 3,
    );
  }

  void _bumpSpeed() {
    speed = math.min(
      GameConst.maxSpeed,
      GameConst.startSpeed + score * GameConst.speedGain,
    );
  }

  void _afterDrop() {
    final ActiveEvent? e = event;
    if (e != null) e.floorsLeft -= 1;

    if (score > 0 && score % GameConst.eventEvery == 0) _startEvent();

    final Ghost? g = ghost;
    if (g != null && !_recordShown && score > g.score) {
      _recordShown = true;
      _showBanner(
        'NEW RECORD PACE',
        AppColors.amber,
        bannerHold: 1.5,
      );
    }
    _spawnMoving();
  }

  void _spawnMoving() {
    movingW = blocks.last.w;
    final bool goRight = _rng.nextBool();
    movingDir = goRight ? 1 : -1;
    movingX = goRight ? 0 : size.width - movingW;
  }

  void _startEvent() {
    final GameEventType type =
        GameEventType.values[_rng.nextInt(GameEventType.values.length)];
    final ActiveEvent e = ActiveEvent(
      type: type,
      windDir: _rng.nextBool() ? 1 : -1,
    );
    event = e;
    _showBanner(e.label, e.color, bannerHold: GameConst.bannerHold);
    AudioService.instance.play(Sfx.perfect, volume: 0.4);
  }

  void _showBanner(String text, Color color, {required double bannerHold}) {
    bannerText = text;
    bannerColor = color;
    bannerAge = 0;
    this.bannerHold = bannerHold;
  }

  void _shakeBy(double amp) {
    _shake = amp;
    _shakeAge = 0;
  }

  void _burst(double cx, double cy) {
    final int count =
        lowEnd ? GameConst.burstCount ~/ 2 : GameConst.burstCount;
    for (int i = 0; i < count; i++) {
      final double a = 2 * math.pi * i / count;
      particles.add(
        BurstParticle(
          x: cx,
          y: cy,
          vx: math.cos(a) * GameConst.burstSpeed,
          vy: math.sin(a) * GameConst.burstSpeed,
        ),
      );
    }
  }

  void _addFloat(
    String text,
    Color color,
    double x,
    double y,
    double fontSize, {
    double delay = 0,
  }) {
    floats.add(
      FloatText(
        text: text,
        color: color,
        x: x,
        y: y,
        fontSize: fontSize,
        delay: delay,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Frame update
  // ---------------------------------------------------------------------

  void update(double dt) {
    if (dt <= 0) return;
    _time += dt;

    final double target = math.max(
          0,
          score - GameConst.cameraFloorsAboveBase,
        ) *
        GameConst.blockHeight;
    camera += (target - camera) *
        (1 - math.exp(-GameConst.cameraSmoothing * dt));

    if (scorePulse > 0) {
      scorePulse = math.max(0.0, scorePulse - dt / 0.12);
    }

    if (_shake > 0) {
      _shakeAge += dt;
      if (_shakeAge >= GameConst.shakeSeconds) _shake = 0;
    }

    for (final FloatText f in floats) {
      f.age += dt;
    }
    floats.removeWhere((FloatText f) => f.done);

    for (final FallingPiece p in pieces) {
      p.age += dt;
      p.vy += GameConst.gravity * dt;
      p.y += p.vy * dt;
      p.rot += p.rotV * dt;
    }
    pieces.removeWhere((FallingPiece p) => p.age >= GameConst.fallFadeSeconds);

    for (final BurstParticle p in particles) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    particles.removeWhere(
      (BurstParticle p) => p.age >= GameConst.burstLife,
    );

    final ActiveEvent? e = event;
    if (e != null && e.floorsLeft <= 0) {
      e.fade -= dt / GameConst.eventFadeOutSeconds;
      if (e.fade <= 0) event = null;
    }

    if (bannerText != null) {
      bannerAge += dt;
      if (bannerAge >=
          GameConst.bannerFadeIn + bannerHold + GameConst.bannerFadeOut) {
        bannerText = null;
      }
    }

    if (phase == GamePhase.playing) {
      double sp = speed;
      if (e != null &&
          e.type == GameEventType.speedUp &&
          e.floorsLeft > 0) {
        sp *= GameConst.speedUpMultiplier;
      }
      double vx = movingDir * sp;
      if (e != null && e.type == GameEventType.wind && e.fade > 0) {
        vx += e.windDir * GameConst.windSpeed * e.fade;
      }

      double nx = movingX + vx * dt;
      if (nx <= 0) {
        nx = 0;
        movingDir = 1;
      } else if (nx + movingW >= size.width) {
        nx = size.width - movingW;
        movingDir = -1;
      }
      movingX = nx;

      stackX += stackDir * stackSpeed * dt;
      if (stackX <= _stackLo) {
        stackX = _stackLo;
        stackDir = 1;
      } else if (stackX >= _stackHi) {
        stackX = _stackHi;
        stackDir = -1;
      }
    } else if (phase == GamePhase.over) {
      overT = math.min(
        1.0,
        overT + dt / (GameConst.gameOverAnim.inMilliseconds / 1000),
      );
    }
  }

  RunResult result() {
    return RunResult(
      mode: mode,
      score: score,
      perfects: perfects,
      maxCombo: maxCombo,
      ghost: Ghost(
        score: score,
        seed: seed,
        floors: <GhostFloor>[
          for (final PlacedBlock b in blocks)
            GhostFloor(b.x / size.width, b.w / size.width),
        ],
      ),
    );
  }
}
