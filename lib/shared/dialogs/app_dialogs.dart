import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/widgets/error_dialog.dart';
import 'package:intl/intl.dart';

class AppDialogs {
  Future<bool?> displayDialog(BuildContext context, String header, String message, AppLocalizations localizations) async {
    final isTablet = Responsive.of(context).isTablet;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 8.0,
        title: Text(
          header,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message, 
          style: TextStyle(
            fontSize: Responsive.of(context).bodyFontSize,
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              localizations.cancel,
              style: TextStyle(fontSize: Responsive.of(context).bodyFontSize - 4),
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
              style: TextStyle(fontSize: Responsive.of(context).bodyFontSize - 4),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> showSubmitMessage(BuildContext context, String message) async {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final textScale = Responsive.of(context).textScaleFactor;
    
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
            size: Responsive.of(context).iconSize(baseSize: 56),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.of(context).bodyFontSize,
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
                style: TextStyle(fontSize: isTablet ? 20.0 * textScale : 16.0),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showInfoMessageDialog(BuildContext context, String message) async {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final textScale = Responsive.of(context).textScaleFactor;

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
            size: Responsive.of(context).iconSize(baseSize: 56),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.of(context).bodyFontSize,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localizations.ok,
                style: TextStyle(fontSize: isTablet ? 20.0 * textScale : 16.0),
              ),
            ),
          ],
        );
      },
    );
  }

  void showResetMessage(BuildContext context, String message) {
    final isTablet = Responsive.of(context).isTablet;
    final textScale = Responsive.of(context).textScaleFactor;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 24.0 * textScale : 20.0,
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
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  void showErrorMessage(BuildContext context, String? message, {StackTrace? stackTrace}) {
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

  int _calculateAge(DateTime birthDate) {
    try {
      final today = DateTime.now();
      var age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? age : 0;
    } catch (e) {
      return 0;
    }
  }

  List<Widget> buildPersonDetails(List<DirectoryPeopleData> data, int index, AppLocalizations localizations, BuildContext context) {
    final person = data[index];
    final displayBirthday = person.birthday;
    final displayBirthdayFormated = DateFormat('dd.MM.yyyy').format(displayBirthday);

    final age = _calculateAge(displayBirthday);
    final isTablet = Responsive.of(context).isTablet;
    final textScale = Responsive.of(context).textScaleFactor;
    final fontSize = isTablet ? 22.0 * textScale : 20.0;

    try{
      return [
        Text(
          "• ${localizations.birthday}: $displayBirthdayFormated ($age)",
          style: TextStyle(fontSize: fontSize),
        ),
        Text(
          "• ${localizations.gender}: ${person.gender.localizedName(localizations)}",
          style: TextStyle(fontSize: fontSize),
        ),
        Text(
          "• ${localizations.migration}: ${person.migration ? localizations.trueValue : localizations.falseValue}",
          style: TextStyle(fontSize: fontSize),
        ),
        if (person.migration)
          Text(
            "• ${localizations.country}: ${person.migrationBackground ?? 'N/A'}",
            style: TextStyle(fontSize: fontSize),
          ),
      ];
    }
    catch(e){
      showErrorMessage(context, e.toString());
      return [];
    }
  }

  Future<void> showDatabaseErrorDialog(BuildContext context, String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final iconSize = Responsive.of(context).iconSize(baseSize: 30);
        final gap = Responsive.of(context).listPadding.horizontal / 2;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: iconSize),
              SizedBox(width: gap),
              Flexible(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.of(context).bodyFontSize))),
            ],
          ),
          content: SelectableText(
            message,
            style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK', style: TextStyle(fontSize: Responsive.of(context).bodyFontSize - 2)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showLoadingDialog(BuildContext context, String message) async {
    return showDialog<void>(
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

  void hideLoadingDialog(BuildContext context) {
    // Ensure the dialog is on the context stack before trying to pop.
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
