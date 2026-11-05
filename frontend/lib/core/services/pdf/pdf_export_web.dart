// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'pdf_export_platform.dart';

class PdfExportImpl implements PdfExportPlatform {
  @override
  Future<String> saveAndOpenPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return 'Downloaded $fileName in browser';
  }
}

PdfExportPlatform getPdfExportPlatform() => PdfExportImpl();
