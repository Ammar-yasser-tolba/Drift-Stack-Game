import 'package:flutter/material.dart';

import '../core/navigation/app_nav.dart';
import '../core/theme/app_colors.dart';

/// Section 15.4 snackbar: floating, side margin 24, bottom margin 32 (+ safe
/// area), height 48, radius 24, fill #2A2560, text 15 white, optional cyan
/// bold action on the right. Shows 2.5 s, slides up in 200 ms.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final ScaffoldMessengerState? messenger = AppNav.messengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        duration: const Duration(milliseconds: 2500),
        content: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.snackbarFill,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    fontFamily: 'Rajdhani',
                    fontFamilyFallback: <String>['Roboto'],
                  ),
                ),
              ),
              if (actionLabel != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      actionLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyan,
                        fontFamily: 'Rajdhani',
                        fontFamilyFallback: <String>['Roboto'],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      snackBarAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 150),
      ),
    );
  }
}
