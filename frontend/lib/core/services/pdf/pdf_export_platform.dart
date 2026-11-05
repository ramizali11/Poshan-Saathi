import 'dart:typed_data';

abstract class PdfExportPlatform {
  Future<String> saveAndOpenPdf({
    required Uint8List bytes,
    required String fileName,
  });
}

