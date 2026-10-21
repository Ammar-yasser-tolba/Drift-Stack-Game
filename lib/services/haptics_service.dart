import 'package:flutter/services.dart';

import 'storage_service.dart';

/// Vibration wrapper. Rule 1.5-3: when hapticsOn is false nothing vibrates.
class HapticsService {
  HapticsService._();

  static final HapticsService instance = HapticsService._();

  bool get _enabled => StorageService.instance.hapticsOn;

  /// Normal drop, "turn haptics on" sample.
  void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// Perfect drop, miss, new best.
  void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  /// Every button press (Section 27). Uses a light impact rather than
  /// selectionClick: CLOCK_TICK can make Android play its system touch sound,
  /// which the in-app Sound switch cannot mute.
  void selection() {
    if (_enabled) HapticFeedback.lightImpact();
  }
}
