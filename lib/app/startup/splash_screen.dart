import 'dart:io';
import 'package:attendly/features/settings/widgets/changelog_dialog.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/utils/date_utils.dart';
import 'package:attendly/shared/widgets/migration_progress_dialog.dart';
import 'package:attendly/app/startup/startup_decision.dart';
import 'package:attendly/app/shell/app_shell.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/core/responsive/responsive.dart';


enum YearChangeChoice { create, later }

/// What the splash screen shows once startup has finished.
enum _StartupResult { ready, needsSetup, failed }

class SplashScreen extends ConsumerStatefulWidget {
  final File? selectedDb;
  final Object? dbError;
  
  const SplashScreen({super.key, this.selectedDb, this.dbError});
 
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  static const String _tag = 'Startup';

  late Future<_StartupResult> _startupFuture;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _longPressCounter = 0;
  bool _isCreatingNewDb = false;

  /// Error reported by a page while the app was running; shown once, cleared on retry.
  late bool _showReportedError;
  Object? _startupError;

  Future<void> Function()? _closeSchemaMigrationDialog;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.95, end: 1.10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _showReportedError = widget.dbError != null;
    _startupFuture = _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onSchemaMigrationStarted() async {
    if (_isCreatingNewDb) return;
    if (!mounted) return;
    
    _closeSchemaMigrationDialog = await MigrationProgressDialog.show(context);
  }

  Future<void> _safeCloseSchemaMigrationDialog() async {
    if (_closeSchemaMigrationDialog != null) {
      await _closeSchemaMigrationDialog!();
      _closeSchemaMigrationDialog = null;
    }
  }

  Future<_StartupResult> _initializeApp() async {
    final results = await Future.wait([
      _initializeDatabase(),
      Future.delayed(const Duration(milliseconds: 1300)),
    ]);

    final result = results[0] as _StartupResult;

    if (result != _StartupResult.ready) return result;

    if (mounted && !ref.read(databaseProvider).isTemporaryDb) {
      await ChangelogHelper.presentChangelogIfNew(context);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }

    return _StartupResult.ready;
  }

  Future<_StartupResult> _initializeDatabase() async {
    final notifier = ref.read(databaseProvider.notifier);

    try {
      final decision = await decideStartup(
        notifier,
        hasReportedError: _showReportedError,
        hasSelectedDatabase: widget.selectedDb != null,
      );

      switch (decision) {
        case StartupDecision.showReportedError:
          AppLogger.w(_tag, "Showing error screen for a reported database error");
          _startupError = widget.dbError;
          return _StartupResult.failed;

        case StartupDecision.openSelectedDatabase:
          AppLogger.i(_tag, "Startup: switching to selected database ${widget.selectedDb!.path}");
          await notifier.openDatabase(file: widget.selectedDb, onMigrationStarted: _onSchemaMigrationStarted);
          return _StartupResult.ready;

        case StartupDecision.needsSetup:
          AppLogger.i(_tag, "Startup: no database yet, showing setup screen");
          return _StartupResult.needsSetup;

        case StartupDecision.askForRollover:
          if (!mounted) {
            await notifier.openDatabase(onMigrationStarted: _onSchemaMigrationStarted);
            return _StartupResult.ready;
          }
          final choice = await _showYearChangeDialog();
          AppLogger.i(_tag, "Year change dialog: user chose ${choice?.name ?? 'nothing'}");

          if (choice == YearChangeChoice.create) {
            await _handleYearRollover();
          } else {
            // User chose to stay on the old DB for now — open it with banner
            await notifier.openDatabaseWithBanner(onMigrationStarted: _onSchemaMigrationStarted);
          }
          return _StartupResult.ready;

        case StartupDecision.openDefaultDatabase:
          AppLogger.i(_tag, "Startup: opening default database");
          await notifier.openDatabase(onMigrationStarted: _onSchemaMigrationStarted);
          return _StartupResult.ready;
      }
    } catch (e, stackTrace) {
      AppLogger.e(_tag, "Startup failed, showing error screen", e, stackTrace);
      _startupError = e;
      return _StartupResult.failed;
    }
    finally{
      await _safeCloseSchemaMigrationDialog();
    }
  }

