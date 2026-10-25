import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../models/game_mode.dart';
import '../../models/ghost.dart';
import '../../services/clipboard_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_snackbar.dart';

/// S8 Import Ghost (Sections 12 and 24).
class ImportGhostScreen extends StatefulWidget {
  const ImportGhostScreen({super.key});

  @override
  State<ImportGhostScreen> createState() => _ImportGhostScreenState();
}

class _ImportGhostScreenState extends State<ImportGhostScreen> {
  final StorageService _storage = StorageService.instance;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  GhostParseError? _error;
  bool _imported = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _error = null);

  String get _errorText => _error == GhostParseError.tooLong
      ? 'This ghost code is too long.'
      : 'This code is damaged or incomplete.';

  Future<void> _paste() async {
    String? text;
    try {
      text = await ClipboardService.paste();
    } catch (_) {
      text = null;
    }
    if (!mounted) return;
    if (text == null) {
      AppSnackbar.show('Clipboard is empty');
      return;
    }
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  void _import() {
    final GhostParseResult result = Ghost.parse(_controller.text);
    if (result.isOk) {
      _storage.importFriendGhost(result.ghost!);
      _focus.unfocus();
      setState(() {
        _error = null;
        _imported = true;
      });
    } else {
      setState(() {
        _error = result.error;
        _imported = false;
      });
    }
  }

  void _remove() {
    _storage.removeFriendGhost();
    setState(() => _imported = false);
  }

  void _playNow() {
    Navigator.of(context).pushNamed(
      AppRouter.game,
      arguments: const RouteArgs(data: GameMode.classic),
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
            builder: (BuildContext context, Widget? _) => SingleChildScrollView(
              child: SizedBox(
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
                          'IMPORT GHOST',
                          maxLines: 1,
                          style: AppTextStyles.h2.scaled(r.scale).copyWith(
                            fontSize: 24 * r.scale,
                            letterSpacing: 3 * r.scale,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: r.u(24),
                      top: r.yPos(88),
                      width: r.u(312),
                      child: Text(
                        "Paste a friend's ghost code to race against their best tower.",
                        maxLines: 2,
                        style: AppTextStyles.body.scaled(r.scale).copyWith(
                          fontSize: 16 * r.scale,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Positioned(
                      left: r.u(24),
                      top: r.yPos(148),
                      width: r.u(312),
                      height: r.u(160),
                      child: _textBox(r),
                    ),
                    Positioned(
                      left: r.u(24),
                      top: r.yPos(324),
                      child: _buttons(r),
                    ),
                    ..._statusElements(r),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textBox(Responsive r) {
    final bool focused = _focus.hasFocus;
    final bool error = _error != null;
    final Color borderColor = error
        ? AppColors.danger
        : focused
            ? AppColors.cyan
            : AppColors.mutedBorder;
    final double borderWidth = error || focused ? 2 : 1.5;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.all(16 * r.scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.u(16)),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        cursorColor: AppColors.cyan,
        style: AppTextStyles.mono.scaled(r.scale).copyWith(fontSize: 14 * r.scale),
        decoration: InputDecoration.collapsed(
          hintText: 'Paste ghost code here',
          hintStyle: AppTextStyles.mono.scaled(r.scale).copyWith(
            fontSize: 14 * r.scale,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buttons(Responsive r) {
    final bool canImport = _controller.text.trim().isNotEmpty;
    return Row(
      children: <Widget>[
        SecondaryButton(
          label: 'PASTE',
          onTap: _paste,
          width: 148,
          height: 52,
        ),
        SizedBox(width: r.u(16)),
        PrimaryButton(
          label: 'IMPORT',
          onTap: canImport ? _import : null,
          enabled: canImport,
          width: 148,
          height: 52,
        ),
      ],
    );
  }

  List<Widget> _statusElements(Responsive r) {
    final Ghost? friend = _storage.friendGhost;
    final bool showSuccess = _imported && friend != null;
    return <Widget>[
      if (_error != null)
        Positioned(
          left: r.u(24),
          top: r.yPos(392),
          width: r.u(312),
          child: Text(
            _errorText,
            maxLines: 2,
            style: AppTextStyles.body.scaled(r.scale).copyWith(
              fontSize: 14 * r.scale,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ),
      if (showSuccess)
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(392),
          child: Center(
            child: Text(
              'Ghost imported · score ${friend.score}',
              maxLines: 1,
              style: AppTextStyles.buttonSmall.scaled(r.scale).copyWith(
                fontSize: 16 * r.scale,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5 * r.scale,
                color: AppColors.success,
              ),
            ),
          ),
        ),
      if (showSuccess)
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(436),
          child: Center(
            child: PrimaryButton(label: 'PLAY NOW', onTap: _playNow, height: 60),
          ),
        ),
      if (friend != null)
        Positioned(
          left: r.u(24),
          top: r.yPos(520),
          width: r.u(312),
          height: r.u(72),
          child: AppCard(
            width: r.u(312),
            height: r.u(72),
            radius: r.u(20),
            padding: EdgeInsets.symmetric(horizontal: 16 * r.scale),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Current friend ghost',
                        maxLines: 1,
                        style: AppTextStyles.caption.scaled(r.scale).copyWith(
                          fontSize: 13 * r.scale,
                          letterSpacing: 0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2 * r.scale),
                      Text(
                        'Score ${friend.score}',
                        maxLines: 1,
                        style: AppTextStyles.button.scaled(r.scale).copyWith(
                          fontSize: 20 * r.scale,
                          letterSpacing: 0,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                AppTextButton(
                  label: 'REMOVE',
                  onTap: _remove,
                  color: AppColors.danger,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
