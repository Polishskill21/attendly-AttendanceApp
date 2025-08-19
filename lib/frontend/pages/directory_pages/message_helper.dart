import 'package:flutter/material.dart';
import 'package:attendly/frontend/person_model/person_logic_conversion.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
import 'package:attendly/frontend/widgets/error_dialog.dart';

class HelperAllPerson {

  Future<bool?> displayDialog(BuildContext context, String header, String message, AppLocalizations localizations) async{
    return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Text(header),
          content: Text(message, 
            style: TextStyle(
              fontSize: 16
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(localizations.delete),
            ),
          ],
        ),
      );
  }
  
  Future<void> showSubmitMessage(BuildContext context, String message) async {
    final localizations = AppLocalizations.of(context);
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
            size: 48,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
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

  void showResetMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
          message,
          textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Colors.grey,
        //floating means u can move it
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 10,
          left: 25,
          right: 25
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        ),
        elevation: 5.0,
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
                style: const TextStyle(fontSize: 16),
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

    try{
      return [
        Text(
          "${localizations.birthday}: $birthday ($age)",
          style: const TextStyle(fontSize: 20),
        ),
        Text(
          "${localizations.gender}: ${stringToStringGender(person['gender'], localizations)}",
          style: const TextStyle(fontSize: 20),
        ),
        Text(
          "${localizations.migration}: ${intToBool(person['migration'])}",
          style: TextStyle(fontSize: 20),
        ),
        if (person['migration'] == 1)
          Text(
            "${localizations.country}: ${person['migration_background'] ?? 'N/A'}",
            style: TextStyle(fontSize: 20),
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Flexible(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: SelectableText(
            message,
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK'),
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
      barrierDismissible: false, // User must not close it manually
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Disable back button
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
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