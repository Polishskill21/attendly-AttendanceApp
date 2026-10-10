import 'dart:io';
import 'package:attendly/app/app.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/logging/logging_provider_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorLogging();
  await _logAppStart();

  if (Platform.isAndroid) {
    // Check if permission is denied before requesting
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      // For Android 10+ (API level 29+)
      if (await Permission.manageExternalStorage.request().isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }
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
