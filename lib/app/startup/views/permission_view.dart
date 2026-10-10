import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:attendly/app/startup/views/status_scaffold.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage access is missing. Asks for it, or points to the system settings
/// when it was permanently denied.
class PermissionView extends ConsumerWidget {
  final bool permanentlyDenied;
  final bool isBusy;

  const PermissionView({
    super.key,
    required this.permanentlyDenied,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final notifier = ref.read(appStartupProvider.notifier);

    return StatusScaffold(
      icon: Icon(Icons.folder_off_outlined,
          size: isTablet ? 100 : 80, color: Theme.of(context).primaryColor),
      title: localizations.storagePermissionTitle,
      message: permanentlyDenied
          ? localizations.storagePermissionDeniedMessage
          : localizations.storagePermissionMessage,
      actions: [
        if (permanentlyDenied)
          StartupActionButton(
            label: localizations.openAppSettings,
            icon: Icon(Icons.settings, color: Colors.white, size: isTablet ? 24 : 20),
            onPressed: notifier.openPermissionSettings,
          )
        else
          StartupActionButton(
            label: localizations.grantPermission,
            icon: Icon(Icons.folder_open, color: Colors.white, size: isTablet ? 24 : 20),
            isBusy: isBusy,
            onPressed: notifier.grantPermission,
          ),
      ],
    );
  }
}
