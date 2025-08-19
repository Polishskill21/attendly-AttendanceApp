import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/pages/settings_page/help_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/frontend/pages/settings_page/settings_provider.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
import 'package:attendly/frontend/pages/settings_page/debug_menu.dart';
import 'package:sqflite/sqflite.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // late DbUpdater updater;
  // late DbInsertion inserter;
  // late DbSelection reader;
  // Database? db;
  // late HelperAllPerson _helper;

  @override
  void initState() {
    super.initState();
  }

  void _openDebugMenu() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DebugMenu()),
    );
  }

  void _openHelpPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HelpPage()),
    );
  }

  void _showRecalibrationDialog() async {
    final localizations = AppLocalizations.of(context);

    HelperAllPerson helper = HelperAllPerson();
    Database? db = DBConnectionManager.db;

    late DbSelection reader;
    late DbUpdater updater;
    late DbInsertion inserter;

    if (db != null) {
      reader = DbSelection(db);
      updater = DbUpdater(db, reader);
      inserter = DbInsertion(db, reader, updater);
    }

    if (db == null || !db.isOpen) {
      helper.showErrorMessage(context, localizations.databaseNotConnected);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.confirmAction),
          content: Text(localizations.recalibrateConfirm),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(localizations.proceed),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (mounted && confirmed == true) {
      helper.showLoadingDialog(context, localizations.recalibrating);

      try {
        await updater.recalibrateWeeklyData(inserter);

        if (mounted) {
          helper.hideLoadingDialog(context);
          await helper.showSubmitMessage(
              context, localizations.recalibrationSuccess);
        }
      } catch (e, stackTrace) {
        if (mounted) {
          helper.hideLoadingDialog(context);
          helper.showErrorMessage(
              context, localizations.recalibrationFailed, stackTrace: stackTrace);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.settings),
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return ListView(
              padding: EdgeInsets.only(
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                SwitchListTile(
                  title: Text(localizations.darkMode),
                  subtitle: Text(localizations.enableDisableDarkTheme),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    settings
                        .updateTheme(value ? ThemeMode.dark : ThemeMode.light);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? localizations.darkModeOn
                            : localizations.darkModeOff),
                      ),
                    );
                  },
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(localizations.language),
                  subtitle: Text(localizations.selectApplicationLanguage),
                  trailing: DropdownButton<String>(
                    value: settings.locale.languageCode == 'de'
                        ? localizations.german
                        : localizations.english,
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        if (newValue == localizations.german) {
                          settings.updateLocale(const Locale('de'));
                        } else {
                          settings.updateLocale(const Locale('en'));
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final newLocalizations = AppLocalizations.of(context);
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${newLocalizations.languageSetTo} $newValue. ${newLocalizations.appRestartRequired}',
                              ),
                            ),
                          );
                        });
                      }
                    },
                    items: [localizations.english, localizations.german]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(localizations.recalibrateData),
                  subtitle: Text(localizations.recalibrateDataDesc),
                  onTap: _showRecalibrationDialog,
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(localizations.help),
                  subtitle: Text(localizations.openUserManual),
                  onTap: _openHelpPage,
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.debugInformation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onLongPress: _openDebugMenu,
                        child:
                            const Icon(Icons.info_outline, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

//import 'package:attendly/backend/dbLogic/db_insert.dart';
//import 'package:attendly/backend/dbLogic/db_read.dart';
//import 'package:attendly/backend/dbLogic/db_update.dart';
//import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
//import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import 'package:attendly/backend/manager/connection_manager.dart';
//import 'package:attendly/frontend/pages/settings_page/settings_provider.dart';
//import 'package:attendly/frontend/l10n/app_localizations.dart';
//import 'package:attendly/frontend/pages/settings_page/debug_menu.dart';
//import 'package:sqflite/sqflite.dart';

//class SettingsPage extends StatefulWidget {
  //const SettingsPage({super.key});

  //@override
  //State<StatefulWidget> createState() => _SettingsPageState();
//}

//class _SettingsPageState extends State<SettingsPage> {
  //// late DbUpdater updater;
  //// late DbInsertion inserter;
  //// late DbSelection reader;
  //// Database? db;
  //// late HelperAllPerson _helper;

  //@override
  //void initState() {
    //super.initState();

  //}

  //void _openDebugMenu() {
    //Navigator.of(context).push(
      //MaterialPageRoute(builder: (context) => const DebugMenu()),
    //);
  //}

  //void _showRecalibrationDialog() async {
    //final localizations = AppLocalizations.of(context);

    //HelperAllPerson helper = HelperAllPerson();
    //Database? db = DBConnectionManager.db;

    //late DbSelection reader;
    //late DbUpdater updater;
    //late DbInsertion inserter;

    //if (db != null) {
      //reader = DbSelection(db);
      //updater = DbUpdater(db, reader);
      //inserter = DbInsertion(db, reader, updater);
    //}

    //if (db == null || !db.isOpen) {
      //helper.showErrorMessage(context, localizations.databaseNotConnected);
      //return;
    //}

    //final confirmed = await showDialog<bool>(
      //context: context,
      //builder: (BuildContext context) {
        //return AlertDialog(
          //title: Text(localizations.confirmAction),
          //content: Text(localizations.recalibrateConfirm),
          //actions: <Widget>[
            //TextButton(
              //child: Text(localizations.cancel),
              //onPressed: () => Navigator.of(context).pop(false),
            //),
            //TextButton(
              //style: TextButton.styleFrom(
                //foregroundColor: Theme.of(context).colorScheme.error,
              //),
              //child: Text(localizations.proceed),
              //onPressed: () => Navigator.of(context).pop(true),
            //),
          //],
        //);
      //},
    //);

    //if (mounted && confirmed == true) {
      //helper.showLoadingDialog(context, localizations.recalibrating);



      //try {
        //await updater.recalibrateWeeklyData(inserter);

        //if (mounted) {
          //helper.hideLoadingDialog(context);
          //await helper.showSubmitMessage(
              //context, localizations.recalibrationSuccess);
        //}
      //} catch (e) {
        //if (mounted) {
          //helper.hideLoadingDialog(context);
          //helper.showErrorMessage(
              //context, '${localizations.recalibrationFailed}: $e');
        //}
      //}
    //}
  //}

  //@override
  //Widget build(BuildContext context) {
    //final localizations = AppLocalizations.of(context);
   
    //return PopScope(
      //onPopInvokedWithResult: (didPop, result) {
        //ScaffoldMessenger.of(context).hideCurrentSnackBar();
      //},
      //child: Scaffold(
        //appBar: AppBar(
          //title: Text(localizations.settings),
        //),
        //body: Consumer<SettingsProvider>(
          //builder: (context, settings, child) {
            //return ListView(
              //padding: const EdgeInsets.symmetric(vertical: 16.0),
              //children: [
                //SwitchListTile(
                  //title: Text(localizations.darkMode),
                  //subtitle: Text(localizations.enableDisableDarkTheme),
                  //value: settings.themeMode == ThemeMode.dark,
                  //onChanged: (bool value) {
                    //settings.updateTheme(value ? ThemeMode.dark : ThemeMode.light);
                     //ScaffoldMessenger.of(context).clearSnackBars();
                     //ScaffoldMessenger.of(context).showSnackBar(
                       //SnackBar(
                         //content: Text(value ? localizations.darkModeOn : localizations.darkModeOff),
                       //),
                     //);
                  //},
                  //secondary: const Icon(Icons.dark_mode_outlined),
                //),
                //const Divider(),
                //ListTile(
                  //leading: const Icon(Icons.language_outlined),
                  //title: Text(localizations.language),
                  //subtitle: Text(localizations.selectApplicationLanguage),
                  //trailing: DropdownButton<String>(
                    //value: settings.locale.languageCode == 'de' ? localizations.german : localizations.english,
                    //underline: const SizedBox(),
                    //onChanged: (String? newValue) {
                      //if (newValue != null) {
                        //if (newValue == localizations.german) {
                          //settings.updateLocale(const Locale('de'));
                        //} else {
                          //settings.updateLocale(const Locale('en'));
                        //}
                        //WidgetsBinding.instance.addPostFrameCallback((_) {
                          //final newLocalizations = AppLocalizations.of(context);
                          //ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          //ScaffoldMessenger.of(context).showSnackBar(
                            //SnackBar(
                              //content: Text(
                                //'${newLocalizations.languageSetTo} $newValue. ${newLocalizations.appRestartRequired}',
                              //),
                            //),
                          //);
                        //});
                      //}
                    //},
                    //items: [localizations.english, localizations.german]
                        //.map<DropdownMenuItem<String>>((String value) {
                      //return DropdownMenuItem<String>(
                        //value: value,
                        //child: Text(value),
                      //);
                    //}).toList(),
                  //),
                //),
                //const Divider(),
                //ListTile(
                  //leading: const Icon(Icons.calculate_outlined),
                  //title: Text(localizations.recalibrateData),
                  //subtitle: Text(localizations.recalibrateDataDesc),
                  //onTap: _showRecalibrationDialog,
                  //trailing: const Icon(Icons.chevron_right),
                //),
                //const Divider(),
                //GestureDetector(
                  //onLongPress: _openDebugMenu,
                  //child: Padding(
                    //padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    //child: Text(
                      //localizations.debugInformation,
                      //style: const TextStyle(
                        //fontSize: 16,
                        //fontWeight: FontWeight.bold,
                        //color: Colors.grey,
                      //),
                    //),
                  //),
                //),
                //ListTile(
                  //leading: const Icon(Icons.storage_outlined),
                  //title: Text(localizations.databasePath),
                  //subtitle: Text(
                    //DBConnectionManager.filePath ?? localizations.notAvailable,
                    //style: const TextStyle(fontSize: 12),
                  //),
                //),
                //ListTile(
                  //leading: Icon(
                    //DBConnectionManager.db?.isOpen ?? false ? Icons.check_circle_outline : Icons.error_outline,
                    //color: DBConnectionManager.db?.isOpen ?? false ? Colors.green : Colors.red,
                  //),
                  //title: Text(localizations.connectionStatus),
                  //subtitle: Text(DBConnectionManager.db?.isOpen ?? false ? localizations.connected : localizations.disconnected),
                //),
              //],
            //);
          //},
        //),
      //),
    //);
  //}
//}