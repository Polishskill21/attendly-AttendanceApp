import 'dart:io';
import 'package:attendly/global/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageManager {
  static const String _tag = "Storage";

  /// Gets the custom external storage directory for the app.
  /// Handles legacy and modern Android storage permissions safely.
  static Future<Directory?> getExternalDocumentsDir() {
    // Concurrent permission requests make permission_handler throw,
    // so callers arriving while a lookup is running share its result.
    return _pendingDirLookup ??= _resolveExternalDocumentsDir()
        .whenComplete(() => _pendingDirLookup = null);
  }

  static Future<Directory?>? _pendingDirLookup;

  static Future<Directory?> _resolveExternalDocumentsDir() async {
    try {
      bool isGranted = await _requestStoragePermission();
      if (!isGranted) {
        AppLogger.e(_tag, "Storage permission not granted, storage directory unavailable");
        return null;
      }

      final List<Directory>? extDocumentsDirs = await getExternalStorageDirectories();
      
      if (extDocumentsDirs == null || extDocumentsDirs.isEmpty) {
        AppLogger.e(_tag, "No external storage directories found");
        return null;
      }

      // Safely extract the root external storage path (e.g., /storage/emulated/0/)
      final String path = extDocumentsDirs.first.path;
      final int androidIndex = path.indexOf('/Android/');
      
      if (androidIndex == -1) {
        AppLogger.e(_tag, "Unexpected external storage path structure: $path");
        return null;
      }
      
      final String basePath = path.substring(0, androidIndex);
      final Directory documentsDir = Directory(p.join(basePath, "Documents", "AttendlyDb"));

      if (!await documentsDir.exists()) {
        AppLogger.i(_tag, "Creating storage directory ${documentsDir.path}");
        await documentsDir.create(recursive: true);
      }

      await AppLogger.attachLogDirectory(documentsDir);
      return documentsDir;
    } catch (e, stackTrace) {
      AppLogger.e(_tag, "Resolving the storage directory failed", e, stackTrace);
      return null;
    }
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
    } catch (e, stackTrace) {
      AppLogger.e(_tag, "Listing database files in ${dir.path} failed", e, stackTrace);
      return [];
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
      AppLogger.w(_tag, "Storage permission permanently denied, opening app settings");
      await openAppSettings();
    } else {
      AppLogger.w(_tag, "Storage permission denied by user");
    }
    
    return false;
  }
}