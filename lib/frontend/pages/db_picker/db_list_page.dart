import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:attendly/frontend/pages/splash_screen/splash_screen.dart';
import 'package:attendly/frontend/pages/directory_pages/state_manager_dir_page.dart';
import 'package:flutter/material.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class DatabaseListPage extends StatefulWidget {
  // Add a field to hold the path of the currently active database.
  final String? currentDbPath;
  final bool isTablet;

  const DatabaseListPage({
    super.key, 
    this.currentDbPath,
    this.isTablet = false,
  });

  @override
  State<DatabaseListPage> createState() => _DatabaseListPageState();
}

class _DatabaseListPageState extends State<DatabaseListPage> {
  late final Future<List<File>> _dbFilesFuture;

  @override
  void initState() {
    super.initState();
    _dbFilesFuture = StorageManager.listDbFiles();
  }

  /// Handles the selection of a database file.
  void _onFileSelected(BuildContext context, String selectedDbPath) async {
    // Close current connection and clear state before switching
    await DBConnectionManager.close();
    StateManager.clearChildrenList();

    if (!mounted) return;

    // Navigate to splash screen to re-initialize with the new DB
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => SplashScreen(selectedDbPath: selectedDbPath),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.selectDatabase,
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<File>>(
        future: _dbFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Text(
                  localizations.errorLoadingFiles(snapshot.error.toString()),
                  style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Text(
                  localizations.noDbFilesFound,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
                ),
              ),
            );
          }

          final files = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getListPadding(context).vertical,
              horizontal: ResponsiveUtils.getListPadding(context).horizontal,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = p.basename(file.path);
              final bool isCurrentDb = file.path == widget.currentDbPath;

              return Card(
                elevation: ResponsiveUtils.getCardElevation(context),
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getListPadding(context).horizontal / 2,
                  vertical: ResponsiveUtils.getListPadding(context).vertical / 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                ),
                color: isCurrentDb ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                child: ListTile(
                  enabled: !isCurrentDb,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getContentPadding(context).horizontal,
                    vertical: ResponsiveUtils.getContentPadding(context).vertical / 2,
                  ),
                  leading: Icon(
                    isCurrentDb ? Icons.check_circle : Icons.storage_rounded,
                    color: isCurrentDb ? Colors.green : Colors.blueGrey,
                    size: iconSize,
                  ),
                  title: Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: isCurrentDb ? Colors.grey[600] : null,
                    ),
                  ),
                  subtitle: Text(
                    isCurrentDb ? localizations.currentlyLoaded : file.parent.path,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context) - 6,
                      color: isCurrentDb ? Colors.grey[600] : null,
                    ),
                  ),
                  onTap: isCurrentDb ? null : () => _onFileSelected(context, file.path),
                ),
              );
            },
          );
        },
      ),
    );
  }
}