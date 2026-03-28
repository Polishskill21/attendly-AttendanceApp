import 'package:attendly/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class MigrationProgressDialog extends StatelessWidget {
  const MigrationProgressDialog({super.key});

  /// Shows the dialog and returns a callback that closes it.
  /// The callback is safe to call multiple times.
  static Future<Future<void> Function()> show(BuildContext context) async {
    bool closed = false;
    final startTime = DateTime.now();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const MigrationProgressDialog(),
    );

    await Future.delayed(Duration.zero);

    return () async {
      if (closed) return;
      closed = true;

      final elapsed = DateTime.now().difference(startTime);
      final minimumDuration = const Duration(seconds: 1);

      if (elapsed < minimumDuration) {
        await Future.delayed(minimumDuration - elapsed);
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    };
  }   

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),

              const SizedBox(height: 28),

              // Title
              Text(localizations.migratingDatabase,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              // Body message
              Text(localizations.migrationBodyMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Small warning note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(localizations.doNotCloseAppWarning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}