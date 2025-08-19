import 'package:flutter/material.dart';

class RefreshableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final bool showRefresh;
  final Widget? leading;
  final List<Widget>? actions;

  const RefreshableAppBar({
    super.key,
    required this.title,
    this.onRefresh,
    this.isLoading = false,
    this.showRefresh = true,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: [
        if (showRefresh)
          IconButton(
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
