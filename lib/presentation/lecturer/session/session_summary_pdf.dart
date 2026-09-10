// lib/presentation/lecturer/session/session_summary_pdf.dart
//
// Builds a printable PDF of a completed session's attendance summary.
// Consumed by SessionSummaryScreen's "Print Report" button, which hands
// the bytes straight to the OS print sheet via `Printing.layoutPdf`.

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'session_controller.dart';

/// Renders [state] plus the full [roster] into an A4 PDF and returns the
/// encoded bytes. [roster] is every enrolled student with their final
/// status; when it is empty the roster table is omitted.
Future<Uint8List> buildSessionSummaryPdf(
  SessionSummaryState state,
  List<StudentEntry> roster,
) async {
  final fonts = await _loadFonts();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.semiBold,
    ),
  );

  final ordered = [...roster]..sort(_byStatusThenName);
  final generatedAt = DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 44),
      build: (context) => [
        _header(state),
        pw.SizedBox(height: 18),
        _statsRow(state),
        pw.SizedBox(height: 22),
        if (ordered.isNotEmpty) ...[
          pw.Text(
            'Roster (${ordered.length})',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _rosterTable(ordered),
        ],
      ],
      footer: (context) => _footer(context, generatedAt),
    ),
  );

  return doc.save();
}

// ── Sections ─────────────────────────────────────────────────────────────────

pw.Widget _header(SessionSummaryState state) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'SESSION ATTENDANCE SUMMARY',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey600,
          letterSpacing: 1.2,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Session Ended — ${state.courseCode}',
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      if (state.courseName.isNotEmpty)
        pw.Text(
          state.courseName,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
        ),
      pw.SizedBox(height: 10),
      pw.Row(
        children: [
          _meta('Date', _formatDate(state.endedAt)),
          _meta('Started', _formatTime(state.startedAt)),
          _meta('Closed', _formatTime(state.endedAt)),
          _meta('Duration', '${state.durationMinutes} min'),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Divider(color: PdfColors.blueGrey200, height: 1),
    ],
  );
}

pw.Widget _meta(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(right: 28),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey400,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    ),
  );
}

pw.Widget _statsRow(SessionSummaryState state) {
  final total = state.enrolled;
  return pw.Row(
    children: [
      _statCard('Present', state.presentCount, total, PdfColors.green700),
      _statCard('Late', state.lateCount, total, PdfColors.orange700),
      _statCard('Absent', state.absentCount, total, PdfColors.red700),
      _statCard('Enrolled', total, total, PdfColors.blueGrey800,
          showPercent: false),
    ],
  );
}

pw.Widget _statCard(
  String label,
  int count,
  int total,
  PdfColor color, {
  bool showPercent = true,
}) {
  final pct = total == 0 ? 0.0 : (count / total) * 100;
  return pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey500,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '$count',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          if (showPercent)
            pw.Text(
              '${pct.toStringAsFixed(1)}%',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey500,
              ),
            ),
        ],
      ),
    ),
  );
}

pw.Widget _rosterTable(List<StudentEntry> roster) {
  final headerStyle = pw.TextStyle(
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey600,
  );
  const cellStyle = pw.TextStyle(fontSize: 9);

  pw.Widget cell(String text, {pw.TextStyle? style, pw.Alignment? align}) {
    return pw.Container(
      alignment: align ?? pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: style ?? cellStyle),
    );
  }

  return pw.Table(
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfColors.blueGrey100),
      bottom: pw.BorderSide(color: PdfColors.blueGrey200),
    ),
    columnWidths: const {
      0: pw.FixedColumnWidth(24),
      1: pw.FlexColumnWidth(3),
      2: pw.FlexColumnWidth(2),
      3: pw.FixedColumnWidth(60),
      4: pw.FixedColumnWidth(66),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          cell('#', style: headerStyle),
          cell('Name', style: headerStyle),
          cell('Student ID', style: headerStyle),
          cell('Status', style: headerStyle),
          cell('Check-in', style: headerStyle, align: pw.Alignment.centerRight),
        ],
      ),
      for (var i = 0; i < roster.length; i++)
        pw.TableRow(
          children: [
            cell('${i + 1}'),
            cell(roster[i].name),
            cell(roster[i].studentId),
            cell(_statusLabel(roster[i].status)),
            cell(
              roster[i].checkInTime == null
                  ? '—'
                  : _formatTime(roster[i].checkInTime!),
              align: pw.Alignment.centerRight,
            ),
          ],
        ),
    ],
  );
}

pw.Widget _footer(pw.Context context, DateTime generatedAt) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 12),
    child: pw.Text(
      'Generated ${_formatDate(generatedAt)} ${_formatTime(generatedAt)} '
      '· Oromark · Page ${context.pageNumber}/${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey400),
    ),
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _Fonts {
  final pw.Font? regular;
  final pw.Font? semiBold;
  const _Fonts(this.regular, this.semiBold);
}

/// Loads bundled Inter faces for brand consistency. Falls back to the
/// pdf package's built-in Helvetica if the assets can't be read (e.g. in
/// a stripped-down test environment).
Future<_Fonts> _loadFonts() async {
  try {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
    final semiBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
    return _Fonts(regular, semiBold);
  } catch (_) {
    return const _Fonts(null, null);
  }
}

int _byStatusThenName(StudentEntry a, StudentEntry b) {
  int rank(CheckInStatus s) => switch (s) {
        CheckInStatus.present => 0,
        CheckInStatus.late => 1,
        CheckInStatus.notCheckedIn => 2,
      };
  final byRank = rank(a.status).compareTo(rank(b.status));
  return byRank != 0 ? byRank : a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

String _statusLabel(CheckInStatus s) => switch (s) {
      CheckInStatus.present => 'Present',
      CheckInStatus.late => 'Late',
      CheckInStatus.notCheckedIn => 'Absent',
    };

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatTime(DateTime d) {
  final h24 = d.hour;
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = h24 >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}
