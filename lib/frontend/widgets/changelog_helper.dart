import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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

  static Future<void> showDirectly(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
      await _showUpdateDialog(context, packageInfo.version);
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
      final isTablet = ResponsiveUtils.isTablet(context);
      
      final double bodySize = isTablet ? 20.0 : 15.0; 
      final double codeSize = isTablet ? 20.0 : 15.0;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text("What's New in v$version"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Markdown(
              data: markdownContent,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                // 1. All Body Text & List Items
                p: TextStyle(
                  fontSize: bodySize,
                  height: 1.4,
                ),

                code: TextStyle(
                  fontSize: codeSize,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                ),

                // 3. Bullet points / List Numbers
                listBullet: TextStyle(fontSize: bodySize),
                listBulletPadding: const EdgeInsets.only(right: 8, top: 2),

                // 5. Headers - Reduced for Mobile
                h1: TextStyle(fontSize: isTablet ? 28.0 : 20.0, fontWeight: FontWeight.bold),
                h3: TextStyle(fontSize: isTablet ? 22.0 : 16.0, fontWeight: FontWeight.bold),
                h4: TextStyle(fontSize: isTablet ? 20.0 : 14.0, fontWeight: FontWeight.bold),

                // Horizontal Line
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
                ),
              ),
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