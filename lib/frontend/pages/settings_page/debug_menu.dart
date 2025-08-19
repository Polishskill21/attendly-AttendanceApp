import 'dart:convert';
import 'dart:io';
import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
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

    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(localizations.debugSettings),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyToClipboard,
                tooltip: localizations.copyToClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSettingsFile,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.settingsJsonContents,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_settingsPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Path: $_settingsPath',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _settingsContent.isEmpty
                                  ? '{}'
                                  : _settingsContent,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: Text(localizations.databasePath),
                    subtitle: Text(
                      DBConnectionManager.filePath ??
                          localizations.notAvailable,
                      style: const TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: Icon(
                      DBConnectionManager.db?.isOpen ?? false
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: DBConnectionManager.db?.isOpen ?? false
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(localizations.connectionStatus),
                    subtitle: Text(DBConnectionManager.db?.isOpen ?? false
                        ? localizations.connected
                        : localizations.disconnected),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.debugMenuDescription,
                          style: TextStyle(
                            fontSize: 12,
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
        ));
  }
}

//import 'dart:convert';
//import 'dart:io';
//import 'package:attendly/backend/manager/storage_manager.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'package:attendly/frontend/l10n/app_localizations.dart';
//import 'package:path/path.dart' as p;

//class DebugMenu extends StatefulWidget {
  //const DebugMenu({super.key});

  //@override
  //State<StatefulWidget> createState() => _DebugMenuState();
//}

//class _DebugMenuState extends State<DebugMenu> {
  //String _settingsContent = '';
  //bool _isLoading = true;
  //String? _error;
  //String? _settingsPath;

  //@override
  //void initState() {
    //super.initState();
    //_loadSettingsFile();
  //}

  //Future<void> _loadSettingsFile() async {
    //setState(() {
      //_isLoading = true;
      //_error = null;
    //});

    //try {
      //// Use the same directory logic as your app
      //final directory = await StorageManager.getExternalDirectory();
      //if (directory == null) {
        //setState(() {
          //_error = 'Could not access external directory';
          //_isLoading = false;
        //});
        //return;
      //}

      //final settingsFile = File(p.join(directory.path, 'settings.json'));
      //_settingsPath = settingsFile.path;
      
      //if (await settingsFile.exists()) {
        //final content = await settingsFile.readAsString();
        
        //if (content.trim().isEmpty) {
          //setState(() {
            //_settingsContent = '{}';
            //_error = 'Settings file is empty';
            //_isLoading = false;
          //});
          //return;
        //}

        //try {
          //// Pretty print JSON
          //final jsonObject = jsonDecode(content);
          //final prettyString = JsonEncoder.withIndent('  ').convert(jsonObject);
          
          //setState(() {
            //_settingsContent = prettyString;
            //_isLoading = false;
          //});
        //} catch (jsonError) {
          //setState(() {
            //_settingsContent = content; // Show raw content if JSON parsing fails
            //_error = 'JSON parsing error: $jsonError';
            //_isLoading = false;
          //});
        //}
      //} else {
        //setState(() {
          //_settingsContent = '{}';
          //_error = 'Settings file does not exist at: ${settingsFile.path}';
          //_isLoading = false;
        //});
      //}
    //} catch (e) {
      //setState(() {
        //_error = 'Error reading settings file: $e';
        //_isLoading = false;
      //});
    //}
  //}

  //void _copyToClipboard() {
    //final localizations = AppLocalizations.of(context);
    //final contentToCopy = _settingsPath != null 
        //? 'Path: $_settingsPath\n\n$_settingsContent'
        //: _settingsContent;
    
    //Clipboard.setData(ClipboardData(text: contentToCopy));
    //ScaffoldMessenger.of(context).showSnackBar(
      //SnackBar(content: Text(localizations.settingsCopiedToClipboard)),
    //);
  //}

  //@override
  //Widget build(BuildContext context) {
    //final localizations = AppLocalizations.of(context);
    
    //return PopScope(
      //onPopInvokedWithResult: (didPop, result) {
        //ScaffoldMessenger.of(context).hideCurrentSnackBar();
      //},
      //child: Scaffold(
      //appBar: AppBar(
        //title: Text(localizations.debugSettings),
        //actions: [
          //IconButton(
            //icon: const Icon(Icons.copy),
            //onPressed: _copyToClipboard,
            //tooltip: localizations.copyToClipboard,
          //),
          //IconButton(
            //icon: const Icon(Icons.refresh),
            //onPressed: _loadSettingsFile,
            //tooltip: 'Refresh',
          //),
        //],
      //),
      //body: Padding(
        //padding: const EdgeInsets.all(16.0),
        //child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,
          //children: [
            //Text(
              //localizations.settingsJsonContents,
              //style: Theme.of(context).textTheme.titleLarge?.copyWith(
                //fontWeight: FontWeight.bold,
              //),
            //),
            //if (_settingsPath != null) ...[
              //const SizedBox(height: 8),
              //Text(
                //'Path: $_settingsPath',
                //style: TextStyle(
                  //fontSize: 12,
                  //fontFamily: 'monospace',
                  //color: Colors.grey.shade600,
                //),
              //),
            //],
            //const SizedBox(height: 16),
            //if (_error != null)
              //Container(
                //padding: const EdgeInsets.all(12),
                //decoration: BoxDecoration(
                  //color: Colors.red.shade50,
                  //border: Border.all(color: Colors.red.shade200),
                  //borderRadius: BorderRadius.circular(8),
                //),
                //child: Row(
                  //children: [
                    //Icon(Icons.error, color: Colors.red.shade600),
                    //const SizedBox(width: 8),
                    //Expanded(
                      //child: Text(
                        //_error!,
                        //style: TextStyle(color: Colors.red.shade700),
                      //),
                    //),
                  //],
                //),
              //),
            //const SizedBox(height: 16),
            //Expanded(
              //child: _isLoading
                  //? const Center(child: CircularProgressIndicator())
                  //: Container(
                      //width: double.infinity,
                      //padding: const EdgeInsets.all(16),
                      //decoration: BoxDecoration(
                        //color: Colors.grey.shade100,
                        //border: Border.all(color: Colors.grey.shade300),
                        //borderRadius: BorderRadius.circular(8),
                      //),
                      //child: SingleChildScrollView(
                        //child: SelectableText(
                          //_settingsContent.isEmpty ? '{}' : _settingsContent,
                          //style: const TextStyle(
                            //fontFamily: 'monospace',
                            //fontSize: 14,
                          //),
                        //),
                      //),
                    //),
            //),
            //const SizedBox(height: 16),
            //Row(
              //children: [
                //Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                //const SizedBox(width: 8),
                //Expanded(
                  //child: Text(
                    //localizations.debugMenuDescription,
                    //style: TextStyle(
                      //fontSize: 12,
                      //color: Colors.grey.shade600,
                    //),
                  //),
                //),
              //],
            //),
          //],
        //),
      //),
    //)
    //);
  //}
//}
