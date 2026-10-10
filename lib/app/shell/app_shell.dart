import 'package:attendly/app/shell/app_navigation_drawer.dart';
import 'package:attendly/app/shell/app_tab.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/features/daily_log/pages/daily_log_tab.dart';
import 'package:attendly/features/directory/pages/directory_tab.dart';
import 'package:attendly/features/weekly_report/pages/weekly_report_tab.dart';
import 'package:attendly/features/yearly_report/pages/yearly_report_tab.dart';
import 'package:attendly/shared/shell/shell_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The only Scaffold of the tabs: drawer on phones, rail and drawer on
/// tablets. The selected tab provides the app bar, body, FAB and bottom bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static ShellTab _tabFor(AppTab tab) => switch (tab) {
        AppTab.directory => const DirectoryTab(),
        AppTab.dailyLog => const DailyLogTab(),
        AppTab.weeklyReport => const WeeklyReportTab(),
        AppTab.yearlyReport => const YearlyReportTab(),
      };

  static Widget _switcherTransition(Widget child, Animation<double> animation) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(fade);

    return ClipRect(
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final tab = _tabFor(selected);

    final appBar = tab.buildAppBar(context, ref);
    final fab = tab.buildFab(context, ref);
    final bottomBar = tab.buildBottomBar(context, ref);

    // AnimatedSwitcher instead of IndexedStack: only the visible tab stays
    // mounted, so the streams of the other tabs are released.
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      transitionBuilder: _switcherTransition,
      child: KeyedSubtree(
        key: ValueKey(selected),
        child: tab.buildBody(context, ref),
      ),
    );

    if (Responsive.of(context).isTablet) {
      // The app bar and bottom bar sit next to the rail, as before.
      return Scaffold(
        drawer: const AppNavigationDrawer(),
        floatingActionButton: fab,
        body: SafeArea(
          child: Row(
            children: [
              const AppNavigationDrawer(isRailMode: true),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Column(
                  children: [
                    appBar,
                    Expanded(child: body),
                    if (bottomBar != null) bottomBar,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: appBar,
      body: SafeArea(child: body),
      floatingActionButton: fab,
      bottomNavigationBar: bottomBar,
    );
  }
}
