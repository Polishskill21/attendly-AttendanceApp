/// Base class for all settings-related exceptions.
abstract class SettingsException implements Exception {
  final String message;
  SettingsException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the application's external storage directory cannot be found or accessed.
class SettingsDirectoryNotFoundException extends SettingsException {
  SettingsDirectoryNotFoundException() : super("Could not access the application's settings directory.");
}

/// Thrown when the settings.json file is not found.
class SettingsFileNotFoundException extends SettingsException {
  SettingsFileNotFoundException() : super("The settings.json file was not found.");
}

/// Thrown when a required key is missing from the settings.json file.
class SettingsKeyNotFoundException extends SettingsException {
  final String key;
  SettingsKeyNotFoundException(this.key) : super("The required key '$key' was not found in settings.json.");
}
