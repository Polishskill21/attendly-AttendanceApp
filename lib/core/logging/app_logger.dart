import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum LogLevel { debug, info, warning, error }

/// Central logger for the app.
///
/// Every line goes to the console (visible via `flutter run` / `adb logcat`),
/// into a small in-memory buffer (shown in the debug menus) and - once the
/// storage folder is known - into `AttendlyDb/logs/attendly.log`, so problems
/// can be traced on a device without a debugger attached.
///
/// Usage: `AppLogger.e('Database', 'Open failed', error, stackTrace);`
///
/// Log file size / cleanup (no manual deletion needed):
/// - Only info, warning and error lines are written to the file; debug lines
///   and SQL statements ([logSqlStatements]) go to the console only.
/// - On every app start, if `attendly.log` is larger than [_maxFileBytes]
///   (512 KB), the previous `attendly.old.log` is deleted and `attendly.log`
///   is renamed to `attendly.old.log`; a fresh `attendly.log` is started.
/// - At most two files exist, roughly 1 MB in total. The size is only checked
///   at app start, so a single very long session can grow the current file
///   beyond 512 KB until the next restart.
/// - Deleting the files manually is safe; they are recreated on the next log line.
/// - The files live next to the databases in `Documents/AttendlyDb/logs/`
///   and therefore survive an app uninstall.
class AppLogger {
  AppLogger._();

  /// Set to true to print every SQL statement drift executes (very verbose, console only).
  static const bool logSqlStatements = false;

  static const int _maxRecentLines = 500;
  static const int _maxFileBytes = 512 * 1024;
  static const String _logDirName = 'logs';
  static const String _logFileName = 'attendly.log';
  static const String _oldLogFileName = 'attendly.old.log';

  static final Queue<String> _recent = Queue<String>();
  static final List<String> _pendingFileLines = [];
  static File? _logFile;
  static Future<void>? _attaching;
  static Future<void> _writeQueue = Future.value();

  /// Path of the log file, or null while the storage folder is not known yet.
  static String? get logFilePath => _logFile?.path;

  /// The most recent log entries, oldest first.
  static List<String> get recentLines => List.unmodifiable(_recent);

  /// Verbose details for development. Not written to the log file and dropped in release builds.
  static void d(String tag, String message) => _log(LogLevel.debug, tag, message);

  /// Normal milestones (database opened, rollover finished, ...).
  static void i(String tag, String message) => _log(LogLevel.info, tag, message);

  /// Something unexpected that the app recovered from.
  static void w(String tag, String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.warning, tag, message, error, stackTrace);

  /// A failure. Pass the error and stack trace whenever they are available.
  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, tag, message, error, stackTrace);

  /// Starts writing to `<baseDir>/logs/attendly.log`. Lines logged before this
  /// call are written first. Safe to call repeatedly; only the first call counts.
  static Future<void> attachLogDirectory(Directory baseDir) {
    return _attaching ??= _attach(baseDir);
  }

  static Future<void> _attach(Directory baseDir) async {
    try {
      final logDir = Directory(p.join(baseDir.path, _logDirName));
      await logDir.create(recursive: true);

      final file = File(p.join(logDir.path, _logFileName));
      if (await file.exists() && await file.length() > _maxFileBytes) {
        final oldFile = File(p.join(logDir.path, _oldLogFileName));
        if (await oldFile.exists()) await oldFile.delete();
        await file.rename(oldFile.path);
      }

      _logFile = file;
      final pending = List<String>.of(_pendingFileLines);
      _pendingFileLines.clear();
      for (final line in pending) {
        _writeToFile(line);
      }
    } catch (error) {
      debugPrint('AppLogger: could not attach log file: $error');
    }
  }

  static void _log(LogLevel level, String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (level == LogLevel.debug && !kDebugMode) return;

    final buffer = StringBuffer('${_timestamp()} ${_levelLabel(level)}/$tag: $message');
    if (error != null) buffer.write('\n    error: $error');
    if (stackTrace != null) {
      buffer.write('\n    stack:\n');
      buffer.write(stackTrace.toString().trimRight().split('\n').map((l) => '      $l').join('\n'));
    }
    final line = buffer.toString();

    debugPrint(line);

    _recent.addLast(line);
    while (_recent.length > _maxRecentLines) {
      _recent.removeFirst();
    }

    if (level != LogLevel.debug) _writeToFile(line);
  }

  static void _writeToFile(String line) {
    final file = _logFile;
    if (file == null) {
      _pendingFileLines.add(line);
      if (_pendingFileLines.length > _maxRecentLines) _pendingFileLines.removeAt(0);
      return;
    }

    // Chained so lines are appended in order and never interleave.
    _writeQueue = _writeQueue.then((_) async {
      try {
        await file.writeAsString('$line\n', mode: FileMode.append);
      } catch (error) {
        debugPrint('AppLogger: could not write log file: $error');
      }
    });
  }

  static String _timestamp() {
    final now = DateTime.now().toIso8601String().replaceFirst('T', ' ');
    // yyyy-MM-dd HH:mm:ss.SSS
    return now.length > 23 ? now.substring(0, 23) : now;
  }

  static String _levelLabel(LogLevel level) => switch (level) {
        LogLevel.debug   => 'D',
        LogLevel.info    => 'I',
        LogLevel.warning => 'W',
        LogLevel.error   => 'E',
      };
}
