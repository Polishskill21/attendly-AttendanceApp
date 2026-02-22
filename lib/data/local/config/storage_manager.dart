import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageManager {
  /// Gets the custom external storage directory for the app.
  /// Handles legacy and modern Android storage permissions safely.
  static Future<Directory?> getExternalDocumentsDir() async {
    try {
      bool isGranted = await _requestStoragePermission();
      if (!isGranted) return null;

      final List<Directory>? extDocumentsDirs = await getExternalStorageDirectories();
      
      if (extDocumentsDirs == null || extDocumentsDirs.isEmpty) {
        debugPrint("No external storage directories found.");
        return null;
      }

      // Safely extract the root external storage path (e.g., /storage/emulated/0/)
      final String path = extDocumentsDirs.first.path;
      final int androidIndex = path.indexOf('/Android/');
      
      if (androidIndex == -1) {
        debugPrint("Unexpected path structure: $path");
        return null;
      }
      
      final String basePath = path.substring(0, androidIndex);
      final Directory documentsDir = Directory(p.join(basePath, "Documents", "AttendlyDb"));

      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      
      return documentsDir;
    } catch (e, stackTrace) {
      debugPrint("Error in getExternalDirectory: $e\n$stackTrace");
      return null;
    }
  }

  /// Handles the complex permission gap between Android 10 and Android 11+
  static Future<bool> _requestStoragePermission() async {
    // Check Android 11+ manageExternalStorage first
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    // Fallback for Android 10 and below
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    // If both are permanently denied, direct the user to app settings
    if (await Permission.manageExternalStorage.isPermanentlyDenied || 
        await Permission.storage.isPermanentlyDenied) {
      debugPrint("Storage permission permanently denied. Redirecting to settings.");
      await openAppSettings();
    } else {
      debugPrint("Storage permission denied by user.");
    }
    
    return false;
  }

  /// Lists all files with a '.db' extension from the external directory asynchronously.
  static Future<List<File>> listDbFiles() async {
    final Directory? dir = await getExternalDocumentsDir();
    if (dir == null) return [];

    try {
      // Use async stream (.list()) instead of listSync() to prevent UI freezing
      final List<File> dbFiles = await dir.list()
          .where((entity) => entity is File && p.extension(entity.path).toLowerCase() == '.db')
          .cast<File>()
          .toList();

      return dbFiles;
    } catch (e) {
      debugPrint("Error listing DB files: $e");
      return [];
    }
  }
}