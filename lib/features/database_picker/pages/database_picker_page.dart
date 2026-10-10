import 'dart:io';
import 'package:attendly/data/storage/storage_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:flutter/material.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/core/responsive/responsive.dart';

class DatabasePickerPage extends ConsumerStatefulWidget {
  // Add a field to hold the path of the currently active database.
  final String? currentDbPath;

  const DatabasePickerPage({
    super.key, 
    this.currentDbPath,
  });

  @override
  ConsumerState<DatabasePickerPage> createState() => _DatabasePickerPageState();
}

class _DatabasePickerPageState extends ConsumerState<DatabasePickerPage> {
  late final Future<List<File>> _dbFilesFuture;

  @override
  void initState() {
    super.initState();
    _dbFilesFuture = StorageManager.listDbFiles();
  }

  /// Handles the selection of a database file.
  /// The startup gate closes this page and shows progress or errors.
  void _onFileSelected(File selectedDb) {
    ref.read(appStartupProvider.notifier).openDatabaseFile(selectedDb);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final iconSize = Responsive.of(context).iconSize();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.selectDatabase,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
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
              vertical: Responsive.of(context).listPadding.vertical,
              horizontal: Responsive.of(context).listPadding.horizontal,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = p.basename(file.path);
              final bool isCurrentDb = file.path == widget.currentDbPath;

              return Card(
                elevation: Responsive.of(context).cardElevation,
                margin: EdgeInsets.symmetric(
                  horizontal: Responsive.of(context).listPadding.horizontal / 2,
                  vertical: Responsive.of(context).listPadding.vertical / 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: Responsive.of(context).cardBorderRadius,
                ),
                color: isCurrentDb ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                child: ListTile(
                  enabled: !isCurrentDb,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Responsive.of(context).contentPadding.horizontal,
                    vertical: Responsive.of(context).contentPadding.vertical / 2,
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
                      fontSize: Responsive.of(context).bodyFontSize,
                      color: isCurrentDb ? Colors.grey[600] : null,
                    ),
                  ),
                  subtitle: Text(
                    isCurrentDb ? localizations.currentlyLoaded : file.parent.path,
                    style: TextStyle(
                      fontSize: Responsive.of(context).bodyFontSize - 6,
                      color: isCurrentDb ? Colors.grey[600] : null,
                    ),
                  ),
                  onTap: isCurrentDb ? null : () => _onFileSelected(file),
                ),
              );
            },
          );
        },
      ),
    );
  }
}