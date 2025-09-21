import 'package:attendly/backend/manager/connection_manager.dart';
import 'package:attendly/frontend/pages/daily_logs_pages/daily_person_page.dart';
import 'package:attendly/frontend/pages/directory_pages/dir_page.dart';
import 'package:attendly/frontend/pages/weekly_report/weekly_report_page.dart';
import 'package:attendly/frontend/pages/yearly_report/year_stats_page.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class MainApp extends StatefulWidget {
  final Database dbConnection;
  
  const MainApp({super.key, required this.dbConnection});

  @override
  State<StatefulWidget> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late Database _dbConnection;
  int _selectedTab = -1;

  final GlobalKey<WeeklyReportPageState> _weeklyReportKey = GlobalKey();
  final GlobalKey<YearStatsPageState> _yearStatsKey = GlobalKey();
  final GlobalKey<DailyPersonState> _dailyPersonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dbConnection = widget.dbConnection;
    WidgetsBinding.instance.addObserver(this);

    // After the first frame, switch from empty to the real page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedTab = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      await DBConnectionManager.close();
    }
  }

  void _onTabChange(int index) {
    if (index == _selectedTab) return;
    
    setState(() {
      _selectedTab = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentPage();
    });
  }

  void _refreshCurrentPage() {
    switch (_selectedTab) {
      case 1: // Daily Person
        _dailyPersonKey.currentState?.refreshDailyEntries();
        break;
      case 2: // Weekly Report
        _weeklyReportKey.currentState?.fetchWeekData(_weeklyReportKey.currentState!.selectedWeekDate);
        break;
      case 3: // Year Stats
        _yearStatsKey.currentState?.fetchYearStats();
        break;
      default:
        break;
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveUtils.isTablet(context);
    
    SystemChrome.setSystemUIOverlayStyle(
      (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildPhoneLayout();
    }
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      drawer: CustomDrawer(
        selectedTab: _selectedTab,
        onTabChange: _onTabChange,
        isTablet: false,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 550),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            return _switcherTransition(child, animation);
          },
          child: _buildPageForTab(_selectedTab),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      drawer: CustomDrawer(
        selectedTab: _selectedTab,
        onTabChange: _onTabChange,
        isTablet: true,
      ),
      body: SafeArea(
        child: Row(
          children: [
            CustomDrawer(
              selectedTab: _selectedTab,
              onTabChange: _onTabChange,
              isTablet: true,
              isRailMode: true,
            ),
            
            const VerticalDivider(width: 1, thickness: 1),
            
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 550),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return _switcherTransition(child, animation);
                },
                child: _buildPageForTab(_selectedTab, isTablet: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageForTab(int tabIndex, {bool isTablet = false}) {
    switch (tabIndex) {
      case -1: // Add this case
        return Container(key: const ValueKey('initial_empty'));
      case 0:
        return DirectoryPage(
          key: const ValueKey('directory_page'),
          dbCon: _dbConnection,
          isSelectionMode: false,
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
          isTablet: isTablet,
        );
      case 1:
        return DailyPerson(
          key: _dailyPersonKey,
          dbCon: _dbConnection,
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
          isTablet: isTablet,
        );
      case 2:
        return WeeklyReportPage(
          key: _weeklyReportKey,
          dbCon: _dbConnection,
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
          isTablet: isTablet,
        );
      case 3:
        return YearStatsPage(
          key: _yearStatsKey,
          dbCon: _dbConnection,
          selectedTab: _selectedTab,
          onTabChange: _onTabChange,
          isTablet: isTablet,
        );
      default:
        return Container(key: ValueKey('empty_$tabIndex'));
    }
  }
}