import 'dart:io';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/services/growth_report_pdf_service.dart';

void main() async {
  print('Generating test PDF report...');
  final pdfService = GrowthReportPdfService.instance;
  final child = MockData.defaultChild;
  final measurements = MockData.growthHistory;

  final bytes = await pdfService.generatePdfBytes(
    child: child,
    measurements: measurements,
  );

  final testFile = File('test_growth_report.pdf');
  await testFile.writeAsBytes(bytes);

  print('PDF written to: ${testFile.absolute.path}');
  print('File size: ${testFile.lengthSync()} bytes');

  // Verify file on disk
  final exists = testFile.existsSync();
  final length = testFile.lengthSync();
  final fileBytes = testFile.readAsBytesSync();
  final header = String.fromCharCodes(fileBytes.take(5));
  final contentSample = String.fromCharCodes(fileBytes.skip(fileBytes.length - 100));

  print('File exists: $exists');
  print('Valid PDF Header (%PDF-): ${header == "%PDF-"} ($header)');
  print('Valid EOF Trailer: ${contentSample.contains("%%EOF")}');

  if (exists && length > 5000 && header == '%PDF-' && contentSample.contains('%%EOF')) {
    print('SUCCESS: The generated PDF is valid, non-empty, and structurally complete!');
  } else {
    print('FAILURE: PDF validation did not pass all criteria.');
    exit(1);
  }
}

