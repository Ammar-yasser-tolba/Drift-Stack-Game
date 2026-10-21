import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Section 9: write the PNG to the temp folder, then open the share sheet.
class ShareService {
  ShareService._();

  /// Writes [pngBytes] to the temp folder and returns the file.
  /// Throws if the file cannot be written (S5 then shows dialog D6).
  static Future<File> writePng(Uint8List pngBytes, {String fileName = 'drift_stack_score.png'}) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  /// Opens the system share sheet with the picture and [text].
  /// Completes when the sheet is closed (sent or not).
  static Future<void> shareImage(File file, String text) async {
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'image/png')],
      text: text,
    );
  }
}
