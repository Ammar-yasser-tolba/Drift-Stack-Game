# Drift Stack

**A neon stacking game where the tower is never still.**

Drift Stack is a fast, offline-first arcade game built with Flutter. Blocks slide left and right, but so does the tower under them — land a perfect drop, build a combo, and the stack grows wider. Miss by a sliver and the block is cut. Miss entirely, and the run is over. Every tenth floor throws a wind gust, a speed surge, or a tilt at you.

No accounts. No ads. No network permission. Just you, a moving tower, and one tap.

<p align="center">
  <img src="UI/home.png" width="24%" alt="Home screen" />
  <img src="UI/playing.png" width="24%" alt="Gameplay" />
  <img src="UI/game_over.png" width="24%" alt="Game over" />
  <img src="UI/skins.png" width="24%" alt="Skins" />
</p>

---

## Features

- **One-tap gameplay** — tap to drop; precision is rewarded, near-misses cost width.
- **Perfect-drop combos** — three perfects in a row widen your block, up to 90% of the screen.
- **Drifting tower** — the entire stack slides while you aim, so alignment is a moving target, not a static one.
- **Live events every 10 floors** — wind (lateral push), speed-up (×1.35), and tilt (oscillating world rotation).
- **Classic and Daily modes** — Daily uses a deterministic UTC-seat seed, so everyone plays the same tower that day.
- **Ghost replay** — race your best score or a friend's imported ghost, with an opt-in ghost line drawn on the field.
- **Three hand-tuned skins** — Neon, Desert, and Pharaoh (unlocked with coins earned in-run).
- **Share card** — a rendered 1080×1350 PNG score card sent through the native share sheet.
- **Custom-built rendering** — the entire world is a single `CustomPaint` canvas: glow blocks, particles, confetti, shake, floating text, camera.
- **Haptics + low-latency SFX** — pooled SoundPool audio, pitch-laddered combo tones, and device-level haptic feedback.
- **Fully responsive** — a reference-360×800 scaling system with safe-area handling, verified from 320×480 to tablets.
- **100% offline** — local persistence only, screen wakelock while playing, portrait lock.

---

## Tech Stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter 3.47 / Dart 3.13 |
| Rendering | `CustomPainter` + `Canvas`, single `Ticker` game loop |
| State | `GameEngine` (pure Dart logic) + `ChangeNotifier` services, `ListenableBuilder` |
| Persistence | `shared_preferences` (best score, coins, skins, ghost source, settings, daily streak) |
| Audio | `audioplayers` 6.8 — low-latency SoundPool pools of 3 per SFX, playback-rate combo pitch |
| Sharing | `share_plus` → native `shareFiles` channel with a generated PNG |
| Platform | `wakelock_plus` (stay-awake during a run), Android minSdk 24 / targetSdk 35 |
| Fonts | Rajdhani (display), Roboto (body), Roboto Mono (score) |
| Testing | `flutter_test` widget/unit tests + a 60-case responsive matrix |

---

## Installation

### Android (ready to play)

1. Copy `Drift_Stack_Game.apk` to an Android 7.0+ phone.
2. Allow installs from unknown sources when prompted.
3. Install and launch.

### From source

```bash
git clone <your-repo-url>
cd drift_stack
flutter pub get
flutter run --release
```

Build a release APK:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

Requirements: Flutter 3.24+ (tested on 3.47), Android SDK 24+.

---

## How to Play

1. **Tap to start.** The first block begins sliding.
2. **Tap to drop.** The moving block falls onto the tower. Overhang is cut away.
3. **Land perfectly** (within 6 dp of the block below) to earn a perfect. Three in a row grows your block by 8 dp — keep the chain alive and the tower gets wider.
4. **Survive the events.** Every 10th floor brings five floors of wind, extra speed, or tilt. Watch the banner and the tint.
5. **Don't miss.** Less than 4 dp of overlap means the block falls — run over.

**Scoring:** +1 per placed floor, with perfects tracked separately. Coins earned equal your score. Daily mode adds streak tracking.

---

## Screenshots

| Splash | Home | Settings |
| --- | --- | --- |
| ![Splash](UI/splash.png) | ![Home](UI/home.png) | ![Settings](UI/settings.png) |

| Skins | Import Ghost | How to Play |
| --- | --- | --- |
| ![Skins](UI/skins.png) | ![Ghost](UI/import_ghost.png) | ![Tutorial](UI/how_to_play.png) |

| How to Play 2 | How to Play 3 | Game Over |
| --- | --- | --- |
| ![Tutorial 2](UI/how_to_play_2.png) | ![Tutorial 3](UI/how_to_play_3.png) | ![Game Over](UI/game_over.png) |

| Pause | Resume countdown | Building the stack |
| --- | --- | --- |
| ![Pause](UI/pause.png) | ![Countdown](UI/countdown.png) | ![Stack](UI/gameplay_stack.png) |

### Skins and themes

| Neon skin | Desert skin | Pharaoh skin |
| --- | --- | --- |
| ![Neon skins](UI/skins_neon.png) | ![Desert skins](UI/skins_desert.png) | ![Pharaoh skins](UI/skins_pharaoh.png) |

| Desert run | Pharaoh run | Neon run |
| --- | --- | --- |
| ![Desert gameplay](UI/desert_playing.png) | ![Pharaoh gameplay](UI/pharaoh_playing.png) | ![Neon gameplay](UI/neon_playing.png) |

| Desert game over | Neon pause | Home after a run |
| --- | --- | --- |
| ![Desert game over](UI/game_over_desert.png) | ![Neon pause](UI/pause_neon.png) | ![Home end](UI/home_end.png) |

The full walkthrough lives in [`video/gameplay.mp4`](video/gameplay.mp4) (1:25): launch splash → Home → Settings → Skins → How to Play → gameplay in all three themes with pauses, resume countdown, and game over → 20+ floor run. The capture device's screen recorder is video-only, so the MP4 has no audio track.

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # gameplay tuning (GameConst)
│   ├── navigation/     # named routes + transitions (AppRouter)
│   ├── theme/          # colors, text styles, skins, responsive scale
│   └── utils/          # UTC date helper
├── models/             # GameMode, Ghost, RunResult
├── screens/            # splash, home, game, game_over, skins, settings, how_to_play, import_ghost
├── services/           # storage, audio, haptics, share, clipboard
├── widgets/            # background, buttons, cards, dialogs, glow block, pressable, segmented control
├── game/               # GameEngine (logic) + GamePainter (canvas)
└── main.dart
```

The engine has no Flutter dependency beyond `dart:ui` colors and sizes — it is plain, testable logic stepped by the screen's ticker.

---

## Design Notes

- **The tower is the difficulty knob.** Instead of only speeding blocks up, the whole stack drifts at 55% of block speed, keeping the closing window readable at high floors while still raising pressure.
- **The camera is a soft follower.** After floor 8 it tracks the top block with exponential smoothing, so late runs never push the action off-screen.
- **Every animation is derived, not keyframed.** Shake, glow, tilt, banners, and floating text are functions of elapsed time and a small amount of state, which keeps the game loop cheap.
- **Layout is measured, not assumed.** Short screens shrink illustrations, long ones center content, and text never overflows because sizes are computed against the live constraints.

---

## License

Personal project. All artwork, audio, and code original unless noted.

---

<p align="center"><em>Stack clean. Chain perfects. Lose a little, or lose it all.</em></p>
