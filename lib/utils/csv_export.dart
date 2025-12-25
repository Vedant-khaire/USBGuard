import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/log_entry.dart';

class CsvExport {
  static Future<File> exportLogs(List<LogEntry> logs) async {
    final buffer = StringBuffer();
    buffer.writeln("timestamp,event,drive,status,message");
    for (final l in logs) {
      buffer.writeln(l.toCsvRow().map((e) => _csvSafe(e)).join(","));
    }

    Directory? dir = await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/usbguard_logs_${DateTime.now().millisecondsSinceEpoch}.csv");
    return file.writeAsString(buffer.toString());
  }

  static String _csvSafe(String input) {
    final needsWrap = input.contains(',') || input.contains('"') || input.contains('\n');
    final escaped = input.replaceAll('"', '""');
    return needsWrap ? '"$escaped"' : escaped;
    }
}
