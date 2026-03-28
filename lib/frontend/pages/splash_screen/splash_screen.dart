import 'dart:io';
import 'package:attendly/frontend/widgets/changelog_helper.dart';
import 'package:attendly/frontend/widgets/migration_dialog.dart';
import 'package:attendly/main_app.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';


enum YearChangeChoice { create, later }

class SplashScreen extends ConsumerStatefulWidget {
  final File? selectedDb;
  final Object? dbError;
  
  const SplashScreen({super.key, this.selectedDb, this.dbError});
 
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late Future<bool> _dbFuture;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _longPressCounter = 0;
  bool _isCreatingNewDb = false;

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
    _dbFuture = _initializeApp();
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

  Future<bool> _initializeApp() async {
    final results = await Future.wait([
      _initializeDatabase(),
      Future.delayed(const Duration(milliseconds: 1300)),
    ]);
    
    final dbSuccess = results[0] as bool;

    if (!dbSuccess) return false;

    if (mounted && !ref.read(databaseManagerProvider).isTemporaryDb) {
      await ChangelogHelper.presentChangelogIfNew(context);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainApp()),
      );
    }
    
    return true;
  }

  Future<bool> _initializeDatabase() async {
    final notifier = ref.read(databaseManagerProvider.notifier);

    if (widget.dbError != null) return false;

    try {
      // ── Case A: user picked a specific DB file from the list ───────────────
      if (widget.selectedDb != null) {
        await notifier.openDatabase(file: widget.selectedDb, onMigrationStarted: _onSchemaMigrationStarted);
        return true;
      }
 
      // ── Case B: normal startup ─────────────────────────────────────────────
      final rolloverNeeded = await notifier.checkForYearRollover();
 
      if (rolloverNeeded && mounted) {
        final choice = await _showYearChangeDialog();
 
        if (choice == YearChangeChoice.create) {
          await _handleYearRollover();
        } else {
          // User chose to stay on the old DB for now — open it with banner
          await notifier.openDatabaseWithBanner(onMigrationStarted: _onSchemaMigrationStarted);
        }
      } else {
        await notifier.openDatabase(onMigrationStarted: _onSchemaMigrationStarted);
      }
 
      return true;
    } catch (e) {
      debugPrint("Database init failed: $e");
      return false;
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
  //     ref.read(databaseManagerProvider.notifier).setDatabase(
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
    if (widget.dbError != null) {
      
      ref.read(databaseManagerProvider.notifier).closeDatabase();
      return;
    }
    setState(() => _dbFuture = _initializeApp());
  }

  
  void _createNewDatabase() async {
    if (_isCreatingNewDb) return;
    setState(() => _isCreatingNewDb = true);
 
    try {
      await ref.read(databaseManagerProvider.notifier).createDatabase();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainApp()),
        );
      }
    } catch (e) {
      debugPrint("Error creating new DB: $e");
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
  //     final IDatabaseManager dbManager = DatabaseManager();
  //     await dbManager.createDatabase();

  //     if (mounted) {
  //       ref.read(databaseManagerNotifierProvider.notifier).setDatabase(
  //         manager,
  //         isTemporary: isTemporaryDb,
  //         showBanner: showNewYearBanner,
  //       );
  //       Navigator.of(context).pushReplacement(
  //         MaterialPageRoute(builder: (_) => const MainApp()),
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
  //         .read(databaseManagerProvider.notifier)
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
  //         await ref.read(databaseManagerProvider.notifier).openDatabaseWithBanner();
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
          .read(databaseManagerProvider.notifier)
          .performYearRolloverAndOpen();
      await safeCloseDialog(); 
      
    } catch (e) {
      await safeCloseDialog(); 
      
      if (mounted) {
        final retry = await _showCreateDbErrorDialog(e.toString()) ?? false;
        if (retry) {
          return _handleYearRollover();
        }
        try {
          await ref.read(databaseManagerProvider.notifier).openDatabaseWithBanner();
        } catch (_) {
          rethrow;
        }
      }
    } finally {
      await safeCloseDialog(); 
      if (mounted) setState(() => _isCreatingNewDb = false);
    }
  }

  // Future<bool> _handleCreateNewYearDatabase(IDatabaseManager dbManager) async {
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
        .read(databaseManagerProvider.notifier)
        .getSettingsJsonContent();
    final isTablet = ResponsiveUtils.isTablet(context);
    if (!mounted) return;
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.json',
            style: TextStyle(
                fontSize: isTablet ? 22.0 : 18.0,
                fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(jsonContent,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: isTablet ? 16.0 : 14.0)),
        ),
        actions: [
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
    final isTablet = ResponsiveUtils.isTablet(context);
    final iconSize = isTablet ? 130.0 : 100.0;
    
    return FutureBuilder<bool>(
      future: _dbFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        // If DB failed to open
        if (snapshot.data == null || snapshot.data == false) {
          final localizations = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
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
                      child: Icon(
                        Icons.error_outline,
                        size: isTablet ? 100 : 80,
                        color: Colors.red
                      ),
                    ),
                    SizedBox(height: isTablet ? 30 : 20),
                    Text(
                      localizations.databaseSwitchFailed,
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 40 : 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _retryInitialization,
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
                        SizedBox(width: isTablet ? 20 : 12),
                        ElevatedButton.icon(
                          onPressed: _isCreatingNewDb ? null : _createNewDatabase,
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
                                  localizations.createNew,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (!mounted) return;
        //   Navigator.of(context).pushReplacement(
        //     MaterialPageRoute(builder: (_) => const MainApp()),
        //   );
        // });
 
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}