import 'dart:io';

import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:attendly/data/local/database.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/pages/settings_page/help_page.dart';
import 'package:attendly/frontend/widgets/changelog_helper.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/frontend/pages/settings_page/settings_provider.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/pages/settings_page/debug_menu.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    final isTablet = ResponsiveUtils.isTablet(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => HelpPage(isTablet: isTablet)),
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
          title: Text(
            localizations.confirmAction,
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.recalibrateConfirm,
            style: TextStyle(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                localizations.cancel,
                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                localizations.proceed,
                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
              ),
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
    final iconSize = ResponsiveUtils.getIconSize(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.settings,
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: iconSize),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return ListView(
              children: [
                _buildSettingsListTile(
                  title: localizations.darkMode,
                  subtitle: localizations.enableDisableDarkTheme,
                  icon: Icons.dark_mode_outlined,
                  trailing: Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      settings
                          .updateTheme(value ? ThemeMode.dark : ThemeMode.light);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? localizations.darkModeOn : localizations.darkModeOff,
                            style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsListTile(
                  title: localizations.language,
                  subtitle: localizations.selectApplicationLanguage,
                  icon: Icons.language_outlined,
                  trailing: DropdownButton<String>(
                    value: settings.locale.languageCode == 'de'
                        ? localizations.german
                        : localizations.english,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    iconSize: ResponsiveUtils.getIconSize(context),
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
                                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
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
                        child: Text(
                          value,
                          style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsListTile(
                  title: localizations.recalibrateData,
                  subtitle: localizations.recalibrateDataDesc,
                  icon: Icons.calculate_outlined,
                  trailing: Icon(Icons.chevron_right, size: ResponsiveUtils.getIconSize(context)),
                  onTap: _showRecalibrationDialog,
                ),
                const Divider(height: 1),
                _buildSettingsListTile(
                  title: localizations.help,
                  subtitle: localizations.openUserManual,
                  icon: Icons.help_outline,
                  trailing: Icon(Icons.chevron_right, size: ResponsiveUtils.getIconSize(context)),
                  onTap: _openHelpPage,
                ),
                const Divider(height: 1),
                Padding(
                  padding: ResponsiveUtils.getContentPadding(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.debugInformation,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onLongPress: _openDebugMenu,
                        child: Icon(
                          Icons.info_outline, 
                          color: Colors.grey,
                          size: ResponsiveUtils.getIconSize(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: ResponsiveUtils.getContentPadding(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {

                            String versionText = snapshot.hasData 
                                ? snapshot.data!.version 
                                : "...";
                                
                            // return Text(
                            //   localizations.getAppsVerision(versionText),
                            //   textAlign: TextAlign.center,
                            //   style: TextStyle(
                            //     fontSize: ResponsiveUtils.getBodyFontSize(context),
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.grey,
                            //   ),
                            // );
                            return InkWell(
                              onTap: () => ChangelogHelper.showDirectly(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  localizations.getAppsVerision(versionText),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsListTile(
                  title: "Test 2025 Migration",
                  subtitle: "Verify db_2025.db conversion logic",
                  icon: Icons.auto_fix_high_outlined,
                  trailing: Icon(Icons.play_arrow, color: Colors.green, size: ResponsiveUtils.getIconSize(context)),
                  onTap: _runMigrationTest,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _runMigrationTest() async {
    final helper = HelperAllPerson();
    
    helper.showLoadingDialog(context, "Testing Migration...");

    try {
      // 1. Get the path to your db_2025.db file
      final dir = await StorageManager.getExternalDirectory(); 
      final file = File(p.join(dir!.path, 'db_2025.db'));

      if (!await file.exists()) {
        throw Exception("File db_2025.db not found in documents directory.");
      }

      // 2. Open a separate connection to run the migration
      final executor = AppDatabase.createExecutor(file);
      final testDb = AppDatabase(executor);

      // 3. Force open triggers the MigrationStrategy
      await testDb.forceOpen();

      // 4. Verify data can be read
      final people = await testDb.readDao.getAllPeople();
      final dailyResults = await testDb.readDao.getPeopleFromCurrentDay(DateTime(2025, 09, 25));
      debugPrint("Daily Entries for 2025-09-25: ${dailyResults.length}");

      final weeklyEntry = await testDb.readDao.getWeeklyEntryByDate(DateTime(2025, 09, 22));
      debugPrint("Weekly Entry for 2025-09-22 found: ${weeklyEntry?.age_10_13 ?? "null"}");
      // 5. Clean up
      await testDb.close();
      
      if (mounted) {
        helper.hideLoadingDialog(context);
        helper.showSubmitMessage(context, "Migration Success! Read ${people.length} people.");
      }
    } catch (e, stack) {
      if (mounted) {
        helper.hideLoadingDialog(context);
        helper.showErrorMessage(context, "Migration Test Failed", stackTrace: stack);
      }
    }
  }

  Widget _buildSettingsListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    
    return ListTile(
      contentPadding: ResponsiveUtils.getContentPadding(context),
      leading: Icon(icon, size: ResponsiveUtils.getIconSize(context)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getBodyFontSize(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}