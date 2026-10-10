import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/core/utils/date_utils.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum YearChangeChoice { create, later }

/// Dialogs used by the startup views.
class StartupDialogs {
  const StartupDialogs._();

  static Future<YearChangeChoice?> yearChange(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    return showDialog<YearChangeChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.yearChangeDetected,
            style: TextStyle(
                fontSize: isTablet ? 22.0 : 18.0,
                fontWeight: FontWeight.bold)),
        content: Text(localizations.yearChangeMessage,
            style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(YearChangeChoice.later),
            child: Text(localizations.later,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(YearChangeChoice.create),
            child: Text(localizations.createNew,
                style: TextStyle(fontSize: isTablet ? 24.0 : 16.0)),
          ),
        ],
      ),
    );
  }

  /// Returns true when the user wants to retry the year rollover.
  static Future<bool?> rolloverFailed(BuildContext context, String error) {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.errorOccurred,
          style: TextStyle(
            fontSize: isTablet ? 22.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            '${localizations.failedToCreateNewDatabase}:\n\n$error',
            style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              localizations.cancel,
              style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              localizations.retry,
              style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
            ),
          ),
        ],
        contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      ),
    );
  }

  /// Asks before creating a new database after an existing one failed to open.
  static Future<bool?> confirmCreateNew(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: isTablet ? 32 : 24),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(localizations.createNewDatabaseWarningTitle,
                style: TextStyle(
                    fontSize: isTablet ? 22.0 : 18.0,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        content: SingleChildScrollView(
          child: Text(
            localizations.createNewDatabaseWarning(yearToString(getCurrentYear())),
            style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.createNew,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
          ),
        ],
        contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    final isTablet = ResponsiveUtils.isTablet(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.error_outline, color: Colors.red, size: isTablet ? 32 : 24),
          SizedBox(width: isTablet ? 12 : 8),
          Text('Error',
              style: TextStyle(
                  fontSize: isTablet ? 22.0 : 18.0,
                  fontWeight: FontWeight.bold)),
        ]),
        content: Text(message,
            style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
          ),
        ],
      ),
    );
  }

  /// settings.json and the recent log lines, so problems can be reported
  /// even when the app cannot start.
  static Future<void> logs(BuildContext context, WidgetRef ref) async {
    final jsonContent = await ref.read(databaseProvider.notifier).getSettingsJsonContent();
    if (!context.mounted) return;

    final isTablet = ResponsiveUtils.isTablet(context);
    final localizations = AppLocalizations.of(context);
    final logPath = AppLogger.logFilePath;
    final logs = AppLogger.recentLines.join('\n');
    final sectionStyle = TextStyle(
        fontSize: isTablet ? 18.0 : 16.0, fontWeight: FontWeight.bold);
    final monoStyle = TextStyle(
        fontFamily: 'monospace', fontSize: isTablet ? 14.0 : 12.0);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.json',
            style: TextStyle(
                fontSize: isTablet ? 22.0 : 18.0,
                fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(jsonContent,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isTablet ? 16.0 : 14.0)),
              const Divider(height: 32),
              Text(localizations.recentLogs, style: sectionStyle),
              if (logPath != null)
                Text(logPath,
                    style: monoStyle.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              SelectableText(logs, style: monoStyle),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: 'settings.json:\n$jsonContent\n\n'
                      'Log file: ${logPath ?? 'not available'}\n$logs'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.logsCopiedToClipboard)),
              );
            },
            child: Text(localizations.copyToClipboard,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0)),
          ),
        ],
      ),
    );
  }
}
