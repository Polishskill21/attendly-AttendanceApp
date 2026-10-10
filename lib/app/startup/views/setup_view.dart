import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:attendly/app/startup/views/startup_dialogs.dart';
import 'package:attendly/app/startup/views/status_scaffold.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// First launch: no database exists yet, so offer to create one.
class SetupView extends ConsumerWidget {
  final bool isBusy;

  const SetupView({super.key, this.isBusy = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;

    return StatusScaffold(
      icon: FaIcon(FontAwesomeIcons.childReaching,
          size: isTablet ? 100 : 80, color: Theme.of(context).primaryColor),
      title: localizations.noDatabaseTitle,
      message: localizations.noDatabaseMessage,
      actions: [
        StartupActionButton(
          label: localizations.createDatabase,
          icon: StartupActionButton.databaseIcon(context),
          isBusy: isBusy,
          onPressed: () async {
            try {
              await ref.read(appStartupProvider.notifier).createDatabase();
            } catch (_) {
              if (context.mounted) {
                StartupDialogs.error(context, localizations.failedToCreateNewDatabase);
              }
            }
          },
        ),
      ],
    );
  }
}
