import 'package:attendly/app/shell/app_shell.dart';
import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:attendly/app/startup/startup_state.dart';
import 'package:attendly/app/startup/views/failed_view.dart';
import 'package:attendly/app/startup/views/loading_view.dart';
import 'package:attendly/app/startup/views/migrating_view.dart';
import 'package:attendly/app/startup/views/permission_view.dart';
import 'package:attendly/app/startup/views/rollover_view.dart';
import 'package:attendly/app/startup/views/setup_view.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/settings/widgets/changelog_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home of the app: shows the startup screen that matches [appStartupProvider],
/// and the app shell once a database is open.
class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may come back from the system settings with the permission granted.
    if (state == AppLifecycleState.resumed) {
      ref.read(appStartupProvider.notifier).recheckPermission();
    }
  }

  void _onStartupChanged(AsyncValue<StartupState>? previous, AsyncValue<StartupState> next) {
    final wasReady = previous?.valueOrNull is StartupReady && !(previous?.isLoading ?? false);
    final isReady = next.valueOrNull is StartupReady && !next.isLoading;

    if (wasReady && !isReady) {
      // Leaving the shell (database switch or error): close every page and
      // dialog on top of it, so the startup screen is visible.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (!wasReady && isReady && !ref.read(databaseProvider).isTemporaryDb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ChangelogDialog.presentChangelogIfNew(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appStartupProvider, _onStartupChanged);

    final startup = ref.watch(appStartupProvider);
    final value = startup.valueOrNull;
    final isBusy = startup.isLoading;

    if (value == null) {
      if (startup.hasError && !startup.isLoading) {
        return FailedView(failure: StartupFailed(startup.error!));
      }
      return const LoadingView();
    }

    return switch (value) {
      StartupNeedsPermission() =>
        PermissionView(permanentlyDenied: value.permanentlyDenied, isBusy: isBusy),
      StartupNeedsSetup() => SetupView(isBusy: isBusy),
      StartupRolloverAvailable() => RolloverView(key: ObjectKey(value)),
      StartupRolloverFailed() => RolloverFailedView(key: ObjectKey(value), error: value.error),
      StartupMigrating() => const MigratingView(),
      StartupReady() => const AppShell(),
      StartupFailed() => FailedView(failure: value, isBusy: isBusy),
    };
  }
}
