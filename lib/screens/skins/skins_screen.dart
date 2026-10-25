import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/skins.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/coins_chip.dart';
import '../../widgets/glow_block.dart';

/// S6 Skins (Sections 10 and 22).
class SkinsScreen extends StatefulWidget {
  const SkinsScreen({super.key});

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  final StorageService _storage = StorageService.instance;
  late String _selectedId = _storage.equippedSkinId;

  SkinDef get _selected => Skins.byId(_selectedId);

  Future<void> _action() async {
    final SkinDef skin = _selected;
    if (_storage.equippedSkinId == skin.id) return;

    if (_storage.ownsSkin(skin.id)) {
      _storage.equipSkin(skin.id);
      AppSnackbar.show('${skin.name} equipped');
      return;
    }

    if (_storage.coins < skin.price) {
      await showAppDialog<bool>(
        context: context,
        title: 'Not enough coins',
        body: 'You need ${skin.price - _storage.coins} more coins. '
            'Play a few runs to earn them.',
        buttons: const <DialogButton<bool>>[
          DialogButton<bool>(label: 'OK', value: true),
        ],
        backValue: true,
      );
      return;
    }

    final bool? buy = await showAppDialog<bool>(
      context: context,
      title: 'Buy ${skin.name}?',
      body: 'This will cost ${skin.price} coins.',
      buttons: const <DialogButton<bool>>[
        DialogButton<bool>(label: 'CANCEL', value: false, style: DialogButtonStyle.muted),
        DialogButton<bool>(label: 'BUY', value: true, style: DialogButtonStyle.amber),
      ],
      backValue: false,
    );
    if (buy != true || !mounted) return;

    if (_storage.buySkin(skin)) {
      AudioService.instance.play(Sfx.perfect);
      HapticsService.instance.light();
      AppSnackbar.show('Unlocked ${skin.name}!');
    }
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
                        'SKINS',
                        maxLines: 1,
                        style: AppTextStyles.h2.scaled(r.scale).copyWith(height: 1.0),
                      ),
                    ),
                  ),
                  Positioned(
                    right: r.u(24),
                    top: r.yPos(16),
                    child: CoinsChip(coins: _storage.coins),
                  ),
                  Positioned(
                    left: r.u(24),
                    top: r.yPos(88),
                    width: r.u(312),
                    height: r.u(220),
                    child: _preview(r),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: r.yPos(328),
                    child: Center(child: _firstRow(r)),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: r.yPos(472),
                    child: Center(child: _secondRow()),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: r.yPos(716),
                    child: Center(child: _actionButton(r)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(Responsive r) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.u(28)),
        border: Border.all(color: AppColors.cyan, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ...previous,
            if (current != null) current,
          ],
        ),
        child: _SkinPreview(
          key: ValueKey<String>(_selected.id),
          skin: _selected,
        ),
      ),
    );
  }

  Widget _firstRow(Responsive r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _card(Skins.all[0]),
        SizedBox(width: r.u(12)),
        _card(Skins.all[1]),
      ],
    );
  }

  Widget _secondRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[_card(Skins.all[2])],
    );
  }

  Widget _card(SkinDef skin) {
    return _SkinCard(
      skin: skin,
      selected: skin.id == _selectedId,
      equipped: skin.id == _storage.equippedSkinId,
      owned: _storage.ownsSkin(skin.id),
      onTap: () => setState(() => _selectedId = skin.id),
    );
  }

  Widget _actionButton(Responsive r) {
    final SkinDef skin = _selected;
    final bool owned = _storage.ownsSkin(skin.id);
    final bool equipped = skin.id == _storage.equippedSkinId;

    if (equipped) {
      return const PrimaryButton(label: 'EQUIPPED', onTap: null, height: 60);
    }
    if (owned) {
      return PrimaryButton(label: 'EQUIP', onTap: _action, height: 60);
    }
    return PrimaryButton(
      label: 'BUY · ${skin.price}',
      onTap: _action,
      height: 60,
      fill: AppColors.amber,
      textColor: AppColors.bgTop,
      glow: AppColors.amber,
      leading: _BuyCoin(r: r),
    );
  }
}

