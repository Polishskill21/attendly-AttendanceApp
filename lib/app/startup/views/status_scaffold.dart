import 'package:attendly/core/responsive/responsive.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Centered icon, title, message and action buttons, shared by the startup
/// screens that need the user to do something.
class StatusScaffold extends StatelessWidget {
  final Widget icon;
  final String title;
  final String message;
  final String? details;
  final List<Widget> actions;

  const StatusScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.details,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 30.0 : 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(height: isTablet ? 30 : 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                message,
                style: TextStyle(fontSize: isTablet ? 18 : 16),
                textAlign: TextAlign.center,
              ),
              if (details != null) ...[
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  details!,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: isTablet ? 40 : 30),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: isTablet ? 20 : 12,
                runSpacing: isTablet ? 16 : 12,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White-on-primary button with a spinner while [isBusy].
class StartupActionButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isBusy;
  final VoidCallback? onPressed;

  const StartupActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isBusy = false,
  });

  /// The database icon used by "Create database" / "Create new".
  static Widget databaseIcon(BuildContext context) => FaIcon(
        FontAwesomeIcons.database,
        size: ResponsiveUtils.isTablet(context) ? 22 : 18,
        color: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return ElevatedButton.icon(
      onPressed: isBusy ? null : onPressed,
      label: isBusy
          ? SizedBox(
              height: isTablet ? 24 : 20,
              width: isTablet ? 24 : 20,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.white,
              ),
            ),
      icon: isBusy ? const SizedBox.shrink() : icon,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 16 : 12,
        ),
      ),
    );
  }
}
