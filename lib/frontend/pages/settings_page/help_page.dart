import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  late PdfControllerPinch _pdfController;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openAsset('assets/attendly_docs.pdf'),
        initialPage: 1,
      );
    } catch (e) {
      _error = true;
    }
  }

  @override
  void dispose() {
    if (!_error) {
      _pdfController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.help),
        actions: _error
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _initController();
                    });
                  },
                  tooltip: loc.retry,
                ),
              ],
      ),
      body: _error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(loc.noData),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = false;
                        _initController();
                      });
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            )
          : PdfViewPinch(
              controller: _pdfController,
              onDocumentError: (err) {
                if (mounted) {
                  setState(() {
                    _error = true;
                  });
                }
              },
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(loc.loading),
                    ],
                  ),
                ),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${loc.errorOccurred}\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}