  //   if (widget.selectedDb != null) {
  //     try {
  //       await notifier.openDatabase(file: widget.selectedDb);
  //     } catch (e) {
  //       debugPrint("Could not open specific db: $e");
  //       return true;
  //     }
  //     ref.read(databaseProvider.notifier).setDatabase(
  //       dbManager,
  //       isTemporary: true,
  //       showBanner: false,
  //     );
  //     debugPrint("Database successfully opened (specific path).");
  //     return dbManager;
  //   }

  //   bool rolloverOccurred = false;

  //   rolloverOccurred = await dbManager.checkForYearRollover();
  //   if(rolloverOccurred && mounted){
  //     final choice = await _showYearChangeDialog();

  //     if (choice == YearChangeChoice.create) {
  //       final success = await _handleCreateNewYearDatabase(dbManager);
  //       if (success) {
  //          showNewYearBanner = false;
  //       }
  //       else {
  //         showNewYearBanner = true;
  //         debugPrint("Failed to create new year db");
  //       }

  //     } else {
  //       try {
  //         await dbManager.openDatabase();
  //       } catch (e) {
  //         debugPrint("Could not open old database $e");
  //         return null;
  //       }
  //       showNewYearBanner = true;
  //     }

  //   } else {
  //     try {
  //       await dbManager.openDatabase();
  //       showNewYearBanner = false;
  //     } catch (e) {
  //       debugPrint("Database does not exist, or could not be opened: $e");
  //       return null;
  //     }
  //   }

  //   if (mounted && !isTemporaryDb) {
  //     ChangelogHelper.presentChangelogIfNew(context);
  //   }

  //   debugPrint("Opened database successfully");
  //   return dbManager;
  // }




  void _retryInitialization() {
    AppLogger.i(_tag, "User tapped retry");
    _showReportedError = false;
    _startupError = null;
    setState(() => _startupFuture = _initializeApp());
  }

  void _openDefaultDatabase() {
    AppLogger.i(_tag, "User chose to open the default database");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  /// [withWarning] asks for confirmation first; used when an existing database failed to open.
  void _createNewDatabase({bool withWarning = false}) async {
    if (_isCreatingNewDb) return;
    if (withWarning && !(await _showCreateNewDbWarningDialog() ?? false)) {
      AppLogger.i(_tag, "User cancelled creating a new database");
      return;
    }
    if (!mounted) return;
    AppLogger.i(_tag, "User requested a new database${withWarning ? ' after an open failure' : ' (initial setup)'}");
    setState(() => _isCreatingNewDb = true);
 
    try {
      await ref.read(databaseProvider.notifier).createDatabase();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(_tag, "Creating a new database failed", e, stackTrace);
      if (mounted) {
        _showSimpleErrorDialog(
            AppLocalizations.of(context).failedToCreateNewDatabase);
      }
    } finally {
      if (mounted) setState(() => _isCreatingNewDb = false);
    }
  }

  // void _createNewDatabase() async {
  //   if (_isCreatingNewDb) return;

  //   setState(() => _isCreatingNewDb = true);

  //   try {
  //     final DatabaseManagerInterface dbManager = DatabaseManager();
  //     await dbManager.createDatabase();

  //     if (mounted) {
  //       ref.read(databaseManagerNotifierProvider.notifier).setDatabase(
  //         manager,
  //         isTemporary: isTemporaryDb,
  //         showBanner: showNewYearBanner,
  //       );
  //       Navigator.of(context).pushReplacement(
  //         MaterialPageRoute(builder: (_) => const AppShell()),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint("Error creating new DB: $e");
  //     if (mounted) {
  //       _showSimpleErrorDialog(
  //           AppLocalizations.of(context).failedToCreateNewDatabase);
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isCreatingNewDb = false);
  //   }
  // }

  // Future<void> _handleYearRollover() async {
  //   setState(() => _isCreatingNewDb = true);
  //   final closeDialog = await MigrationProgressDialog.show(context);
 
