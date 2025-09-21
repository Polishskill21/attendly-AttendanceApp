import 'package:flutter/material.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class RefreshableAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Function? onRefresh;
  final bool isLoading;
  final bool showRefresh;
  final Widget? leading;
  final List<Widget>? actions;
  final bool isTablet;

  const RefreshableAppBar({
    super.key,
    required this.title,
    this.onRefresh,
    required this.isLoading,
    required this.showRefresh,
    this.leading,
    this.actions,
    this.isTablet = false,
  });

  @override
  State<RefreshableAppBar> createState() => _RefreshableAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _RefreshableAppBarState extends State<RefreshableAppBar> {
  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    final titleFontSize = isTablet ? 28.0 : 20.0;
    final iconSize = isTablet ? 32.0 : 24.0;

    return AppBar(
      automaticallyImplyLeading: !isTablet,
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: widget.leading,
      actions: [
        if (widget.showRefresh && widget.onRefresh != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: widget.isLoading
                ? Transform.scale(
                    key: const ValueKey('loading'),
                    scale: isTablet ? 0.7 : 0.5,
                    child: const CircularProgressIndicator(),
                  )
                : IconButton(
                    key: const ValueKey('refresh'),
                    icon: Icon(Icons.refresh, size: iconSize),
                    onPressed: widget.isLoading ? null : () => widget.onRefresh?.call(),
                    tooltip: 'Refresh',
                  ),
          ),
        if (widget.actions != null) ...widget.actions!,
      ],
    );
  }
}
