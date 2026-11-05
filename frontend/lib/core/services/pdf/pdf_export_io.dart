import 'dart:io';
import 'dart:typed_data';
import 'pdf_export_platform.dart';

class PdfExportImpl implements PdfExportPlatform {
  @override
  Future<String> saveAndOpenPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    Directory targetDir;
    try {
      // Try downloads or documents if available, fallback to temp
      final temp = Directory.systemTemp;
      targetDir = temp;
    } catch (_) {
      targetDir = Directory.current;
    }

    final filePath = '${targetDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file.path;
  }
}

PdfExportPlatform getPdfExportPlatform() => PdfExportImpl();

