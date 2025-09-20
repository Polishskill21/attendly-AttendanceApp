import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/person_model/person_logic_conversion.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/widgets/error_dialog.dart';

class HelperAllPerson {
  Future<bool?> displayDialog(BuildContext context, String header, String message, AppLocalizations localizations) async {
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 8.0,
        title: Text(
          header,
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message, 
          style: TextStyle(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              localizations.cancel,
              style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
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
              style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> showSubmitMessage(BuildContext context, String message) async {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final textScale = ResponsiveUtils.getTextScaleFactor(context);
    
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
            size: ResponsiveUtils.getIconSize(context, baseSize: 56),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
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

  void showResetMessage(BuildContext context, String message) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final textScale = ResponsiveUtils.getTextScaleFactor(context);
    
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
                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 2),
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

  int _calculateAge(String? birthDateString) {
    if (birthDateString == null || birthDateString.isEmpty) {
      return 0;
    }
    try {
      final birthDate = DateTime.parse(birthDateString);
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

  List<Widget> buildPersonDetails(List<Map<String, dynamic>> data, int index, AppLocalizations localizations, BuildContext context) {
    final person = data[index];
    final birthday = person['birthday']?.toString() ?? 'N/A';
    final age = _calculateAge(person['birthday']?.toString());
    final isTablet = ResponsiveUtils.isTablet(context);
    final textScale = ResponsiveUtils.getTextScaleFactor(context);
    final fontSize = isTablet ? 22.0 * textScale : 20.0;

    try{
      return [
        Text(
          "• ${localizations.birthday}: $birthday ($age)",
          style: TextStyle(fontSize: fontSize),
        ),
        Text(
          "• ${localizations.gender}: ${stringToStringGender(person['gender'], localizations)}",
          style: TextStyle(fontSize: fontSize),
        ),
        Text(
          "• ${localizations.migration}: ${intToBool(person['migration'])}",
          style: TextStyle(fontSize: fontSize),
        ),
        if (person['migration'] == 1)
          Text(
            "• ${localizations.country}: ${person['migration_background'] ?? 'N/A'}",
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
        final iconSize = ResponsiveUtils.getIconSize(context, baseSize: 30);
        final gap = ResponsiveUtils.getListPadding(context).horizontal / 2;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: iconSize),
              SizedBox(width: gap),
              Flexible(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context)))),
            ],
          ),
          content: SelectableText(
            message,
            style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK', style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 2)),
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
        final gap = ResponsiveUtils.getListPadding(context).horizontal / 2;
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
                    style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
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