import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendly/frontend/pages/splash_screen/splash_screen.dart';
import 'package:attendly/frontend/pages/directory_pages/state_manager_dir_page.dart';
import 'package:attendly/localization/app_localizations.dart';

class DbConnectionValidator {
  static Future<bool> isConnectionValid(Database? db) async {
    if (db == null) return false;
    
    try {
      // Try a simple query to test if the database is still accessible
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      debugPrint('Database connection validation failed: $e');
      return false;
    }
  }

  static Future<void> handleConnectionError(BuildContext context, {String? customMessage}) async {
    if (!context.mounted) return;
    
    final localizations = AppLocalizations.of(context);
    
    // Clear the state manager before showing dialog
    StateManager.clearChildrenList();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(localizations.databaseConnectionLost),
              ),
            ],
          ),
          content: Text(
            customMessage ?? localizations.databaseConnectionErrorMessage,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _redirectToSplashScreen(context);
              },
              child: Text(localizations.ok),
            ),
          ],
        );
      },
    );
  }

  static void _redirectToSplashScreen(BuildContext context) {
    if (!context.mounted) return;
    
    // Clear the state manager before redirecting
    StateManager.clearChildrenList();
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => SplashScreen()),
      (route) => false,
    );
  }

  static Future<bool> validateAndHandle(BuildContext context, Database? db, {String? customMessage}) async {
    final isValid = await isConnectionValid(db);
    if (!isValid && context.mounted) {
      await handleConnectionError(context, customMessage: customMessage);
    }
    return isValid;
  }
}
