import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/reward_model.dart';
import '../models/task_log_model.dart';
import '../models/user_model.dart';

/// Generates a savings report PDF for Pro users.
class PdfExportService {
  PdfExportService._();
  static final instance = PdfExportService._();

  Future<void> exportMonthlyReport({
    required UserModel user,
    required List<TaskLogModel> logs,
    List<RewardModel> redeemed = const [],
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Filter this-month logs
    final monthLogs = logs.where((l) => l.createdAt.isAfter(monthStart)).toList();
    final totalCoinsMonth = monthLogs.fold<int>(0, (s, l) => s + l.coinsEarned);
    final totalTasksMonth = monthLogs.length;

    // Aggregate per-day for a simple bar chart
    final daysInMonth = now.day;
    final dailyTotals = List<int>.filled(daysInMonth, 0);
    for (final l in monthLogs) {
      final d = l.createdAt.day - 1;
      if (d >= 0 && d < daysInMonth) {
        dailyTotals[d] += l.coinsEarned;
      }
    }

    // Top tasks
    final counts = <String, int>{};
    for (final l in monthLogs) {
      counts[l.taskTitle] = (counts[l.taskTitle] ?? 0) + 1;
    }
    final topTasks = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final primaryDark = PdfColor.fromInt(0xFF705D00);
    final secondaryDark = PdfColor.fromInt(0xFF00658B);
    final tertiaryDark = PdfColor.fromInt(0xFF9B3F5A);
    final bg = PdfColor.fromInt(0xFFF0EBE1);
    final surface = PdfColor.fromInt(0xFFFFFFFF);
    final onSurfaceVariant = PdfColor.fromInt(0xFF49454F);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Container(
          color: bg,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TINYSAVER KIDS',
                        style: pw.TextStyle(fontSize: 12,
                          color: primaryDark,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 3)),
                      pw.SizedBox(height: 6),
                      pw.Text('Monthly Savings Report',
                        style: pw.TextStyle(fontSize: 28,
                          color: primaryDark,
                          fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        '${_monthName(now.month)} ${now.year} · ${user.pigName}',
                        style: pw.TextStyle(fontSize: 14,
                          color: onSurfaceVariant)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFECAA),
                      borderRadius: pw.BorderRadius.circular(20)),
                    child: pw.Text('PRO',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: primaryDark,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2)),
                  ),
                ],
              ),
              pw.SizedBox(height: 28),

              // Stats row
              pw.Row(
                children: [
                  _statBox('This Month', '$totalCoinsMonth ${user.currencySymbol}',
                    'coins saved', primaryDark, surface),
                  pw.SizedBox(width: 12),
                  _statBox('Tasks Done', '$totalTasksMonth',
                    'this month', secondaryDark, surface),
                  pw.SizedBox(width: 12),
                  _statBox('Streak', '${user.currentStreak}',
                    'day${user.currentStreak == 1 ? '' : 's'}',
                    tertiaryDark, surface),
                ],
              ),
              pw.SizedBox(height: 24),

              // Real-world value callout
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: surface,
                  borderRadius: pw.BorderRadius.circular(16)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total balance',
                          style: pw.TextStyle(fontSize: 11,
                            color: onSurfaceVariant, letterSpacing: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text(user.formatAmount(user.coinBalance),
                          style: pw.TextStyle(fontSize: 28,
                            color: primaryDark,
                            fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Text('${user.coinBalance} coins',
                      style: pw.TextStyle(fontSize: 16,
                        color: onSurfaceVariant,
                        fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Daily chart
              pw.Text('DAILY SAVINGS',
                style: pw.TextStyle(fontSize: 11,
                  color: onSurfaceVariant, letterSpacing: 2,
                  fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _dailyChart(dailyTotals, primaryDark),
              pw.SizedBox(height: 24),

              // Top tasks
              if (topTasks.isNotEmpty) ...[
                pw.Text('TOP TASKS THIS MONTH',
                  style: pw.TextStyle(fontSize: 11,
                    color: onSurfaceVariant, letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...topTasks.take(5).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 20, height: 20,
                          decoration: pw.BoxDecoration(
                            color: i == 0
                              ? PdfColor.fromInt(0xFFFFECAA)
                              : surface,
                            borderRadius: pw.BorderRadius.circular(6)),
                          alignment: pw.Alignment.center,
                          child: pw.Text('${i + 1}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: primaryDark,
                              fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(child: pw.Text(e.key,
                          style: pw.TextStyle(fontSize: 12,
                            fontWeight: pw.FontWeight.bold))),
                        pw.Text('${e.value} times',
                          style: pw.TextStyle(fontSize: 11,
                            color: primaryDark,
                            fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],

              // Redeemed gifts section
              if (redeemed.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text('REDEEMED GIFTS',
                  style: pw.TextStyle(fontSize: 11,
                    color: onSurfaceVariant, letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...redeemed.take(8).map((r) {
                  final dateStr = r.redeemedAt == null
                    ? ''
                    : _shortDate(r.redeemedAt!);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: surface,
                        borderRadius: pw.BorderRadius.circular(10)),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 24, height: 24,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFFFD0D9),
                              borderRadius: pw.BorderRadius.circular(8)),
                            alignment: pw.Alignment.center,
                            child: pw.Text(r.emoji,
                              style: const pw.TextStyle(fontSize: 14)),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(child: pw.Text(r.title,
                            style: pw.TextStyle(fontSize: 12,
                              fontWeight: pw.FontWeight.bold))),
                          pw.Text(dateStr,
                            style: pw.TextStyle(fontSize: 10,
                              color: onSurfaceVariant)),
                          pw.SizedBox(width: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFFFECAA),
                              borderRadius: pw.BorderRadius.circular(8)),
                            child: pw.Text(
                              '${r.targetCoins} ${user.currencySymbol}',
                              style: pw.TextStyle(fontSize: 10,
                                color: primaryDark,
                                fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (redeemed.length > 8)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      '+ ${redeemed.length - 8} more',
                      style: pw.TextStyle(fontSize: 10,
                        color: onSurfaceVariant,
                        fontStyle: pw.FontStyle.italic)),
                  ),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColor.fromInt(0xFFCAC4D0)),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated ${_formatDate(now)} · TinySaver Kids',
                  style: pw.TextStyle(fontSize: 9,
                    color: onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'TinySaverKids_${_monthName(now.month)}_${now.year}.pdf',
    );
  }

  pw.Widget _statBox(String label, String value, String subtitle,
      PdfColor color, PdfColor surface) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: surface,
          borderRadius: pw.BorderRadius.circular(14)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
              style: pw.TextStyle(fontSize: 9,
                color: color, fontWeight: pw.FontWeight.bold,
                letterSpacing: 1)),
            pw.SizedBox(height: 6),
            pw.Text(value,
              style: pw.TextStyle(fontSize: 20,
                color: color, fontWeight: pw.FontWeight.bold)),
            pw.Text(subtitle,
              style: pw.TextStyle(fontSize: 9,
                color: PdfColor.fromInt(0xFF49454F))),
          ],
        ),
      ),
    );
  }

  pw.Widget _dailyChart(List<int> totals, PdfColor color) {
    final maxValue = totals.isEmpty
        ? 1
        : totals.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    return pw.Container(
      height: 80,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: totals.map((v) {
          final h = (v / safeMax) * 70;
          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 1),
              child: pw.Container(
                height: h < 2 ? 2 : h,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(2)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _monthName(int m) {
    const n = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return n[m - 1];
  }

  String _formatDate(DateTime d) {
    return '${_monthName(d.month)} ${d.day}, ${d.year}';
  }

  String _shortDate(DateTime d) {
    const abbr = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${abbr[d.month - 1]} ${d.day}';
  }
}
