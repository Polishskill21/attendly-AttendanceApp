import 'package:attendly/features/daily_log/pages/daily_log_tab.dart';
import 'package:attendly/features/directory/pages/directory_tab.dart';
import 'package:attendly/features/weekly_report/pages/weekly_report_tab.dart';
import 'package:attendly/features/yearly_report/pages/yearly_report_tab.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/app/shell/app_navigation_drawer.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  
  const AppShell({super.key});

  @override
  State<StatefulWidget> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedTab = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // After the first frame, switch from empty to the real page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedTab = 0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabChange(int index) {
    if (index == _selectedTab) return;

    setState(() => _selectedTab = index);
  }

  Widget _switcherTransition(Widget child, Animation<double> animation) {
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
  Widget build(BuildContext context) {
    final isTablet = Responsive.of(context).isTablet;
    if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildPhoneLayout();
    }
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      drawer: AppNavigationDrawer(
          selectedTab: _selectedTab, onTabChange: _onTabChange),
      body: SafeArea(child: _animatedBody()),
    );
  }
 
  Widget _buildTabletLayout() {
    return Scaffold(
      drawer: AppNavigationDrawer(
          selectedTab: _selectedTab, onTabChange: _onTabChange),
      body: SafeArea(
        child: Row(
          children: [
            AppNavigationDrawer(
                selectedTab: _selectedTab,
                onTabChange: _onTabChange,
                isRailMode: true),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _animatedBody()),
          ],
        ),
      ),
    );
  }
 
  Widget _animatedBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      transitionBuilder: _switcherTransition,
      child: _buildPageForTab(_selectedTab),
    );
  }

  Widget _buildPageForTab(int tabIndex) {
    switch (tabIndex) {
      case -1: // Add this case
        return Container(key: const ValueKey('initial_empty'));
      case 0:
        return DirectoryTab(
          isSelectionMode: false,
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
        );
      case 1:
        return DailyLogTab(
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
        );
      case 2:
        return WeeklyReportTab(
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
        );
      case 3:
        return YearlyReportTab(
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
        );
      default:
        return Container(key: ValueKey('empty_$tabIndex'));
    }
  }
}