/// Section 22 preview: selected skin gradient, name, 7-block tower.
class _SkinPreview extends StatelessWidget {
  const _SkinPreview({super.key, required this.skin});

  final SkinDef skin;

  static const List<double> _widths = <double>[160, 150, 138, 126, 114, 100, 86];

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(decoration: BoxDecoration(gradient: skin.gradient)),
        Positioned(
          left: r.u(16),
          top: r.u(14),
          child: Text(
            skin.name,
            maxLines: 1,
            style: AppTextStyles.button.scaled(r.scale).copyWith(
              fontSize: 18 * r.scale,
              letterSpacing: 2 * r.scale,
              height: 1.0,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: r.u(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = _widths.length - 1; i >= 0; i--) ...<Widget>[
                  GlowBlock(
                    width: r.u(_widths[i]),
                    height: r.u(22),
                    radius: r.u(6),
                    color: skin.colorAt(i),
                    outline: skin.outline,
                  ),
                  if (i > 0) SizedBox(height: r.u(3)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Section 22 skin card: two palette bars, name and the state line.
class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.equipped,
    required this.owned,
    required this.onTap,
  });

  final SkinDef skin;
  final bool selected;
  final bool equipped;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return AppCard(
      width: r.u(150),
      height: r.u(132),
      radius: r.u(20),
      padding: EdgeInsets.zero,
      selected: selected,
      opacity: owned ? 1.0 : 0.85,
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: r.u(18),
            left: 0,
            right: 0,
            child: Column(
              children: <Widget>[
                _bar(r, skin.blockColors[0]),
                SizedBox(height: r.u(4)),
                _bar(r, skin.blockColors[1]),
              ],
            ),
          ),
          Positioned(
            top: r.u(55),
            left: 8,
            right: 8,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  skin.name,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTextStyles.family,
                    fontFamilyFallback: AppTextStyles.fallback,
                    fontSize: 18 * r.scale,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: r.u(90),
            left: 6,
            right: 6,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _status(r))),
          ),
          if (equipped)
            Positioned(
              top: r.u(8),
              right: r.u(8),
              child: Container(
                width: r.u(20),
                height: r.u(20),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.cyan),
                child: Icon(Icons.check, size: r.u(13), color: AppColors.bgTop),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(Responsive r, Color color) {
    return Container(
      width: r.u(100),
      height: r.u(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r.u(4)),
      ),
    );
  }

  Widget _status(Responsive r) {
    const TextStyle base = TextStyle(
      fontFamily: AppTextStyles.family,
      fontFamilyFallback: AppTextStyles.fallback,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );
    if (equipped) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check, size: 13 * r.scale, color: AppColors.cyan),
          SizedBox(width: r.u(3)),
          Text(
            'EQUIPPED',
            maxLines: 1,
            style: base.copyWith(
              fontSize: 13 * r.scale,
              letterSpacing: 0.5 * r.scale,
              color: AppColors.cyan,
            ),
          ),
        ],
      );
    }
    if (owned) {
      return Text(
        'OWNED',
        maxLines: 1,
        style: base.copyWith(
          fontSize: 13 * r.scale,
          letterSpacing: 0.5 * r.scale,
          color: AppColors.textSecondary,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.lock, size: 14 * r.scale, color: AppColors.amber),
        SizedBox(width: r.u(4)),
        Text(
          '${skin.price}',
          maxLines: 1,
          style: base.copyWith(fontSize: 15 * r.scale, color: AppColors.amber),
        ),
      ],
    );
  }
}

/// Dark coin mark that reads on the amber BUY button.
class _BuyCoin extends StatelessWidget {
  const _BuyCoin({required this.r});

  final Responsive r;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: r.u(20),
      height: r.u(20),
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgTop),
      child: Text(
        'C',
        style: TextStyle(
          fontFamily: AppTextStyles.family,
          fontFamilyFallback: AppTextStyles.fallback,
          fontSize: 12 * r.scale,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: AppColors.amber,
        ),
      ),
    );
  }
}
