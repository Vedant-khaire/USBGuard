class LogEntry {
  final DateTime timestamp;
  final String event; // 'arrival' | 'remove' | 'scan' | 'info' etc
  final String message;
  final String? drive; // e.g. "E:\"
  final bool isThreat; // mark if scan found threat

  LogEntry({
    required this.timestamp,
    required this.event,
    required this.message,
    this.drive,
    this.isThreat = false,
  });

  List<String> toCsvRow() => [
        timestamp.toIso8601String(),
        event,
        drive ?? '',
        isThreat ? 'THREAT' : 'OK',
        message.replaceAll('\n', ' '),
      ];
}
