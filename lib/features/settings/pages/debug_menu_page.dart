import 'dart:convert';
import 'dart:io';
import 'package:attendly/data/storage/storage_manager.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class DebugMenuPage extends ConsumerStatefulWidget  {
  const DebugMenuPage({super.key});

  @override
  ConsumerState<DebugMenuPage> createState() => _DebugMenuPageState();
}

class _DebugMenuPageState extends ConsumerState<DebugMenuPage> {
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
      final directory = await StorageManager.getExternalDocumentsDir();
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
          final jsonObject = jsonDecode(content);
          final prettyString =
              JsonEncoder.withIndent('  ').convert(jsonObject);
          setState(() {
            _settingsContent = prettyString;
            _isLoading = false;
          });
        } catch (jsonError) {
          setState(() {
            _settingsContent = content;
            _error = 'JSON parsing error: $jsonError';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _settingsContent = '{}';
          _error =
              'Settings file does not exist at: ${settingsFile.path}';
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
      SnackBar(
          content: Text(localizations.settingsCopiedToClipboard)),
    );
  }

  void _copyLogsToClipboard() {
    final localizations = AppLocalizations.of(context);
    final path = AppLogger.logFilePath;
    final logs = AppLogger.recentLines.join('\n');

    Clipboard.setData(ClipboardData(text: path != null ? 'Log file: $path\n\n$logs' : logs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.logsCopiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final iconSize = Responsive.of(context).iconSize();
    // Read the active db state from AppState
    final appState = ref.watch(databaseProvider); 

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.debugSettings,
            style: TextStyle(
              fontSize: Responsive.of(context).titleFontSize,
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
            bottom: Responsive.of(context).contentPadding.bottom +
                MediaQuery.of(context).padding.bottom,
            left: Responsive.of(context).contentPadding.left,
            right: Responsive.of(context).contentPadding.right,
            top: Responsive.of(context).contentPadding.top,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.settingsJsonContents,
                style: TextStyle(
                  fontSize: Responsive.of(context).bodyFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_settingsPath != null) ...[
                SizedBox(
                    height: Responsive.of(context).isTablet ? 12 : 8),
                Text(
                  'Path: $_settingsPath',
                  style: TextStyle(
                    fontSize:
                        Responsive.of(context).bodyFontSize - 4,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              SizedBox(
                  height: Responsive.of(context).isTablet ? 24 : 16),
              if (_error != null)
                Container(
                  padding:
                      Responsive.of(context).contentPadding,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius:
                        Responsive.of(context).cardBorderRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error,
                          color: Colors.red.shade600, size: iconSize),
                      SizedBox(
                          width:
                              Responsive.of(context).isTablet ? 12 : 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize:
                                Responsive.of(context).bodyFontSize -
                                    4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                  height: Responsive.of(context).isTablet ? 24 : 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      padding:
                          Responsive.of(context).contentPadding,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border:
                            Border.all(color: Colors.grey.shade300),
                        borderRadius:
                            Responsive.of(context).cardBorderRadius,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _settingsContent.isEmpty
                              ? '{}'
                              : _settingsContent,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize:
                                Responsive.of(context).bodyFontSize -
                                    6,
                          ),
                        ),
                      ),
                    ),
              Divider(
                  height: Responsive.of(context).isTablet ? 40 : 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.recentLogs,
                      style: TextStyle(
                        fontSize: Responsive.of(context).bodyFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: iconSize),
                    onPressed: _copyLogsToClipboard,
                    tooltip: localizations.copyToClipboard,
                  ),
                ],
              ),
              if (AppLogger.logFilePath != null)
                Text(
                  'Path: ${AppLogger.logFilePath}',
                  style: TextStyle(
                    fontSize:
                        Responsive.of(context).bodyFontSize - 4,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
              SizedBox(
                  height: Responsive.of(context).isTablet ? 12 : 8),
              Container(
                width: double.infinity,
                height: Responsive.of(context).isTablet ? 400 : 300,
                padding: Responsive.of(context).contentPadding,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius:
                      Responsive.of(context).cardBorderRadius,
                ),
                child: SingleChildScrollView(
                  reverse: true, // newest entries at the bottom, visible first
                  child: SelectableText(
                    AppLogger.recentLines.join('\n'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.black87,
                      fontSize:
                          Responsive.of(context).bodyFontSize - 8,
                    ),
                  ),
                ),
              ),
              Divider(
                  height: Responsive.of(context).isTablet ? 40 : 32),
              // DB path — from AppState instead of DBConnectionManager
              _buildInfoTile(
                title: localizations.databasePath,
                icon: Icons.storage_outlined,
                subtitle: appState.currentDbPath ??
                    localizations.notAvailable,
                iconSize: iconSize,
                isTablet: Responsive.of(context).isTablet,
              ),
              // Connection status — AppState.isReady replaces db?.isOpen
              _buildInfoTile(
                title: localizations.connectionStatus,
                icon: appState.isReady
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                subtitle: appState.isReady
                    ? localizations.connected
                    : localizations.disconnected,
                iconColor: appState.isReady ? Colors.green : Colors.red,
                iconSize: iconSize,
                isTablet: Responsive.of(context).isTablet,
              ),
              SizedBox(
                  height: Responsive.of(context).isTablet ? 24 : 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: Responsive.of(context).iconSize(baseSize: 16),
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(
                      width:
                          Responsive.of(context).isTablet ? 12 : 8),
                  Expanded(
                    child: Text(
                      localizations.debugMenuDescription,
                      style: TextStyle(
                        fontSize:
                            Responsive.of(context).bodyFontSize - 6,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      leading: Icon(icon, color: iconColor, size: iconSize),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.of(context).bodyFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: Responsive.of(context).bodyFontSize - 6),
      ),
    );
  }
}