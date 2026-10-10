import 'dart:io';
import 'package:attendly/app/app.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/logging/logging_provider_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorLogging();
  await _logAppStart();

  runApp(
    const ProviderScope(
      observers: [LoggingProviderObserver()],
      child: AttendlyApp()
    )
  );
}

/// Routes every uncaught error (widget build, async, platform) into the log with its stack trace.
void _installGlobalErrorLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.e('Flutter', 'Uncaught Flutter error${details.context != null ? ' ${details.context}' : ''}',
        details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.e('Uncaught', 'Unhandled asynchronous error', error, stackTrace);
    return true;
  };
}

Future<void> _logAppStart() async {
  String version = 'unknown';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } catch (_) {}
  AppLogger.i('App', '===== Attendly $version starting on '
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion} '
      '(${kReleaseMode ? 'release' : 'debug'}) =====');
}
