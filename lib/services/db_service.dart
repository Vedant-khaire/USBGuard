import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/log_entry.dart';

class DBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/usbguard_logs.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            event TEXT,
            drive TEXT,
            message TEXT,
            isThreat INTEGER
          )
        ''');
      },
    );
  }

  static Future<int> insertLog(LogEntry log) async {
    final db = await database;
    return await db.insert("logs", {
      "timestamp": log.timestamp.toIso8601String(),
      "event": log.event,
      "drive": log.drive,
      "message": log.message,
      "isThreat": log.isThreat ? 1 : 0,
    });
  }

  static Future<List<LogEntry>> fetchLogs() async {
    final db = await database;
    final result = await db.query("logs", orderBy: "id DESC");
    return result.map((row) {
      return LogEntry(
        timestamp: DateTime.parse(row["timestamp"] as String),
        event: row["event"] as String,
        drive: row["drive"] as String?,
        message: row["message"] as String,
        isThreat: (row["isThreat"] as int) == 1,
      );
    }).toList();
  }

  static Future<void> clearLogs() async {
    final db = await database;
    await db.delete("logs");
  }

  /// Export logs to TXT
  static Future<File> exportLogsToTxt() async {
    final logs = await fetchLogs();
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/usbguard_logs.txt");

    final buffer = StringBuffer();
    for (var log in logs) {
      buffer.writeln(
          "[${log.timestamp.toLocal()}] ${log.event} | Drive: ${log.drive ?? '-'} | ${log.message} | Threat: ${log.isThreat ? "YES" : "NO"}");
    }

    await file.writeAsString(buffer.toString());
    return file;
  }
}
