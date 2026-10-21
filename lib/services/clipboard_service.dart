import 'package:flutter/services.dart';

class ClipboardService {
  ClipboardService._();

  static Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  /// Returns the clipboard text, or null if it is empty.
  static Future<String?> paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text;
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }
}
