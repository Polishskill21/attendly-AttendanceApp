import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
import 'package:attendly/global/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs every provider that throws or whose Future/Stream emits an error,
/// including the stack trace, so failing streams can be traced back.
class LoggingProviderObserver extends ProviderObserver {
  const LoggingProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();

    // Expected while the database is being switched or closed.
    if (error is DatabaseNotReadyException) {
      AppLogger.d('Provider', '$name: database not ready');
      return;
    }

    AppLogger.e('Provider', '$name failed', error, stackTrace);
  }
}
