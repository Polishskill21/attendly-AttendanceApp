import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/widgets/error_dialog.dart';
import 'package:flutter/material.dart';

/// The app's standard dialogs and snackbars.
abstract final class AppDialogs {
  /// Asks before a destructive action. True when the user confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 8.0,
        title: Text(
          title,
          style: TextStyle(
            fontSize: responsive.titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              localizations.cancel,
              style: TextStyle(fontSize: responsive.bodyFontSize - 4),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20.0 : 16.0,
                vertical: isTablet ? 12.0 : 8.0,
              ),
            ),
            child: Text(
              localizations.delete,
              style: TextStyle(fontSize: responsive.bodyFontSize - 4),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Green check mark with [message]; completes when the user taps OK.
  static Future<void> showSuccess(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: responsive.iconSize(baseSize: 56),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.0 : 16.0,
                  vertical: isTablet ? 12.0 : 8.0,
                ),
              ),
              child: Text(
                localizations.ok,
                style: TextStyle(fontSize: isTablet ? 20.0 * responsive.textScaleFactor : 16.0),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Blue info icon with [message]; completes when the user taps OK.
  static Future<void> showInfo(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: responsive.iconSize(baseSize: 56),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localizations.ok,
                style: TextStyle(fontSize: isTablet ? 20.0 * responsive.textScaleFactor : 16.0),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Short grey snackbar, e.g. "All fields reset".
  static void showSnack(BuildContext context, String message) {
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 24.0 * responsive.textScaleFactor : 20.0,
            ),
          ),
        ),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: isTablet ? 16.0 : 10.0,
          left: isTablet ? 40.0 : 25.0,
          right: isTablet ? 40.0 : 25.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 16.0 : 10.0),
        ),
        elevation: isTablet ? 6.0 : 5.0,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  /// Error dialog. With a [stackTrace] it shows the "contact the creator"
  /// dialog with copyable details. Every error shown is logged.
  static void showError(BuildContext context, String? message, {StackTrace? stackTrace}) {
    AppLogger.e('UI', 'Error dialog shown: ${message ?? 'unknown error'}', null, stackTrace);
    final localizations = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        if (stackTrace != null) {
          return ErrorDialog(
            title: localizations.unexpectedErrorContactCreator,
            content: localizations.errorDialogContent,
            error: message ?? localizations.unknownError,
            stackTrace: stackTrace,
          );
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  localizations.errorOccurred,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                message ?? localizations.unknownError,
                style: TextStyle(fontSize: Responsive.of(context).bodyFontSize - 2),
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(localizations.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Non-dismissible progress dialog; close it with [hideLoading].
  static void showLoading(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final gap = Responsive.of(context).listPadding.horizontal / 2;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                SizedBox(width: gap),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hideLoading(BuildContext context) {
    // Ensure the dialog is on the context stack before trying to pop.
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
