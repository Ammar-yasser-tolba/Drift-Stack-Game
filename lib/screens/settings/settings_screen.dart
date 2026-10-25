import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_nav.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../models/game_mode.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_toggle.dart';
import '../../widgets/pressable.dart';
import '../../widgets/segmented_control.dart';

/// S7 Settings (Sections 11 and 23).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  StorageService get _storage => StorageService.instance;

  void _setSound(bool value) {
    _storage.setSoundOn(value);
    if (value) {
      unawaited(AudioService.instance.play(Sfx.tap));
    } else {
      unawaited(AudioService.instance.stopAll());
    }
  }

  void _setHaptics(bool value) {
    _storage.setHapticsOn(value);
    if (value) HapticsService.instance.light();
  }

  void _replayTutorial(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRouter.howToPlay,
      arguments: const RouteArgs(data: false),
    );
  }

  Future<void> _about(BuildContext context) async {
    await showAppDialog<bool>(
      context: context,
      title: 'Drift Stack',
      body: 'Version 1.0.0 · Made with Flutter',
      buttons: const <DialogButton<bool>>[
        DialogButton<bool>(label: 'OK', value: true),
      ],
      backValue: true,
    );
  }

  Future<void> _reset(BuildContext context) async {
    final bool? reset = await showAppDialog<bool>(
      context: context,
      title: 'Reset progress?',
      body: 'Coins, best scores, skins, streak and ghosts will be deleted. '
          'Settings stay.',
      buttons: const <DialogButton<bool>>[
        DialogButton<bool>(label: 'CANCEL', value: false, style: DialogButtonStyle.muted),
        DialogButton<bool>(label: 'RESET', value: true, style: DialogButtonStyle.danger),
      ],
      backValue: false,
    );
    if (reset == true) {
      _storage.resetProgress();
      AppSnackbar.show('Progress reset');
    }
  }

  void _noFriendGhost() {
    AppSnackbar.show(
      'No friend ghost yet',
      actionLabel: 'IMPORT',
      onAction: () => AppNav.navigatorKey.currentState?.pushNamed(AppRouter.importGhost),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return Scaffold(
      body: AppBackground(
        child: ContentFrame(
          child: ListenableBuilder(
            listenable: _storage,
            builder: (BuildContext context, Widget? _) => SizedBox(
              height: r.height,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: r.u(16),
                    top: r.yPos(12),
                    child: IconCircleButton(
                      icon: Icons.arrow_back,
                      semanticLabel: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: r.yPos(16),
                    child: Center(
                      child: Text(
                        'SETTINGS',
                        maxLines: 1,
                        style: AppTextStyles.h2.scaled(r.scale).copyWith(height: 1.0),
                      ),
                    ),
                  ),
                  Positioned(
                    left: r.u(24),
                    top: r.yPos(88),
                    width: r.u(312),
                    height: r.u(224),
                    child: _togglesCard(r),
                  ),
                  Positioned(
                    left: r.u(24),
                    top: r.yPos(328),
                    width: r.u(312),
                    height: r.u(128),
                    child: _linksCard(r, context),
                  ),
                  Positioned(
                    left: r.u(24),
                    top: r.yPos(472),
                    width: r.u(312),
                    height: r.u(64),
                    child: _resetCard(r, context),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: r.yPos(760),
                    child: Center(
                      child: Text(
                        'Drift Stack v1.0.0',
                        maxLines: 1,
                        style: AppTextStyles.caption.scaled(r.scale).copyWith(
                          fontSize: 13 * r.scale,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _togglesCard(Responsive r) {
    return AppCard(
      width: r.u(312),
      height: r.u(224),
      radius: r.u(20),
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 64,
            child: _row(
              r,
              icon: Icons.volume_up,
              label: 'Sound',
              trailing: AppToggle(value: _storage.soundOn, onChanged: _setSound),
            ),
          ),
          _divider(),
          Expanded(
            flex: 64,
            child: _row(
              r,
              icon: Icons.vibration,
              label: 'Haptics',
              trailing: AppToggle(value: _storage.hapticsOn, onChanged: _setHaptics),
            ),
          ),
          _divider(),
          Expanded(flex: 94, child: _ghostRow(r)),
        ],
      ),
    );
  }

  Widget _ghostRow(Responsive r) {
    final bool hasFriend = _storage.friendGhost != null;
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 16 * r.scale, right: 16 * r.scale, top: 8 * r.scale),
          child: Row(
            children: <Widget>[
              Icon(Icons.visibility_outlined, size: 24 * r.scale, color: AppColors.cyan),
              SizedBox(width: 16 * r.scale),
              Text(
                'Ghost',
                maxLines: 1,
                style: AppTextStyles.body.scaled(r.scale).copyWith(
                  fontSize: 18 * r.scale,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SegmentedControl<GhostSource>(
          options: <SegmentOption<GhostSource>>[
            const SegmentOption<GhostSource>(value: GhostSource.off, label: 'OFF'),
            const SegmentOption<GhostSource>(value: GhostSource.mine, label: 'MY BEST'),
            SegmentOption<GhostSource>(
              value: GhostSource.friend,
              label: 'FRIEND',
              enabled: hasFriend,
            ),
          ],
          selected: _storage.ghostSource,
          onChanged: _storage.setGhostSource,
          onDisabledTap: (_) => _noFriendGhost(),
        ),
        SizedBox(height: r.u(10)),
      ],
    );
  }

  Widget _linksCard(Responsive r, BuildContext context) {
    return AppCard(
      width: r.u(312),
      height: r.u(128),
      radius: r.u(20),
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Expanded(
            child: _row(
              r,
              icon: Icons.play_circle_outline,
              label: 'Replay tutorial',
              trailing: _chevron(r),
              onTap: () => _replayTutorial(context),
            ),
          ),
          _divider(),
          Expanded(
            child: _row(
              r,
              icon: Icons.info_outline,
              label: 'About',
              trailing: _chevron(r),
              onTap: () => _about(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resetCard(Responsive r, BuildContext context) {
    return AppCard(
      width: r.u(312),
      height: r.u(64),
      radius: r.u(20),
      padding: EdgeInsets.zero,
      borderColor: AppColors.a(AppColors.danger, 0.4),
      onTap: () => _reset(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * r.scale),
        child: Row(
          children: <Widget>[
            Icon(Icons.delete_outline, size: 24 * r.scale, color: AppColors.danger),
            SizedBox(width: 16 * r.scale),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reset progress',
                  maxLines: 1,
                  style: AppTextStyles.body.scaled(r.scale).copyWith(
                    fontSize: 18 * r.scale,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    Responsive r, {
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final Widget content = Padding(
      padding: EdgeInsets.only(left: 16 * r.scale, right: 16 * r.scale),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 24 * r.scale, color: AppColors.cyan),
          SizedBox(width: 16 * r.scale),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.body.scaled(r.scale).copyWith(
                  fontSize: 18 * r.scale,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
    if (onTap == null) return content;
    return Pressable(
      onTap: onTap,
      builder: (BuildContext context, bool pressed) => Container(
        color: pressed ? AppColors.pressedFill : Colors.transparent,
        child: content,
      ),
    );
  }

  Widget _chevron(Responsive r) =>
      Icon(Icons.chevron_right, size: 24 * r.scale, color: AppColors.textMuted);

  Widget _divider() => Container(height: 1, color: AppColors.divider);
}
