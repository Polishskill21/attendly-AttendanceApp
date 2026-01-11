import 'package:attendly/backend/helpers/db_result.dart';
import 'package:attendly/frontend/widgets/changelog_helper.dart';
import 'package:attendly/main_app.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attendly/backend/manager/db_data_manager.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/backend/global/global_var.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

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
    final isTablet = ResponsiveUtils.isTablet(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: isTablet ? 32 : 24),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Error',
              style: TextStyle(
                fontSize: isTablet ? 22.0 : 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context).ok,
              style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
            ),
          ),
        ],
        contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      ),
    );
  }

  Future<void> _showSecretMenu() async {
    final handler = await AnnualDataManager.create();
    final jsonContent = await handler.getSettingsJsonContent();
    final isTablet = ResponsiveUtils.isTablet(context);

    if (mounted) {
      final localizations = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'settings.json',
            style: TextStyle(
              fontSize: isTablet ? 22.0 : 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              jsonContent,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isTablet ? 16.0 : 14.0,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
              ),
            ),
          ],
          contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
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
            dbConnection = newDb;
          } else {
            showNewYearBanner = true;
          }
        } else { 
          showNewYearBanner = true;
        }
      }
    }

    if (dbConnection != null && mounted && !isTemporaryDb) {
      await ChangelogHelper.presentChangelogIfNew(context);
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
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return showDialog<YearChangeChoice>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            localizations.yearChangeDetected,
            style: TextStyle(
              fontSize: isTablet ? 22.0 : 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.yearChangeMessage,
            style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                localizations.later,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
              ),
              onPressed: () {
                Navigator.of(context).pop(YearChangeChoice.later);
              },
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              child: Text(
                localizations.createNewDatabase,
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
              ),
              onPressed: () async {
                Navigator.of(context).pop(YearChangeChoice.create);
              },
            ),
          ],
          contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
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
            onPressed: () {
              Navigator.of(context).pop(true);
            },
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final iconSize = isTablet ? 130.0 : 100.0;
    
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
                    child: FaIcon(
                      FontAwesomeIcons.childReaching, 
                      size: iconSize, 
                      color: Theme.of(context).primaryColor
                    ),
                  ),
                  SizedBox(height: isTablet ? 30 : 20),
                  Text(
                    AppLocalizations.of(context).attendly,
                    style: TextStyle(
                      fontSize: isTablet ? 34 : 28, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: isTablet ? 40 : 30),
                  SizedBox(
                    width: isTablet ? 40 : 30,
                    height: isTablet ? 40 : 30,
                    child: CircularProgressIndicator(
                      strokeWidth: isTablet ? 4.0 : 3.0,
                    ),
                  ),
                  SizedBox(height: isTablet ? 30 : 20),
                  Text(
                    AppLocalizations.of(context).initializing, 
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isTablet ? 20 : 16,
                    )
                  )
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
                          icon: Icon(Icons.refresh, color: Colors.white, size: isTablet ? 24 : 20),
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
                                  child: CircularProgressIndicator(
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
        return MainApp(dbConnection: snapshot.data!);
      },
    );
  }
}
