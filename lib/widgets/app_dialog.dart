import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';
import 'app_buttons.dart';

enum DialogButtonStyle { primary, muted, danger, amber }

class DialogButton<T> {
  const DialogButton({
    required this.label,
    required this.value,
    this.style = DialogButtonStyle.primary,
  });

  final String label;
  final T value;
  final DialogButtonStyle style;
}

bool _dialogOpen = false;

/// Section 15.4 dialog + Rule 1.5-4: only one dialog at a time, cannot be
/// closed by tapping outside, Android Back = [backValue] (the negative /
/// cancel button's value). [buttons] go left → right. Returns the value of
/// the pressed button (or [backValue]); returns null if another dialog is
/// already open.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required String body,
  required List<DialogButton<T>> buttons,
  required T backValue,
}) async {
  if (_dialogOpen) return null;
  _dialogOpen = true;
  try {
    return await showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: AppColors.scrim,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) =>
          _AppDialog<T>(title: title, body: body, buttons: buttons, backValue: backValue),
      transitionBuilder:
          (BuildContext ctx, Animation<double> a, Animation<double> b, Widget child) {
        final Animation<double> curved = CurvedAnimation(parent: a, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  } finally {
    _dialogOpen = false;
  }
}

class _AppDialog<T> extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.body,
    required this.buttons,
    required this.backValue,
  });

  final String title;
  final String body;
  final List<DialogButton<T>> buttons;
  final T backValue;

  Widget _button(BuildContext context, DialogButton<T> b, double width) {
    void pop() => Navigator.of(context).pop(b.value);
    switch (b.style) {
      case DialogButtonStyle.primary:
        return PrimaryButton(label: b.label, onTap: pop, width: width, height: 52);
      case DialogButtonStyle.amber:
        return PrimaryButton(
          label: b.label,
          onTap: pop,
          width: width,
          height: 52,
          fill: AppColors.amber,
          textColor: AppColors.bgTop,
          glow: AppColors.amber,
        );
      case DialogButtonStyle.danger:
        return DangerButton(label: b.label, onTap: pop, width: width, height: 52);
      case DialogButtonStyle.muted:
        return MutedButton(label: b.label, onTap: pop, width: width, height: 52);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double dialogWidth = math.min(r.u(300), r.contentWidth - 48);
    final bool two = buttons.length >= 2;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) Navigator.of(context).pop(backValue);
      },
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: dialogWidth,
            padding: EdgeInsets.all(24 * r.scale),
            decoration: BoxDecoration(
              color: AppColors.dialogFill,
              borderRadius: BorderRadius.circular(24 * r.scale),
              border: Border.all(color: AppColors.a(AppColors.cyan, 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2
                      .scaled(r.scale)
                      .copyWith(fontSize: 24 * r.scale, letterSpacing: 1, height: 1.15),
                ),
                SizedBox(height: 12 * r.scale),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.scaled(r.scale),
                ),
                SizedBox(height: 24 * r.scale),
                if (two)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child: _button(context, buttons[0], 126)),
                      SizedBox(width: 12 * r.scale),
                      Expanded(child: _button(context, buttons[1], 126)),
                    ],
                  )
                else
                  Center(child: _button(context, buttons.first, 200)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
