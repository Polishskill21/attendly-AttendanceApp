import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

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
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    final iconSize = ResponsiveUtils.getIconSize(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.help,
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
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
          padding: ResponsiveUtils.getContentPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: ResponsiveUtils.getIconSize(context, baseSize: 56), color: Theme.of(context).primaryColor),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                loc.openUserManual,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_lastError != null) ...[
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  _lastError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    color: Colors.red,
                  ),
                ),
              ],
              SizedBox(height: isTablet ? 24 : 16),
              SizedBox(
                width: isTablet ? 260 : 220,
                height: ResponsiveUtils.getButtonHeight(context),
                child: ElevatedButton.icon(
                  onPressed: _opening ? null : _openExternally,
                  icon: _opening
                      ? SizedBox(
                          width: ResponsiveUtils.getIconSize(context, baseSize: 18),
                          height: ResponsiveUtils.getIconSize(context, baseSize: 18),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.open_in_new, size: ResponsiveUtils.getIconSize(context, baseSize: 20), color: Colors.white),
                  label: Text(
                    loc.openUserManual,
                    style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                loc.externalPdfAppHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getBodyFontSize(context) - 2,
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