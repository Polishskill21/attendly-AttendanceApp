import 'package:attendly/app/startup/startup_gate.dart';
import 'package:attendly/core/permissions/storage_permission_service.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/data/settings/settings_service.dart';
import 'package:attendly/features/settings/providers/settings_notifier.dart';
import 'package:attendly/l10n/app_en.dart';
import 'package:attendly/l10n/app_localizations_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_database_manager.dart';
import '../fakes/fake_storage_permission_service.dart';
import '../helpers/pump_app.dart';

class _FakeSettingsService extends SettingsService {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.light;

  @override
  Future<Locale> getLocale() async => const Locale('en');
}

void main() {
  final l10n = AppLocalizationsEn();
  late FakeDatabaseManager manager;
  late FakeStoragePermissionService permission;

  setUp(() {
    manager = FakeDatabaseManager();
    permission = FakeStoragePermissionService();
    SharedPreferences.setMockInitialValues({});
    // No changelog asset exists for this version, so no dialog pops up.
    PackageInfo.setMockInitialValues(
      appName: 'attendly',
      packageName: 'attendly',
      version: '0.0.0',
      buildNumber: '0',
      buildSignature: '',
    );
  });

  tearDown(() => manager.closeDatabase());

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => DatabaseNotifier(manager)),
        storagePermissionServiceProvider.overrideWithValue(permission),
        settingsProvider.overrideWith((ref) => SettingsNotifier(_FakeSettingsService())),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: StartupGate(),
      ),
    ));
    await settleStreams(tester);
  }

  testWidgets('denied permission -> permission view -> shell', (tester) async {
    permission
      ..current = PermissionState.denied
      ..afterRequest = PermissionState.granted;

    await pumpGate(tester);
    expect(find.text(l10n.storagePermissionTitle), findsOneWidget);

    await tester.tap(find.text(l10n.grantPermission));
    await settleStreams(tester);

    expect(find.text(l10n.noPersonFound), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('permanently denied permission offers the system settings', (tester) async {
    permission.current = PermissionState.permanentlyDenied;

    await pumpGate(tester);
    expect(find.text(l10n.storagePermissionDeniedMessage), findsOneWidget);

    await tester.tap(find.text(l10n.openAppSettings));
    await tester.pump();
    expect(permission.settingsOpened, 1);
    await unmount(tester);
  });

  testWidgets('fresh install -> setup view -> shell', (tester) async {
    manager.initialSetupNeeded = true;

    await pumpGate(tester);
    expect(find.text(l10n.noDatabaseTitle), findsOneWidget);

    await tester.tap(find.text(l10n.createDatabase));
    await settleStreams(tester);

    expect(find.text(l10n.noPersonFound), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('broken database -> failed view with retry and logs', (tester) async {
    manager.openError = Exception('file is not a database');

    await pumpGate(tester);
    expect(find.text(l10n.databaseSwitchFailed), findsOneWidget);
    expect(find.text(l10n.showLogs), findsOneWidget);
    expect(find.text(l10n.openDefaultDatabase), findsNothing);

    manager.openError = null;
    await tester.tap(find.text(l10n.retry));
    await settleStreams(tester);

    expect(find.text(l10n.noPersonFound), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a reported database error replaces the shell with the failed view',
      (tester) async {
    await pumpGate(tester);
    expect(find.text(l10n.noPersonFound), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(StartupGate)));
    container.read(databaseProvider.notifier).reportDatabaseError(Exception('stream failed'));
    await settleStreams(tester);

    expect(find.text(l10n.databaseSwitchFailed), findsOneWidget);
    await unmount(tester);
  });
}
