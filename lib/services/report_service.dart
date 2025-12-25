import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart'; 
import '../providers/app_state.dart';

class ReportService {
  static Future<File> generateGlobalReport(AppState app) async {
    final pdf = pw.Document();

    final allDrives = app.connectedDrives;
    final logs = app.logs;

    //  Cover Page (no emojis, plain text)
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                "USBGuard Security Report",
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.cyan,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                "Global Report (All Drives)",
                style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                "Generated: ${DateTime.now().toLocal().toString().split('.')[0]}",
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    //  Summary & Threats for Each Drive
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final widgets = <pw.Widget>[];

          // Global summary
          widgets.add(pw.Header(level: 0, child: pw.Text("Summary Overview")));
          widgets.add(
              pw.Bullet(text: "Total Connected Drives: ${allDrives.length}"));
          widgets.add(pw.Bullet(text: "Total Logs: ${logs.length}"));
          widgets.add(pw.Bullet(
              text:
                  "Auto-block on threat: ${app.autoBlockOnThreat ? "Enabled" : "Disabled"}"));

          widgets.add(pw.SizedBox(height: 20));

          // Section per drive
          for (final drive in allDrives) {
            final threats = app.threatDetails[drive] ?? [];
            final driveLogs = logs.where((l) => l.drive == drive).toList();

            widgets.add(pw.Header(level: 1, child: pw.Text("Drive: $drive")));

            widgets.add(pw.Bullet(
                text:
                    "Total Scans: ${driveLogs.where((l) => l.event.contains('scan')).length}"));
            widgets.add(pw.Bullet(text: "Threats Found: ${threats.length}"));

            widgets.add(pw.SizedBox(height: 10));

            // Threat files table
            if (threats.isEmpty) {
              widgets.add(pw.Text("No threats found.",
                  style: pw.TextStyle(color: PdfColors.green)));
            } else {
              widgets.add(
                pw.Table.fromTextArray(
                  headers: ["#", "File Path"],
                  data: [
                    for (int i = 0; i < threats.length; i++)
                      ["${i + 1}", threats[i]],
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.red),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 15));

            // Logs for that drive
            if (driveLogs.isEmpty) {
              widgets.add(pw.Text("No logs for this drive."));
            } else {
              widgets.add(
                pw.Table.fromTextArray(
                  headers: ["Time", "Event", "Message"],
                  data: driveLogs
                      .map((l) => [
                            l.timestamp.toLocal().toString().split('.')[0],
                            l.event,
                            l.message,
                          ])
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                ),
              );
            }

            widgets.add(pw.Divider());
          }

          // Global logs at the end
          widgets.add(pw.Header(level: 0, child: pw.Text("All Logs (Global)")));
          if (logs.isEmpty) {
            widgets.add(pw.Text("No logs available."));
          } else {
            widgets.add(
              pw.Table.fromTextArray(
                headers: ["Time", "Event", "Drive", "Message"],
                data: logs
                    .map((l) => [
                          l.timestamp.toLocal().toString().split('.')[0],
                          l.event,
                          l.drive ?? "-",
                          l.message,
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.teal),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 9),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    //  Save file in Documents folder
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      "${dir.path}/USBGuard_Global_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    //  Auto-open the PDF after saving
    await OpenFile.open(file.path);

    return file;
  }
}
