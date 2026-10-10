import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/core/responsive/responsive.dart';

class HelpPage extends StatefulWidget {
  final bool isTablet;

  const HelpPage({super.key, this.isTablet = false});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  bool _opening = false;
  String? _lastError;

  Future<void> _openExternally() async {
    setState(() {
      _opening = true;
      _lastError = null;
    });

    try {
      // Load the PDF from assets
      final data = await rootBundle.load('assets/attendly_docs.pdf');
      final bytes = data.buffer.asUint8List();

      // Write to a temp file so external apps can read it
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/attendly_docs.pdf');
      await file.writeAsBytes(bytes, flush: true);

      // Ask the OS to open with any installed PDF viewer
      final res = await OpenFilex.open(file.path);

      if (res.type != ResultType.done) {
        setState(() => _lastError = res.message);
      }
    } catch (e) {
      setState(() => _lastError = e.toString());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isTablet = widget.isTablet || Responsive.of(context).isTablet;
    final iconSize = Responsive.of(context).iconSize();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.help,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: Responsive.of(context).contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: Responsive.of(context).iconSize(baseSize: 56), color: Theme.of(context).primaryColor),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                loc.openUserManual,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.of(context).bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_lastError != null) ...[
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  _lastError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.of(context).bodyFontSize,
                    color: Colors.red,
                  ),
                ),
              ],
              SizedBox(height: isTablet ? 24 : 16),
              SizedBox(
                width: isTablet ? 260 : 220,
                height: Responsive.of(context).buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _opening ? null : _openExternally,
                  icon: _opening
                      ? SizedBox(
                          width: Responsive.of(context).iconSize(baseSize: 18),
                          height: Responsive.of(context).iconSize(baseSize: 18),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.open_in_new, size: Responsive.of(context).iconSize(baseSize: 20), color: Colors.white),
                  label: Text(
                    loc.openUserManual,
                    style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                loc.externalPdfAppHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.of(context).bodyFontSize - 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}