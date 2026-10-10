import 'dart:io';

import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionState { granted, denied, permanentlyDenied }

/// Storage access for Documents/AttendlyDb.
///
/// Android 11+ needs "all files access" (manageExternalStorage). On Android 10
/// and below that permission reports `restricted`, and the classic storage
/// permission is used instead.
class StoragePermissionService {
  static const String _tag = 'Permission';

  const StoragePermissionService();

  /// Checks the current state without asking the user.
  Future<PermissionState> status() async {
    if (!Platform.isAndroid) return PermissionState.granted;
    final permission = await _storagePermission();
    return _map(await permission.status);
  }

  /// Asks the user. On Android 11+ this opens the system "all files access"
  /// screen and completes when the user comes back.
  Future<PermissionState> request() async {
    if (!Platform.isAndroid) return PermissionState.granted;
    final permission = await _storagePermission();
    final result = _map(await permission.request());
    AppLogger.i(_tag, 'Storage permission request: ${result.name}');
    return result;
  }

  Future<bool> openSettings() => openAppSettings();

  Future<Permission> _storagePermission() async {
    final manageStatus = await Permission.manageExternalStorage.status;
    return manageStatus.isRestricted
        ? Permission.storage
        : Permission.manageExternalStorage;
  }

  PermissionState _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return PermissionState.granted;
    if (status.isPermanentlyDenied) return PermissionState.permanentlyDenied;
    return PermissionState.denied;
  }
}

final storagePermissionServiceProvider = Provider<StoragePermissionService>(
  (ref) => const StoragePermissionService(),
);
