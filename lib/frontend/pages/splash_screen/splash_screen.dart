import 'package:attendly/backend/helpers/db_result.dart';
import 'package:attendly/main_app.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attendly/backend/manager/db_data_manager.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
import 'package:attendly/backend/global/global_var.dart';

enum YearChangeChoice { create, later }

class SplashScreen extends StatefulWidget {
  final String? selectedDbPath;

  const SplashScreen({super.key, this.selectedDbPath});

  @override
  State<StatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late Future<Database?> _dbFuture;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _longPressCounter = 0;
  bool _isCreatingNewDb = false;

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

  Future<Database?> _initializeApp() async {
    // Create the database initialization future
    Future<Database?> dbInitFuture = _initializeDatabase();
    
    // Create the minimum wait time future
    Future<void> minWaitFuture = Future.delayed(const Duration(milliseconds: 1500));
    
    final results = await Future.wait([dbInitFuture, minWaitFuture]);
    
    return results[0] as Database?;
  }

  void _retryInitialization() {
    setState(() {
      _dbFuture = _initializeApp();
    });
  }

  void _createNewDatabase() async {
    if (_isCreatingNewDb) return;

    setState(() {
      _isCreatingNewDb = true;
    });

    try {
      final localizations = AppLocalizations.of(context);
      AnnualDataManager dbHandler = await AnnualDataManager.create();
      Database? database = await dbHandler.createDBInstance();

      if (database != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainApp(dbConnection: database),
          ),
        );
      } else if (mounted) {
        _showSimpleErrorDialog(localizations.failedToCreateNewDatabase);
      }
    } catch (e) {
      debugPrint("Error creating new DB: $e");
      if (mounted) {
        _showSimpleErrorDialog(AppLocalizations.of(context).failedToCreateNewDatabase);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingNewDb = false;
        });
      }
    }
  }

  void _showSimpleErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showSecretMenu() async {
    final handler = await AnnualDataManager.create();
    final jsonContent = await handler.getSettingsJsonContent();

    if (mounted) {
      final localizations = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('settings.json'),
          content: SingleChildScrollView(
            child: Text(
              jsonContent,
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
          ],
        ),
      );
    }
  }

  Future<Database?> _initializeDatabase() async {
    AnnualDataManager fileHandler = await AnnualDataManager.create();
    Database? dbConnection;

    if (widget.selectedDbPath != null) {
      dbConnection = await fileHandler.openSpecificDBInstance(widget.selectedDbPath!);
      showNewYearBanner = false;
      isTemporaryDb = true;
    } else {
      isTemporaryDb = false;
      DbInitResult result = await fileHandler.returnDBInstance();
      dbConnection = result.db;

      if (result.yearChangeDetected && mounted) {
        final choice = await _showYearChangeDialog();

        if (choice == YearChangeChoice.create) {
          final newDb = await _handleCreateNewYearDatabase(result.oldDbPath!);

          if (newDb != null) {
            return newDb;
          } else {
            showNewYearBanner = true;
          }
        } else { 
          showNewYearBanner = true;
        }
      }
    }

    if (dbConnection == null) {
      debugPrint("Database does not exist, or could not be opened.");
    } else {
      debugPrint("Database successfully opened.");
    }

    return dbConnection;
  }

  Future<YearChangeChoice?> _showYearChangeDialog() async {
    final localizations = AppLocalizations.of(context);
    return showDialog<YearChangeChoice>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.yearChangeDetected),
          content: Text(localizations.yearChangeMessage),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.later),
              onPressed: () {
                Navigator.of(context).pop(YearChangeChoice.later);
              },
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              child: Text(localizations.createNewDatabase),
              onPressed: () async {
                Navigator.of(context).pop(YearChangeChoice.create);
              },
            ),
          ],
        );
      },
    );
  }

 Future<Database?> _handleCreateNewYearDatabase(String oldDbPath) async {
    setState(() {
      _isCreatingNewDb = true;
    });
    try {
      AnnualDataManager dbHandler = await AnnualDataManager.create();
      Database? database = await dbHandler.createDBInstance(oldDbPath: oldDbPath);

      if (mounted) {
        if (database != null) {
          setState(() {
            showNewYearBanner = false;
          });
          // Return the created database instead of navigating
          return database;
        } else {
          _showSimpleErrorDialog(AppLocalizations.of(context).failedToCreateNewDatabase);
          // Return null on failure
          return null;
        }
      }
    } catch (e) {
      if (mounted) {
        // Ask the user if they want to retry
        final bool shouldRetry = await _showCreateDbErrorDialog(e.toString(), oldDbPath) ?? false;
        if (shouldRetry) {
          // If they retry, call this function again and return its result
          return _handleCreateNewYearDatabase(oldDbPath);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingNewDb = false;
        });
      }
    }
    // Return null if the process fails or is cancelled
    return null;
  }

  Future<bool?> _showCreateDbErrorDialog(String error, String oldDbPath) async {
    final localizations = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.errorOccurred),
        content: SingleChildScrollView(
          child: Text(
            '${localizations.failedToCreateNewDatabase}:\n\n$error',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(localizations.retry),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Database?>(
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
                    child: FaIcon(FontAwesomeIcons.childReaching, size: 100, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context).attendly,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context).initializing, style: TextStyle(color: Colors.grey.shade600))
                ],
              ),
            ),
          );
        }

        // If DB failed to open
        if (snapshot.data == null) {
          final localizations = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                      child: Icon(Icons.error_outline, size: 80, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.databaseSwitchFailed,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _retryInitialization,
                          label: Text(localizations.retry),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isCreatingNewDb ? null : _createNewDatabase,
                          label: _isCreatingNewDb
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(localizations.createNew),
                          icon: _isCreatingNewDb
                              ? const SizedBox.shrink()
                              : const FaIcon(FontAwesomeIcons.database, size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return MainApp(dbConnection: snapshot.data!);
      },
    );
  }
}
