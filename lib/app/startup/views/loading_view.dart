import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Shown while startup is doing real work (permission check, opening the
/// database). The native splash covers the engine start before this.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.95, end: 1.10).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.of(context).isTablet;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: FaIcon(FontAwesomeIcons.childReaching,
                  size: isTablet ? 130.0 : 100.0, color: Theme.of(context).primaryColor),
            ),
            SizedBox(height: isTablet ? 30 : 20),
            Text(localizations.attendly,
                style: TextStyle(
                    fontSize: isTablet ? 34 : 28,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: isTablet ? 40 : 30),
            SizedBox(
              width: isTablet ? 40 : 30,
              height: isTablet ? 40 : 30,
              child: CircularProgressIndicator(strokeWidth: isTablet ? 4.0 : 3.0),
            ),
            SizedBox(height: isTablet ? 30 : 20),
            Text(localizations.initializing,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isTablet ? 20 : 16)),
          ],
        ),
      ),
    );
  }
}
