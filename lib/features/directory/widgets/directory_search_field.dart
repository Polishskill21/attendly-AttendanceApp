import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Name search above the directory list.
class DirectorySearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const DirectorySearchField({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    return Padding(
      padding: responsive.listPadding,
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: responsive.bodyFontSize),
        decoration: InputDecoration(
          labelText: localizations.searchForName,
          labelStyle: TextStyle(fontSize: responsive.bodyFontSize),
          contentPadding: responsive.contentPadding,
          border: OutlineInputBorder(borderRadius: responsive.cardBorderRadius),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel, size: responsive.iconSize()),
            onPressed: onClear,
          ),
        ),
      ),
    );
  }
}