  //   try {
  //     await ref
  //         .read(databaseProvider.notifier)
  //         .performYearRolloverAndOpen();
  //     // Success — notifier already set showNewYearBanner=false
  //   } catch (e) {
  //     closeDialog();
  //     if (mounted) {
  //       final retry = await _showCreateDbErrorDialog(e.toString()) ?? false;
  //       if (retry) {
  //         return _handleYearRollover();
  //       }
  //       // Rollover failed — fall back to opening old DB with banner
  //       try {
  //         await ref.read(databaseProvider.notifier).openDatabaseWithBanner();
  //       } catch (_) {
  //         // Even fallback failed — _initializeDatabase will return false
  //         rethrow;
  //       }
  //     }
  //   } finally {
  //     closeDialog();
  //     if (mounted) setState(() => _isCreatingNewDb = false);
  //   }
  // }

  Future<void> _handleYearRollover() async {
    setState(() => _isCreatingNewDb = true);
    
    final closeDialog = await MigrationProgressDialog.show(context);
    bool isDialogClosed = false;

    Future<void> safeCloseDialog() async {
      if (!isDialogClosed) {
        await closeDialog();
        isDialogClosed = true;
      }
    }

    try {
      await ref
          .read(databaseProvider.notifier)
          .performYearRolloverAndOpen();
      await safeCloseDialog(); 
      
    } catch (e, stackTrace) {
      AppLogger.e(_tag, "Year rollover failed, asking user to retry", e, stackTrace);
      await safeCloseDialog();

      if (mounted) {
        final retry = await _showCreateDbErrorDialog(e.toString()) ?? false;
        if (retry) {
          AppLogger.i(_tag, "User retries the year rollover");
          return _handleYearRollover();
        }
        AppLogger.i(_tag, "User cancelled the rollover, falling back to the old database");
        try {
          await ref.read(databaseProvider.notifier).openDatabaseWithBanner();
        } catch (_) {
          rethrow;
        }
      }
    } finally {
      await safeCloseDialog(); 
      if (mounted) setState(() => _isCreatingNewDb = false);
    }
  }

  // Future<bool> _handleCreateNewYearDatabase(DatabaseManagerInterface dbManager) async {
  //   setState(() => _isCreatingNewDb = true);
  //   try {
  //     await dbManager.performYearRolloverAndOpen();
  //     return true;
  //   } catch (e) {
  //     if (mounted) {
  //       final shouldRetry = await _showCreateDbErrorDialog(e.toString()) ?? false;
  //       if (shouldRetry) {
  //         return _handleCreateNewYearDatabase(dbManager);
  //       }
  //     }
  //     return false;
  //   } finally {
  //     if (mounted) setState(() => _isCreatingNewDb = false);
  //   }
  // }

