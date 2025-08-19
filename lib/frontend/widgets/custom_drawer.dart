import 'package:attendly/frontend/pages/db_picker/db_list_page.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/backend/global/global_var.dart';
import 'package:attendly/frontend/pages/settings_page/settings_page.dart';
import 'package:attendly/frontend/pages/splash_screen/splash_screen.dart';
import 'package:attendly/frontend/pages/directory_pages/state_manager_dir_page.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

class CustomDrawer extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabChange;

  const CustomDrawer({
    super.key,
    required this.selectedTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dbPath = DBConnectionManager.filePath ?? localizations.noDatabaseOpen;
    final dbName = p.basename(dbPath);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.65,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context, theme, dbName, localizations),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    theme: theme,
                    icon: Icons.people_outline,
                    text: localizations.directory,
                    isSelected: selectedTab == 0,
                    onTap: () {
                      onTabChange(0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    theme: theme,
                    icon: Icons.calendar_today_outlined,
                    text: localizations.dailyLogs,
                    isSelected: selectedTab == 1,
                    onTap: () {
                      onTabChange(1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    theme: theme,
                    icon: Icons.view_week_outlined,
                    text: localizations.weeklyReport,
                    isSelected: selectedTab == 2,
                    onTap: () {
                      onTabChange(2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    theme: theme,
                    icon: Icons.bar_chart_outlined,
                    text: localizations.yearStats,
                    isSelected: selectedTab == 3,
                    onTap: () {
                      onTabChange(3);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(
              context: context,
              theme: theme,
              icon: Icons.settings_outlined,
              text: localizations.settings,
              isSelected: selectedTab == 4,
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              theme: theme,
              icon: isTemporaryDb ? Icons.exit_to_app : Icons.folder_open_outlined,
              text: isTemporaryDb ? localizations.returnToMainDatabase : localizations.changeDatabase,
              isSelected: false, // This is a one-off action
              onTap: () async {
                Navigator.pop(context);

                if (isTemporaryDb) {
                  await DBConnectionManager.close();
                  StateManager.clearChildrenList();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                    (Route<dynamic> route) => false,
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DatabaseListPage(
                        currentDbPath: DBConnectionManager.filePath,
                      ),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom), // Spacer for system nav bar
          ],
        ),
      ),
    );
  }

  //   Future<void> _saveDatabase(BuildContext context, AppLocalizations localizations) async {
  //   try {
  //     final dbPath = DBConnectionManager.filePath;
  //     if (dbPath == null) return;

  //     // Read the database file as bytes
  //     final File dbFile = File(dbPath);
  //     final Uint8List fileBytes = await dbFile.readAsBytes();
  //     final String fileName = p.basename(dbPath);

  //     // Use FilePicker to save the file with bytes
  //     final String? outputFile = await FilePicker.platform.saveFile(
  //       dialogTitle: localizations.saveDatabaseAs,
  //       fileName: fileName,
  //       bytes: fileBytes,
  //     );

  //     if (outputFile != null && context.mounted) {
  //       await showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text(localizations.ok),
  //         content: Text(localizations.databaseSavedSuccessfully),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text(localizations.ok),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // } catch (e) {
  //   if (context.mounted) {
  //     await showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text(localizations.errorOccurred),
  //         content: Text(e.toString()),
  //         backgroundColor: Colors.red[100],
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text(localizations.ok),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //   }
  // }

  Widget _buildDrawerHeader(BuildContext context, ThemeData theme, String dbName, AppLocalizations localizations) {
    return Container(
        height: showNewYearBanner ? 270 : 210,
        width: double.infinity,
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.primaryColorLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.storage, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              localizations.currentDatabase,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              dbName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (showNewYearBanner) ...[
              const SizedBox(height: 15),
              _buildNewYearBanner(context, localizations),
            ]
          ],
        ),
    );
  }

  Widget _buildNewYearBanner(BuildContext context, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () {
        // This should trigger the new year DB creation flow again.
        // For simplicity, we restart the app to show the splash screen dialog.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.new_releases_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                localizations.newYearAvailable,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                softWrap: true,
                //overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color selectedColor = theme.colorScheme.primary;
    final Color defaultTextColor = theme.listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final Color defaultIconColor = theme.listTileTheme.iconColor ?? theme.iconTheme.color ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? selectedColor : defaultIconColor,
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? selectedColor : defaultTextColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}