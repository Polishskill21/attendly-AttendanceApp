// lib/storage_manager.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageManager {
  /// Gets the custom external storage directory for the app.
  /// This function handles permissions and creates the directory if it doesn't exist.
  static Future<Directory?> getExternalDirectory() async {
    try {
      Directory? documentsDir;
      var status = await Permission.manageExternalStorage.status;

      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status.isGranted) {
        final List<Directory>? extDirs = await getExternalStorageDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          // Get base path (remove "/Android/data/...")
          String basePath = extDirs[0].path.split("Android")[0];
          // Construct the path to a public-facing directory like 'Documents'
          documentsDir = Directory(p.join(basePath, "Documents", "AttendlyDb"));
        } else {
          debugPrint("No external storage directories found.");
        }
      } else if (status.isPermanentlyDenied) {
        debugPrint("Manage External Storage permission is permanently denied.");
        await openAppSettings(); 
        return null;
      } else {
        debugPrint("Manage External Storage permission is not granted.");
        return null;
      }

      if (documentsDir == null) {
        debugPrint("Failed to get Documents directory");
        return null;
      }

      // Ensure the directory exists
      await documentsDir.create(recursive: true);
      return documentsDir;
    } catch (e) {
      debugPrint("Error in getExternalDirectory: $e");
      return null;
    }
  }

  /// Lists all files with a '.db' extension from the external directory.
  static Future<List<File>> listDbFiles() async {
    final Directory? dir = await getExternalDirectory();
    if (dir == null) {
      // Return an empty list if the directory is not accessible
      return [];
    }

    final List<File> dbFiles = [];
    // Use listSync to get all entities, then filter them
    final List<FileSystemEntity> entities = dir.listSync();
    for (var entity in entities) {
      // Check if the entity is a file and has the '.db' extension
      if (entity is File && p.extension(entity.path) == '.db') {
        dbFiles.add(entity);
      }
    }
    return dbFiles;
  }
}