import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangelogHelper {
  static const String _versionKey = 'last_seen_version';

  static Future<void> presentChangelogIfNew(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    
    final currentVersion = packageInfo.version;
    final lastSeenVersion = prefs.getString(_versionKey);

    if (lastSeenVersion != currentVersion) {
      if (context.mounted) {
        await _showUpdateDialog(context, currentVersion);
      }
      await prefs.setString(_versionKey, currentVersion);
    }
  }

  static Future<void> _showUpdateDialog(BuildContext context, String version) async {
    String markdownContent;
    try {
      markdownContent = await rootBundle.loadString('assets/changelogs/$version.md');
    } catch (e) {
      return; 
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text("What's New in v$version"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            child: MarkdownWidget(
              data: markdownContent,
              shrinkWrap: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}