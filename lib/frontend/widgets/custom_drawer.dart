import 'package:attendly/frontend/pages/db_picker/db_list_page.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/backend/global/global_var.dart';
import 'package:attendly/frontend/pages/settings_page/settings_page.dart';
import 'package:attendly/frontend/pages/splash_screen/splash_screen.dart';
import 'package:attendly/frontend/pages/directory_pages/state_manager_dir_page.dart';
import 'package:attendly/localization/app_localizations.dart';

class CustomDrawer extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabChange;
  final bool isTablet;
  final bool isRailMode;

  const CustomDrawer({
    super.key,
    required this.selectedTab,
    required this.onTabChange,
    this.isTablet = false,
    this.isRailMode = false,
  });

  void _handleNewYearBannerTap(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isRailMode && isTablet) {
      return _buildNavigationRail(context);
    } else {
      return _buildDrawer(context);
    }
  }

  Widget _buildNavigationRail(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final iconSize = ResponsiveUtils.getIconSize(context, baseSize: 32);

    final int? validSelectedIndex = (selectedTab >= 0 && selectedTab <= 3) ? selectedTab : null;

    return NavigationRail(
      extended: false,
      minWidth: 72,
      selectedIndex: validSelectedIndex,
      onDestinationSelected: onTabChange,
      labelType: NavigationRailLabelType.none,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: Column(
        children: [
          const SizedBox(height: 8),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(
                Icons.menu,
                color: theme.iconTheme.color,
                size: iconSize * 0.95,
              ),
            ),
          ),
          if (showNewYearBanner)
            GestureDetector(
              onTap: () => _handleNewYearBannerTap(context),
              child: Container(
                margin: const EdgeInsets.only(top: 24, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.new_releases,
                  color: Colors.white,
                  size: iconSize * 0.9,
                ),
              ),
            ),
          SizedBox(height: showNewYearBanner ? 0 : 40),
        ],
      ),
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.people_outline, size: iconSize),
          selectedIcon: Icon(Icons.people, size: iconSize, color: theme.primaryColor),
          label: Text(
            localizations.directory,
            style: TextStyle(fontSize: 14),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today_outlined, size: iconSize),
          selectedIcon: Icon(Icons.calendar_today, size: iconSize, color: theme.primaryColor),
          label: Text(
            localizations.dailyLogs,
            style: TextStyle(fontSize: 14),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.view_week_outlined, size: iconSize),
          selectedIcon: Icon(Icons.view_week, size: iconSize, color: theme.primaryColor),
          label: Text(
            localizations.weeklyReport,
            style: TextStyle(fontSize: 14),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined, size: iconSize),
          selectedIcon: Icon(Icons.bar_chart, size: iconSize, color: theme.primaryColor),
          label: Text(
            localizations.yearStats,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.settings_outlined, size: iconSize),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              tooltip: localizations.settings,
            ),
            SizedBox(height: 16),
            IconButton(
              icon: Icon(
                isTemporaryDb ? Icons.exit_to_app : Icons.folder_open_outlined,
                size: iconSize,
              ),
              onPressed: () async {
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
                        isTablet: isTablet,
                      ),
                    ),
                  );
                }
              },
              tooltip: isTemporaryDb 
                  ? localizations.returnToMainDatabase 
                  : localizations.changeDatabase,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dbPath = DBConnectionManager.filePath ?? localizations.noDatabaseOpen;
    final dbName = p.basename(dbPath);
    
    final iconScale = ResponsiveUtils.getIconScaleFactor(context);

    final textScale = isTablet ? 0.9 : 1.0;

    return Drawer(

      width: isTablet 
          ? MediaQuery.of(context).size.width * 0.55
          : MediaQuery.of(context).size.width * 0.65,
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
                    iconScale: iconScale,
                    textScale: textScale,
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
                    iconScale: iconScale,
                    textScale: textScale,
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
                    iconScale: iconScale,
                    textScale: textScale,
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
                    iconScale: iconScale,
                    textScale: textScale,
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
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              iconScale: iconScale,
              textScale: textScale,
            ),
            _buildDrawerItem(
              context: context,
              theme: theme,
              icon: isTemporaryDb ? Icons.exit_to_app : Icons.folder_open_outlined,
              text: isTemporaryDb ? localizations.returnToMainDatabase : localizations.changeDatabase,
              isSelected: false,
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
                        isTablet: isTablet,
                      ),
                    ),
                  );
                }
              },
              iconScale: iconScale,
              textScale: textScale,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, ThemeData theme, String dbName, AppLocalizations localizations) {
    final isTablet = this.isTablet || ResponsiveUtils.isTablet(context);
    final textScale = isTablet ? 0.85 : 1.0;
    
    return Container(
        height: showNewYearBanner ? (isTablet ? 300 : 270) : (isTablet ? 240 : 210),
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
            Icon(Icons.storage, size: isTablet ? 52 : 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              localizations.currentDatabase,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), 
                fontSize: isTablet ? 20.0 * textScale : 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dbName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 26.0 * textScale : 18.0,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            if (showNewYearBanner) ...[
              const SizedBox(height: 15),
              _buildNewYearBanner(context, localizations, isTablet: isTablet),
            ]
          ],
        ),
    );
  }

  Widget _buildNewYearBanner(BuildContext context, AppLocalizations localizations, {bool isTablet = false}) {
    final textScale = ResponsiveUtils.getTextScaleFactor(context);
    
    return GestureDetector(
      onTap: () => _handleNewYearBannerTap(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12, 
          vertical: isTablet ? 12 : 8
        ),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.new_releases_outlined, 
              color: Colors.white, 
              size: isTablet ? 28 : 20
            ),
            SizedBox(width: isTablet ? 12 : 9),
            Expanded(
              child: Text(
                localizations.newYearAvailable,
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 * textScale : 14,
                ),
                softWrap: true,
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
    double iconScale = 1.0,
    double textScale = 1.0,
  }) {
    final Color selectedColor = theme.colorScheme.primary;
    final Color defaultTextColor = theme.listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final Color defaultIconColor = theme.listTileTheme.iconColor ?? theme.iconTheme.color ?? Colors.grey;
    final isTablet = this.isTablet || ResponsiveUtils.isTablet(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8, 
        vertical: isTablet ? 6 : 4
      ),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 4 : 0,
        ),
        leading: Icon(
          icon,
          color: isSelected ? selectedColor : defaultIconColor,
          size: (isTablet ? 32 : 24) * iconScale,
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: (isTablet ? 18 : 16) * textScale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? selectedColor : defaultTextColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}