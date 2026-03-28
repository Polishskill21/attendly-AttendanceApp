import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/pages/settings_page/help_page.dart';
import 'package:attendly/frontend/pages/settings_page/settings_notifier.dart';
import 'package:attendly/frontend/widgets/changelog_helper.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/pages/settings_page/debug_menu.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class SettingsPage extends ConsumerWidget  {
  const SettingsPage({super.key});
  
  // void _showRecalibrationDialog() async {
  //   final localizations = AppLocalizations.of(context);

  //   HelperAllPerson helper = HelperAllPerson();
  //   final appState = context.read<AppState>();

  //   if (!appState.isReady) {
  //     helper.showErrorMessage(context, localizations.databaseNotConnected);
  //     return;
  //   }

  //   final db = appState.dbManager!.databaseConnection;

  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           localizations.confirmAction,
  //           style: TextStyle(
  //             fontSize: ResponsiveUtils.getTitleFontSize(context),
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         content: Text(
  //           localizations.recalibrateConfirm,
  //           style: TextStyle(
  //             fontSize: ResponsiveUtils.getBodyFontSize(context),
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text(
  //               localizations.cancel,
  //               style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
  //             ),
  //             onPressed: () => Navigator.of(context).pop(false),
  //           ),
  //           TextButton(
  //             style: TextButton.styleFrom(
  //               foregroundColor: Theme.of(context).colorScheme.error,
  //             ),
  //             child: Text(
  //               localizations.proceed,
  //               style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
  //             ),
  //             onPressed: () => Navigator.of(context).pop(true),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (mounted && confirmed == true) {
  //     helper.showLoadingDialog(context, localizations.recalibrating);

  //     try {
  //       await db.updateDao.recalibrateWeeklyData();

  //       if (mounted) {
  //         helper.hideLoadingDialog(context);
  //         await helper.showSubmitMessage(
  //             context, localizations.recalibrationSuccess);
  //       }
  //     } catch (e, stackTrace) {
  //       if (mounted) {
  //         helper.hideLoadingDialog(context);
  //         helper.showErrorMessage(context, localizations.recalibrationFailed,
  //             stackTrace: stackTrace);
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final settings = ref.watch(settingsProvider);

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
        body: ListView(
              children: [
                _buildSettingsListTile(
                  context: context,
                  title: localizations.darkMode,
                  subtitle: localizations.enableDisableDarkTheme,
                  icon: Icons.dark_mode_outlined,
                  trailing: Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).updateTheme(value ? ThemeMode.dark : ThemeMode.light);
                      ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
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
                  context: context,
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
                      if (newValue == null) return;
                      final locale = newValue == localizations.german
                        ? const Locale('de')
                        : const Locale('en');
                      ref.read(settingsProvider.notifier).updateLocale(locale);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final newLoc = AppLocalizations.of(context);
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text(
                              '${newLoc.languageSetTo} $newValue. ${newLoc.appRestartRequired}',
                              style: TextStyle(
                                  fontSize: ResponsiveUtils.getBodyFontSize(context)),
                            ),
                          ));
                      });
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
                  context: context,
                  title: localizations.recalibrateData,
                  subtitle: localizations.recalibrateDataDesc,
                  icon: Icons.calculate_outlined,
                  trailing: Icon(Icons.chevron_right, size: ResponsiveUtils.getIconSize(context)),
                  onTap: () => _showRecalibrationDialog(context, ref)
                ),
                const Divider(height: 1),
                _buildSettingsListTile(
                  context: context,
                  title: localizations.help,
                  subtitle: localizations.openUserManual,
                  icon: Icons.help_outline,
                  trailing: Icon(Icons.chevron_right, size: ResponsiveUtils.getIconSize(context)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        HelpPage(isTablet: ResponsiveUtils.isTablet(context)),
                  )),
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
                      onLongPress: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DebugMenu()),
                      ),
                      child: Icon(
                          Icons.info_outline, 
                          color: Colors.grey,
                          size: iconSize,
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
                            final version =
                                snapshot.hasData ? snapshot.data!.version : '...';
                            return InkWell(
                              onTap: () => ChangelogHelper.showDirectly(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  localizations.getAppsVerision(version),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // _buildSettingsListTile(
                //   context: context,
                //   title: "Test 2025 Migration",
                //   subtitle: "Verify db_2025.db conversion logic",
                //   icon: Icons.auto_fix_high_outlined,
                //   trailing: Icon(Icons.play_arrow, color: Colors.green, size: ResponsiveUtils.getIconSize(context)),
                //   onTap: _runMigrationTest,
                // ),
              ],
            )
        )
      );
  }

  Future<void> _showRecalibrationDialog(
      BuildContext context, WidgetRef ref) async {
    final localizations = AppLocalizations.of(context);
    final helper = HelperAllPerson();
    final dbState = ref.read(databaseManagerProvider);               // CHANGED
 
    if (!dbState.isReady) {
      helper.showErrorMessage(context, localizations.databaseNotConnected);
      return;
    }
 
    final db = dbState.manager!.databaseConnection;
 
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.confirmAction,
            style: TextStyle(
                fontSize: ResponsiveUtils.getTitleFontSize(context),
                fontWeight: FontWeight.bold)),
        content: Text(localizations.recalibrateConfirm,
            style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(localizations.cancel,
                style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context) - 4)),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(localizations.proceed,
                style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context) - 4)),
          ),
        ],
      ),
    );
 
    if (confirmed == true) {
      helper.showLoadingDialog(context, localizations.recalibrating);
      try {
        await db.updateDao.recalibrateWeeklyData();
        helper.hideLoadingDialog(context);
        await helper.showSubmitMessage(
            context, localizations.recalibrationSuccess);
      } catch (e, stackTrace) {
        helper.hideLoadingDialog(context);
        helper.showErrorMessage(context, localizations.recalibrationFailed,
            stackTrace: stackTrace);
      }
    }
  }
 
  // Future<void> _runMigrationTest(BuildContext context, WidgetRef ref) async {
  //   final helper = HelperAllPerson();
  //   helper.showLoadingDialog(context, "Testing Migration...");
 
  //   try {
  //     final dir = await StorageManager.getExternalDocumentsDir();
  //     final file = File(p.join(dir!.path, 'db_2026_jt.db'));
 
  //     // Use the notifier directly — no new DatabaseManager() needed
  //     final notifier = ref.read(databaseManagerProvider.notifier);  // CHANGED
 
  //     final rolloverNeeded = await notifier.checkForYearRollover();
  //     if (rolloverNeeded) {
  //       debugPrint("Need to call performYearRolloverAndOpen");
  //     } else {
  //       debugPrint("Same year");
  //       try {
  //         await notifier.openDatabase(file: file);
  //       } on FileSystemException catch (e) {
  //         debugPrint("File not found: $e");
  //         rethrow;
  //       }
  //     }
 
  //     final testDb = ref.read(databaseManagerProvider).manager!.databaseConnection;
  //     final people = await testDb.readDao.getAllPerson(true);
  //     final dailyResults = await testDb.readDao
  //         .getPeopleFromCurrentDay(DateTime(2026, 01, 22));
  //     debugPrint("Daily Entries: ${dailyResults.length}");
  //     final weeklyEntry = await testDb.readDao
  //         .getWeeklyEntryByDate(DateTime(2026, 01, 26));
  //     debugPrint("Weekly Entry: ${weeklyEntry?.age_10_13 ?? 'null'}");
 
  //     helper.hideLoadingDialog(context);
  //     helper.showSubmitMessage(
  //         context, "Migration Success! Read ${people.length} people.");
  //   } catch (e, stack) {
  //     helper.hideLoadingDialog(context);
  //     helper.showErrorMessage(context, "Migration Test Failed",
  //         stackTrace: stack);
  //   }
  // }
 
  Widget _buildSettingsListTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: ResponsiveUtils.getContentPadding(context),
      leading: Icon(icon, size: ResponsiveUtils.getIconSize(context)),
      title: Text(title,
          style: TextStyle(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.w500)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(subtitle,
            style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

//   Future<void> _runMigrationTest() async {
//     final helper = HelperAllPerson();
    
//     helper.showLoadingDialog(context, "Testing Migration...");

//     try {
//       // 1. Get the path to your db_2025.db file
//       final dir = await StorageManager.getExternalDocumentsDir(); 
//       final file = File(p.join(dir!.path, 'db_2026_jt.db'));

//       // if (!await file.exists()) {
//       //   throw Exception("File db_2025.db not found in documents directory.");
//       // }

//       // 2. Open a separate connection to run the migration
//       final dbManager = DatabaseManager();
//       if(await dbManager.checkForYearRollover()){
//         debugPrint("Need to call performYearRolloverAndOpen");
//         //await dbManager.performYearRolloverAndOpen();
//       }
//       else{
//         debugPrint("Same year");
//         try{
//           await dbManager.openDatabase(file: file);
//         }
//         on FileSystemException catch (e) {
//           debugPrint("File not found need to create db first. $e");
//           rethrow;
//           // await dbManager.createDatabase();
//         }
//         catch (e, stackTrace) {
//           debugPrint("Unkown error Error: $e and $stackTrace");
//           rethrow;
//         }
//       }

//       final testDb = dbManager.databaseConnection;

//       // 4. Verify data can be read
//       final people = await testDb.readDao.getAllPerson(true);
//       final dailyResults = await testDb.readDao.getPeopleFromCurrentDay(DateTime(2026, 01, 22));
//       debugPrint("Daily Entries for 2025-09-25: ${dailyResults.length}");

//       final weeklyEntry = await testDb.readDao.getWeeklyEntryByDate(DateTime(2026, 01, 26));
//       debugPrint("Weekly Entry for 2025-09-22 found: ${weeklyEntry?.age_10_13 ?? "null"}");
//       // 5. Clean up
//       await dbManager.closeDatabase();
      
//       if (mounted) {
//         helper.hideLoadingDialog(context);
//         helper.showSubmitMessage(context, "Migration Success! Read ${people.length} people.");
//       }
//     } catch (e, stack) {
//       if (mounted) {
//         helper.hideLoadingDialog(context);
//         helper.showErrorMessage(context, "Migration Test Failed", stackTrace: stack);
//       }
//     }
//   }

//   Widget _buildSettingsListTile({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Widget trailing,
//     VoidCallback? onTap,
//   }) {
    
//     return ListTile(
//       contentPadding: ResponsiveUtils.getContentPadding(context),
//       leading: Icon(icon, size: ResponsiveUtils.getIconSize(context)),
//       title: Text(
//         title,
//         style: TextStyle(
//           fontSize: ResponsiveUtils.getBodyFontSize(context),
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       subtitle: Padding(
//         padding: const EdgeInsets.only(top: 2.0),
//         child: Text(
//           subtitle,
//           style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
//         ),
//       ),
//       trailing: trailing,
//       onTap: onTap,
//     );
//   }
// }