import 'package:flutter/material.dart';
import 'package:attendly/core/responsive/responsive.dart';

/// App bar of a shell tab: bold title sized for phone or tablet.
class TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const TabAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.of(context).isTablet;

    return AppBar(
      automaticallyImplyLeading: !isTablet,
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? 28.0 : 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: leading,
      actions: actions,
    );
  }
}