  Future<void> _showSecretMenu() async {
    final jsonContent = await ref
        .read(databaseProvider.notifier)
        .getSettingsJsonContent();
    if (!mounted) return;
    final isTablet = ResponsiveUtils.isTablet(context);
    final localizations = AppLocalizations.of(context);
    final logPath = AppLogger.logFilePath;
    final logs = AppLogger.recentLines.join('\n');
    final sectionStyle = TextStyle(
        fontSize: isTablet ? 18.0 : 16.0, fontWeight: FontWeight.bold);
    final monoStyle = TextStyle(
        fontFamily: 'monospace', fontSize: isTablet ? 14.0 : 12.0);

    showDialog(
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

  void _showSimpleErrorDialog(String message) {
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

    Future<YearChangeChoice?> _showYearChangeDialog() {
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

  // Future<YearChangeChoice?> _showYearChangeDialog() async {
  //   final localizations = AppLocalizations.of(context);
  //   final isTablet = ResponsiveUtils.isTablet(context);

  //   return showDialog<YearChangeChoice>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           localizations.yearChangeDetected,
  //           style: TextStyle(
  //             fontSize: isTablet ? 22.0 : 18.0,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         content: Text(
  //           localizations.yearChangeMessage,
  //           style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text(
  //               localizations.later,
  //               style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
  //             ),
  //             onPressed: () =>
  //                 Navigator.of(context).pop(YearChangeChoice.later),
  //           ),
  //           const SizedBox(height: 5),
  //           ElevatedButton(
  //             child: Text(
  //               localizations.createNewDatabase,
  //               style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
  //             ),
  //             onPressed: () =>
  //                 Navigator.of(context).pop(YearChangeChoice.create),
  //           ),
  //         ],
  //         contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
  //       );
  //     },
  //   );
  // }

  Future<bool?> _showCreateNewDbWarningDialog() {
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

  Future<bool?> _showCreateDbErrorDialog(String error) async {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return showDialog<bool>(
      context: context,
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


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupResult>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(context);
        }

        switch (snapshot.data) {
          case _StartupResult.needsSetup:
            return _buildSetupView(context);
          case _StartupResult.failed:
          case null:
            return _buildFailedView(context);
          case _StartupResult.ready:
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: const Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final iconSize = isTablet ? 130.0 : 100.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: FaIcon(FontAwesomeIcons.childReaching,
                  size: iconSize, color: Theme.of(context).primaryColor),
            ),
            SizedBox(height: isTablet ? 30 : 20),
            Text(AppLocalizations.of(context).attendly,
                style: TextStyle(
                    fontSize: isTablet ? 34 : 28,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: isTablet ? 40 : 30),
            SizedBox(
              width: isTablet ? 40 : 30,
              height: isTablet ? 40 : 30,
              child: CircularProgressIndicator(
                  strokeWidth: isTablet ? 4.0 : 3.0),
            ),
            SizedBox(height: isTablet ? 30 : 20),
            Text(AppLocalizations.of(context).initializing,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isTablet ? 20 : 16)),
          ],
        ),
      ),
    );
  }

  /// First launch: no database exists yet, so offer to create one.
  Widget _buildSetupView(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return _buildStatusScaffold(
      context,
      icon: FaIcon(FontAwesomeIcons.childReaching,
          size: isTablet ? 100 : 80, color: Theme.of(context).primaryColor),
      title: localizations.noDatabaseTitle,
      message: localizations.noDatabaseMessage,
      actions: [
        _buildCreateDbButton(context, localizations.createDatabase,
            () => _createNewDatabase()),
      ],
    );
  }

  /// Opening the default or a selected database failed.
  Widget _buildFailedView(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return _buildStatusScaffold(
      context,
      icon: Icon(Icons.error_outline, size: isTablet ? 100 : 80, color: Colors.red),
      title: localizations.databaseSwitchFailed,
      message: localizations.databaseOpenFailedMessage,
      details: _startupError?.toString(),
      actions: [
        ElevatedButton.icon(
          onPressed: _isCreatingNewDb ? null : _retryInitialization,
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
        _buildCreateDbButton(context, localizations.createNew,
            () => _createNewDatabase(withWarning: true)),
        if (widget.selectedDb != null)
          TextButton(
            onPressed: _isCreatingNewDb ? null : _openDefaultDatabase,
            child: Text(localizations.openDefaultDatabase,
                style: TextStyle(fontSize: isTablet ? 18 : 16)),
          ),
      ],
    );
  }

  Widget _buildStatusScaffold(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String message,
    String? details,
    required List<Widget> actions,
  }) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 30.0 : 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: () {
                  _longPressCounter++;
                  if (_longPressCounter >= 2) {
                    _showSecretMenu();
                    _longPressCounter = 0;
                  }
                },
                child: icon,
              ),
              SizedBox(height: isTablet ? 30 : 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                message,
                style: TextStyle(fontSize: isTablet ? 18 : 16),
                textAlign: TextAlign.center,
              ),
              if (details != null) ...[
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: isTablet ? 40 : 30),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: isTablet ? 20 : 12,
                runSpacing: isTablet ? 16 : 12,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateDbButton(BuildContext context, String label, VoidCallback onPressed) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return ElevatedButton.icon(
      onPressed: _isCreatingNewDb ? null : onPressed,
      label: _isCreatingNewDb
          ? SizedBox(
              height: isTablet ? 24 : 20,
              width: isTablet ? 24 : 20,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.white,
              ),
            ),
      icon: _isCreatingNewDb
          ? const SizedBox.shrink()
          : FaIcon(
              FontAwesomeIcons.database,
              size: isTablet ? 22 : 18,
              color: Colors.white
            ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 16 : 12,
        ),
      ),
    );
  }
}
