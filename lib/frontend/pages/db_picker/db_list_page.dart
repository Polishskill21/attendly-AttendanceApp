import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:attendly/frontend/pages/splash_screen/splash_screen.dart';
import 'package:attendly/frontend/pages/directory_pages/state_manager_dir_page.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';


class DatabaseListPage extends StatefulWidget {
 // Add a field to hold the path of the currently active database.
  final String? currentDbPath;

  const DatabaseListPage({super.key, this.currentDbPath});

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
  /// This logic is moved from your original CustomDrawer.
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
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.selectDatabase),
      ),
      body: FutureBuilder<List<File>>(
        future: _dbFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(localizations.errorLoadingFiles(snapshot.error.toString())));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  localizations.noDbFilesFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = p.basename(file.path);
              
              final bool isCurrentDb = file.path == widget.currentDbPath;

              return Card(
                // Change the card color if it's the active DB.
                color: isCurrentDb ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  // Disable the tile if it's the active DB.
                  enabled: !isCurrentDb,
                  leading: Icon(
                    // Show a checkmark for the active DB.
                    isCurrentDb ? Icons.check_circle : Icons.storage_rounded,
                    color: isCurrentDb ? Colors.green : Colors.blueGrey,
                  ),
                  title: Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      // Gray out the text color if it's the active DB.
                      color: isCurrentDb ? Colors.grey[600] : null,
                    ),
                  ),
                  subtitle: Text(
                    // Show a different subtitle for the active DB.
                    isCurrentDb ? localizations.currentlyLoaded : file.parent.path,
                    style: TextStyle(
                        fontSize: 12,
                        color: isCurrentDb ? Colors.grey[600] : null),
                  ),
                  // Set onTap to null to disable interaction for the active DB.
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