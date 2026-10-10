import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:attendly/app/startup/views/loading_view.dart';
import 'package:attendly/app/startup/views/startup_dialogs.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The year changed: shows the loading screen with the year-change dialog on
/// top, as before.
class RolloverView extends ConsumerStatefulWidget {
  const RolloverView({super.key});

  @override
  ConsumerState<RolloverView> createState() => _RolloverViewState();
}

class _RolloverViewState extends ConsumerState<RolloverView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    if (!mounted) return;
    final choice = await StartupDialogs.yearChange(context);
    AppLogger.i('Startup', "Year change dialog: user chose ${choice?.name ?? 'nothing'}");

    final notifier = ref.read(appStartupProvider.notifier);
    if (choice == YearChangeChoice.create) {
      await notifier.confirmRollover();
    } else {
      await notifier.declineRollover();
    }
  }

  @override
  Widget build(BuildContext context) => const LoadingView();
}

/// The year rollover failed: offers retry, or keeps the old database.
class RolloverFailedView extends ConsumerStatefulWidget {
  final Object error;

  const RolloverFailedView({super.key, required this.error});

  @override
  ConsumerState<RolloverFailedView> createState() => _RolloverFailedViewState();
}

class _RolloverFailedViewState extends ConsumerState<RolloverFailedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    if (!mounted) return;
    final retry = await StartupDialogs.rolloverFailed(context, widget.error.toString()) ?? false;

    final notifier = ref.read(appStartupProvider.notifier);
    if (retry) {
      AppLogger.i('Startup', 'User retries the year rollover');
      await notifier.confirmRollover();
    } else {
      AppLogger.i('Startup', 'User cancelled the rollover, falling back to the old database');
      await notifier.declineRollover();
    }
  }

  @override
  Widget build(BuildContext context) => const LoadingView();
}
