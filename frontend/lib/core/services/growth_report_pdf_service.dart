import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/mock_data.dart';
import 'pdf/pdf_export_helper.dart';

class GrowthReportPdfService {
  GrowthReportPdfService._();
  static final GrowthReportPdfService instance = GrowthReportPdfService._();

  Future<Uint8List> generatePdfBytes({
    required ChildProfile child,
    required List<GrowthMeasurement> measurements,
  }) async {
    final pdf = pw.Document(
      title: 'Poshan Saathi Growth Report - ${child.name}',
      author: 'Ministry of Women and Child Development - Poshan Saathi',
    );

    final primaryColor = PdfColor.fromHex('006A60');
    final secondaryColor = PdfColor.fromHex('115E59');
    final accentColor = PdfColor.fromHex('F59E0B');
    final lightBg = PdfColor.fromHex('F0FDF4');
    final textDark = PdfColor.fromHex('1F2937');
    final textMuted = PdfColor.fromHex('6B7280');
    final borderColor = PdfColor.fromHex('E5E7EB');

    final latest = measurements.isNotEmpty ? measurements.first : null;
    final earliest = measurements.isNotEmpty ? measurements.last : null;
    final double weightChange = (latest != null && earliest != null && latest != earliest)
        ? (latest.weightKg - earliest.weightKg)
        : 0.0;
    final double heightChange = (latest != null && earliest != null && latest != earliest)
        ? (latest.lengthCm - earliest.lengthCm)
        : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'POSHAN SAATHI - HEALTH MISSION',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Maternal and Child Growth Assessment Report (WHO P50 Aligned)',
                      style: pw.TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: primaryColor, width: 0.5),
                      ),
                      child: pw.Text(
                        'ABHA ID: ${child.abhaId}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Date: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 8, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            margin: const pw.EdgeInsets.only(top: 14),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Poshan Saathi - Integrated Child Development Services (ICDS)',
                  style: pw.TextStyle(fontSize: 8, color: textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // 1. Child Demographics Summary Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F9FAFB'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CHILD IDENTIFICATION AND REGISTRATION',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: lightBg,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          child.whoZone.contains('Green') ? 'WHO GREEN ZONE (Normal)' : child.whoZone,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildMetaRow('Child Full Name:', child.name, textDark, textMuted),
                            _buildMetaRow('Age / Cohort:', '${child.ageInMonths} Months (${child.gender})', textDark, textMuted),
                            _buildMetaRow('Date of Birth:', DateFormat('dd MMM yyyy').format(child.dob), textDark, textMuted),
                            _buildMetaRow('Mother / Guardian:', child.motherName, textDark, textMuted),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildMetaRow('Anganwadi Center:', child.anganwadiCenter, textDark, textMuted),
                            _buildMetaRow('Assigned ASHA Worker:', child.ashaWorkerName, textDark, textMuted),
                            _buildMetaRow('Feeding Milestone:', child.feedingStage, textDark, textMuted),
                            _buildMetaRow('Total Records Logged:', '${measurements.length} checkups', textDark, textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 2. Key Growth Metrics Highlights
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetricTile(
                    label: 'LATEST WEIGHT',
                    value: '${child.currentWeightKg.toStringAsFixed(1)} kg',
                    subtext: weightChange >= 0
                        ? '+${weightChange.toStringAsFixed(1)} kg overall gain'
                        : '${weightChange.toStringAsFixed(1)} kg change',
                    accentColor: primaryColor,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMetricTile(
                    label: 'LATEST HEIGHT',
                    value: '${child.currentLengthCm.toStringAsFixed(1)} cm',
                    subtext: heightChange >= 0
                        ? '+${heightChange.toStringAsFixed(1)} cm growth'
                        : '${heightChange.toStringAsFixed(1)} cm change',
                    accentColor: secondaryColor,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMetricTile(
                    label: 'WHO PERCENTILE',
                    value: 'P50 (Median)',
                    subtext: 'Z-Score: +0.1 SD (Normal)',
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // 3. Historical Measurements Table
            pw.Text(
              'MEASUREMENT AND CLINICAL OBSERVATION LOG',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: secondaryColor,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 6),

            measurements.isEmpty
                ? pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    alignment: pw.Alignment.center,
                    child: pw.Text('No historical measurements recorded yet.', style: pw.TextStyle(color: textMuted)),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: borderColor, width: 0.5),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.4), // Date
                      1: pw.FlexColumnWidth(0.9), // Age
                      2: pw.FlexColumnWidth(1.1), // Weight
                      3: pw.FlexColumnWidth(1.1), // Height
                      4: pw.FlexColumnWidth(0.9), // Z-Score
                      5: pw.FlexColumnWidth(2.0), // Session
                      6: pw.FlexColumnWidth(2.6), // Notes
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
                        children: [
                          _buildTableHeader('Date'),
                          _buildTableHeader('Age (m)'),
                          _buildTableHeader('Weight'),
                          _buildTableHeader('Height'),
                          _buildTableHeader('Z-Score'),
                          _buildTableHeader('Checkup / Session'),
                          _buildTableHeader('Clinical Notes and Advice'),
                        ],
                      ),
                      // Data Rows
                      ...measurements.map((m) {
                        return pw.TableRow(
                          children: [
                            _buildTableCell(m.dateString, isBold: true),
                            _buildTableCell('${m.ageMonths}m'),
                            _buildTableCell('${m.weightKg.toStringAsFixed(1)} kg'),
                            _buildTableCell('${m.lengthCm.toStringAsFixed(1)} cm'),
                            _buildTableCell(m.zScore >= 0 ? '+${m.zScore.toStringAsFixed(1)}' : m.zScore.toStringAsFixed(1)),
                            _buildTableCell('${m.eventType}\n(${m.workerName})'),
                            _buildTableCell(m.notes.isNotEmpty ? m.notes : 'Standard clinical progression observed.'),
                          ],
                        );
                      }),
                    ],
                  ),

            pw.SizedBox(height: 18),

            // 4. Clinical Recommendations & WHO Guidance
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: primaryColor, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PEDIATRIC NUTRITIONAL GUIDANCE (ICMR-NIN AND WHO STANDARDS)',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _buildGuidelineBullet(
                    'Dietary Diversity:',
                    'Ensure minimum 4 of 5 food groups daily (Grains/Millets, Pulses, Dairy/Eggs, Yellow/Orange fruits, Green Leafy Vegetables).',
                  ),
                  _buildGuidelineBullet(
                    'Texture Progression:',
                    'Child is at 14 months (Stage 3). Provide coarse mashed foods and soft finger food batons. Do not blend meals into liquid soup.',
                  ),
                  _buildGuidelineBullet(
                    'Iron Bioavailability:',
                    'Add 2-3 drops of fresh lemon or grated amla to lentil feeds to optimize non-heme iron absorption by 300%. Avoid concurrent milk at iron meals.',
                  ),
                  _buildGuidelineBullet(
                    'Upcoming Surveillance:',
                    'Next monthly Mamta Divas session is scheduled at Sector 4 Anganwadi Center. Bring Mother and Child Protection (MCP) card.',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // 5. Official Verification Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Generated By: Poshan Saathi Automated System', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                    pw.Text('Verified By: ${child.ashaWorkerName} (ASHA Community Worker)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(bottom: 24),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Medical Officer / CDPO Signature',
                      style: pw.TextStyle(fontSize: 8, color: textMuted, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<String> exportAndSavePdf({
    required ChildProfile child,
    required List<GrowthMeasurement> measurements,
  }) async {
    final bytes = await generatePdfBytes(child: child, measurements: measurements);
    final sanitizedName = child.name.replaceAll(RegExp(r'\s+'), '_');
    final fileName = 'PoshanSaathi_Growth_Report_${sanitizedName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    return PdfExportHelper.instance.exportPdf(
      bytes: bytes,
      fileName: fileName,
    );
  }

  pw.Widget _buildMetaRow(String label, String value, PdfColor textColor, PdfColor mutedColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: mutedColor, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8.5, color: textColor, fontWeight: pw.FontWeight.bold),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required PdfColor accentColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('E5E7EB')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('6B7280'), fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(subtext, style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('4B5563'))),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('374151'),
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String content, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        content,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('1F2937'),
        ),
      ),
    );
  }

  pw.Widget _buildGuidelineBullet(String title, String description) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('- ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('006A60'))),
          pw.Text('$title ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1F2937'))),
          pw.Expanded(
            child: pw.Text(description, style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('374151'))),
          ),
        ],
      ),
    );
  }
}
