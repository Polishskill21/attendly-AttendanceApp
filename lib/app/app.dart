import 'package:attendly/app/startup/startup_gate.dart';
import 'package:attendly/app/theme/app_theme.dart';
import 'package:attendly/data/settings/settings_exceptions.dart';
import 'package:attendly/features/settings/providers/settings_notifier.dart';
import 'package:attendly/l10n/app_localizations_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget: MaterialApp with theme, localization and the startup gate.
class AttendlyApp extends ConsumerWidget {
  const AttendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    if (settings.error != null) return _buildErrorApp(settings.error!);

    return MaterialApp(
      title: 'Attendly',
      themeMode: settings.themeMode,
      locale:    settings.locale,
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('de', ''),
      ],
      theme:     AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      // One system bar style for every screen, including the startup views
      // without an AppBar. Updated by Flutter only when it changes.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child!,
        );
      },
      home: const StartupGate(),
    );
  }

  Widget _buildErrorApp(SettingsException error) {
    // Use a temporary MaterialApp to show the error screen.
    // It uses the default light theme and locale.
    final localizations = AppLocalizationsDelegate.getLocalization(const Locale('en'));
    String errorMessage;

    if (error is SettingsDirectoryNotFoundException) {
      errorMessage = localizations.settingsErrorDirectory;
    } else if (error is SettingsFileNotFoundException) {
      errorMessage = localizations.settingsErrorFile;
    } else if (error is SettingsKeyNotFoundException) {
      errorMessage = localizations.settingsErrorKey(error.key);
    } else {
      errorMessage = localizations.settingsErrorFile; // Fallback
    }

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  localizations.settingsErrorTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
