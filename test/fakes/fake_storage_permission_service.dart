import 'dart:async';

import 'package:attendly/core/permissions/storage_permission_service.dart';

/// Permission service whose answers are set by the test.
class FakeStoragePermissionService implements StoragePermissionService {
  FakeStoragePermissionService({
    this.current = PermissionState.granted,
    this.afterRequest = PermissionState.granted,
  });

  PermissionState current;

  /// What [request] returns; it also becomes the new [current].
  PermissionState afterRequest;

  /// When set, [request] waits for it, like the real request waits until
  /// the user comes back from the system settings.
  Completer<void>? requestGate;

  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<PermissionState> status() async => current;

  @override
  Future<PermissionState> request() async {
    requests++;
    await requestGate?.future;
    current = afterRequest;
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}
