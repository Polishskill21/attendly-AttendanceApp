import 'package:attendly/core/responsive/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tab hosted by the app shell. The shell owns the only Scaffold (drawer
/// or rail); a tab contributes its app bar, body and floating action button.
///
/// The build methods run in the shell's build, so providers they watch
/// rebuild the shell. Keep long-lived UI state in providers or inside the
/// body widget, never in the tab object.
abstract class ShellTab {
  const ShellTab();

  PreferredSizeWidget buildAppBar(BuildContext context, WidgetRef ref);

  Widget buildBody(BuildContext context, WidgetRef ref);

  Widget? buildFab(BuildContext context, WidgetRef ref) => null;

  Widget? buildBottomBar(BuildContext context, WidgetRef ref) => null;
}

/// Opens the shell's drawer. Only shown on phones; on tablets the rail has
/// its own menu button.
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  /// The app bar `leading` for a shell tab: the menu button on phones,
  /// nothing on tablets.
  static Widget? forShell(BuildContext context) =>
      Responsive.of(context).isTablet ? null : const DrawerMenuButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Scaffold.of(context).openDrawer(),
      // Bigger drawer icon
      icon: Icon(Icons.menu, size: Responsive.of(context).iconSize(baseSize: 35)),
    );
  }
}
