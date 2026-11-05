import 'dart:typed_data';
import 'pdf_export_platform.dart';
import 'pdf_export_io.dart'
    if (dart.library.html) 'pdf_export_web.dart';

class PdfExportHelper {
  PdfExportHelper._();
  static final PdfExportHelper instance = PdfExportHelper._();

  final PdfExportPlatform _platform = getPdfExportPlatform();

  Future<String> exportPdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _platform.saveAndOpenPdf(bytes: bytes, fileName: fileName);
  }
}

