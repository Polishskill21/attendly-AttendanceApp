import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:attendly/app/startup/startup_state.dart';
import 'package:attendly/app/startup/views/startup_dialogs.dart';
import 'package:attendly/app/startup/views/status_scaffold.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opening the default or a selected database failed, or a page reported a
/// database error.
class FailedView extends ConsumerWidget {
  final StartupFailed failure;
  final bool isBusy;

  const FailedView({super.key, required this.failure, this.isBusy = false});

  Future<void> _createNew(BuildContext context, WidgetRef ref) async {
    final localizations = AppLocalizations.of(context);
    if (!(await StartupDialogs.confirmCreateNew(context) ?? false)) {
      AppLogger.i('Startup', 'User cancelled creating a new database');
      return;
    }
    try {
      await ref.read(appStartupProvider.notifier).createDatabase();
    } catch (_) {
      if (context.mounted) {
        StartupDialogs.error(context, localizations.failedToCreateNewDatabase);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final notifier = ref.read(appStartupProvider.notifier);

    return StatusScaffold(
      icon: Icon(Icons.error_outline, size: isTablet ? 100 : 80, color: Colors.red),
      title: localizations.databaseSwitchFailed,
      message: localizations.databaseOpenFailedMessage,
      details: failure.error.toString(),
      actions: [
        ElevatedButton.icon(
          onPressed: isBusy ? null : notifier.retry,
          label: Text(
            localizations.retry,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.white,
            ),
          ),
          icon: Icon(Icons.refresh,
              color: Colors.white,
              size: isTablet ? 24 : 20),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 16 : 12,
            ),
          ),
        ),
        StartupActionButton(
          label: localizations.createNew,
          icon: StartupActionButton.databaseIcon(context),
          isBusy: isBusy,
          onPressed: () => _createNew(context, ref),
        ),
        if (failure.selectedDb != null)
          TextButton(
            onPressed: isBusy ? null : notifier.openDefault,
            child: Text(localizations.openDefaultDatabase,
                style: TextStyle(fontSize: isTablet ? 18 : 16)),
          ),
        TextButton.icon(
          onPressed: () => StartupDialogs.logs(context, ref),
          icon: Icon(Icons.article_outlined, size: isTablet ? 24 : 20),
          label: Text(localizations.showLogs,
              style: TextStyle(fontSize: isTablet ? 18 : 16)),
        ),
      ],
    );
  }
}
