import 'dart:convert';
import 'dart:io';
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:path/path.dart' as p;

class DebugMenu extends StatefulWidget {
  const DebugMenu({super.key});

  @override
  State<StatefulWidget> createState() => _DebugMenuState();
}

class _DebugMenuState extends State<DebugMenu> {
  String _settingsContent = '';
  bool _isLoading = true;
  String? _error;
  String? _settingsPath;

  @override
  void initState() {
    super.initState();
    _loadSettingsFile();
  }

  Future<void> _loadSettingsFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the same directory logic as your app
      final directory = await StorageManager.getExternalDirectory();
      if (directory == null) {
        setState(() {
          _error = 'Could not access external directory';
          _isLoading = false;
        });
        return;
      }

      final settingsFile = File(p.join(directory.path, 'settings.json'));
      _settingsPath = settingsFile.path;

      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();

        if (content.trim().isEmpty) {
          setState(() {
            _settingsContent = '{}';
            _error = 'Settings file is empty';
            _isLoading = false;
          });
          return;
        }

        try {
          // Pretty print JSON
          final jsonObject = jsonDecode(content);
          final prettyString = JsonEncoder.withIndent('  ').convert(jsonObject);

          setState(() {
            _settingsContent = prettyString;
            _isLoading = false;
          });
        } catch (jsonError) {
          setState(() {
            _settingsContent = content; // Show raw content if JSON parsing fails
            _error = 'JSON parsing error: $jsonError';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _settingsContent = '{}';
          _error = 'Settings file does not exist at: ${settingsFile.path}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error reading settings file: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    final localizations = AppLocalizations.of(context);
    final contentToCopy = _settingsPath != null
        ? 'Path: $_settingsPath\n\n$_settingsContent'
        : _settingsContent;

    Clipboard.setData(ClipboardData(text: contentToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.settingsCopiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final iconSize = ResponsiveUtils.getIconSize(context);

    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              localizations.debugSettings,
              style: TextStyle(
                fontSize: ResponsiveUtils.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: iconSize),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.copy, size: iconSize),
                onPressed: _copyToClipboard,
                tooltip: localizations.copyToClipboard,
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: iconSize),
                onPressed: _loadSettingsFile,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.getContentPadding(context).bottom + MediaQuery.of(context).padding.bottom,
              left: ResponsiveUtils.getContentPadding(context).left,
              right: ResponsiveUtils.getContentPadding(context).right,
              top: ResponsiveUtils.getContentPadding(context).top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.settingsJsonContents,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_settingsPath != null) ...[
                  SizedBox(height: ResponsiveUtils.isTablet(context) ? 12 : 8),
                  Text(
                    'Path: $_settingsPath',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context) - 4,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                SizedBox(height: ResponsiveUtils.isTablet(context) ? 24 : 16),
                if (_error != null)
                  Container(
                    padding: ResponsiveUtils.getContentPadding(context),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: iconSize),
                        SizedBox(width: ResponsiveUtils.isTablet(context) ? 12 : 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: ResponsiveUtils.getBodyFontSize(context) - 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: ResponsiveUtils.isTablet(context) ? 24 : 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        width: double.infinity,
                        padding: ResponsiveUtils.getContentPadding(context),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _settingsContent.isEmpty ? '{}' : _settingsContent,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: ResponsiveUtils.getBodyFontSize(context) - 6,
                            ),
                          ),
                        ),
                      ),
                Divider(height: ResponsiveUtils.isTablet(context) ? 40 : 32),
                _buildInfoTile(
                  title: localizations.databasePath,
                  icon: Icons.storage_outlined,
                  subtitle: DBConnectionManager.filePath ?? localizations.notAvailable,
                  iconSize: iconSize,
                  isTablet: ResponsiveUtils.isTablet(context),
                ),
                _buildInfoTile(
                  title: localizations.connectionStatus,
                  icon: DBConnectionManager.db?.isOpen ?? false
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  subtitle: DBConnectionManager.db?.isOpen ?? false
                      ? localizations.connected
                      : localizations.disconnected,
                  iconColor: DBConnectionManager.db?.isOpen ?? false ? Colors.green : Colors.red,
                  iconSize: iconSize,
                  isTablet: ResponsiveUtils.isTablet(context),
                ),
                SizedBox(height: ResponsiveUtils.isTablet(context) ? 24 : 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: ResponsiveUtils.getIconSize(context, baseSize: 16), color: Colors.grey.shade600),
                    SizedBox(width: ResponsiveUtils.isTablet(context) ? 12 : 8),
                    Expanded(
                      child: Text(
                        localizations.debugMenuDescription,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getBodyFontSize(context) - 6,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildInfoTile({
    required String title,
    required IconData icon,
    required String subtitle,
    Color? iconColor,
    required double iconSize,
    required bool isTablet,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getBodyFontSize(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 6),
      ),
    );
  }
}