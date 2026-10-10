import 'package:attendly/shared/widgets/migration_progress_dialog.dart';
import 'package:flutter/material.dart';

/// A schema migration or the year rollover is running.
class MigratingView extends StatelessWidget {
  const MigratingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: MigrationProgressDialog()),
    );
  }
}
