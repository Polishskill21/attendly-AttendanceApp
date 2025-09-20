import 'dart:io';
import 'package:attendly/backend/settings_exceptions.dart';
import 'package:attendly/frontend/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:attendly/frontend/pages/splash_screen/splash_screen.dart';
import 'package:attendly/frontend/pages/settings_page/settings_provider.dart';
import 'package:attendly/frontend/pages/settings_page/settings_service.dart';
import 'package:attendly/localization/app_localizations_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // Check if permission is denied before requesting
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      // For Android 10+ (API level 29+)
      if (await Permission.manageExternalStorage.request().isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }
  //debugPaintSizeEnabled = true;
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(SettingsService()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.error != null) {
          return _buildErrorApp(context, settings.error!);
        }

        return MaterialApp(
          title: 'Attendly',
          themeMode: settings.themeMode,
          locale: settings.locale,
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
          theme: Themebuilder.buildLightTheme(),
          darkTheme: Themebuilder.buildDarkTheme(),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            SystemChrome.setSystemUIOverlayStyle(
              (isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
            );
            return child!;
          },
          home: const SplashScreen(),
        );
      },
    );
  }

  Widget _buildErrorApp(BuildContext context, SettingsException error) {
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
