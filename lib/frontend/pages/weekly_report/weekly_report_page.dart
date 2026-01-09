import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/frontend/pages/weekly_report/weekly_list_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/widgets/chart_dialog_helper.dart'; 
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class WeeklyReportPage extends StatefulWidget {
  final Database dbCon;
  final int selectedTab;
  final void Function(int) onTabChange;
  final bool isTablet;

  const WeeklyReportPage({
    super.key,
    required this.dbCon,
    required this.selectedTab,
    required this.onTabChange,
    this.isTablet = false,
  });

  @override
  State<StatefulWidget> createState() => WeeklyReportPageState();
}

class WeeklyReportPageState extends State<WeeklyReportPage> {
  late DbSelection _reader;
  late DbUpdater _updater;
  late HelperAllPerson _helper;
  DateTime selectedWeekDate = getFirstDateOfWeek(getScopedDate());
  Map<String, dynamic>? _weekData;
  bool _isLoading = true; 
  bool _isFetching = false;
  bool _statusChanged = false;

  @override
  void initState() {
    super.initState();
    _reader = DbSelection(widget.dbCon);
    _updater = DbUpdater(widget.dbCon, _reader);
    _helper = HelperAllPerson();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchWeekData(selectedWeekDate);
    });
  }

  Future<void> fetchWeekData(DateTime weekDate) async {
    setState(() {
      _isFetching = true;
    });

    try {
      final weekDateStr = dateToString(weekDate);
      final data = await _reader.getDataFromCurrentWeek(weekDateStr);
      if (mounted) {
        setState(() {
          _weekData = data.isNotEmpty ? Map<String, dynamic>.from(data.first) : null;
          _isLoading = false; 
          _isFetching = false;
        });
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetching = false;
        });
        await DbConnectionValidator.handleConnectionError(context);
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching week data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetching = false;
        });
        _helper.showErrorMessage(
            context, 'Failed to load week data: ${e.toString()}', stackTrace: stackTrace);
      }
    }
  }

  Future<void> _selectWeek() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedWeekDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime val) => val.weekday == DateTime.monday,
      keyboardType: TextInputType.numberWithOptions(),
      builder: (context, child) {
        if (!widget.isTablet || child == null) return child ?? const SizedBox.shrink();

       final mq = MediaQuery.of(context);
       final currentScale = mq.textScaler.scale(1.0);
       final newScale = (currentScale * 1.2).clamp(1.0, 1.6);
       
       return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(newScale),
          ),
          child: Transform.scale(
            scale: 1.1,
            child: child,
          ),
        );
      },
    );

    if (picked != null && picked != selectedWeekDate) {
      setState(() {
        selectedWeekDate = picked;
      });
      await fetchWeekData(selectedWeekDate);
    }
  }

  void _changeWeek(int days) {
    setState(() {
      selectedWeekDate = selectedWeekDate.add(Duration(days: days));
      fetchWeekData(selectedWeekDate);
    });
  }

  void _updateCountableStatus(bool isCountable) {
    if (_weekData != null) {
      setState(() {
        _weekData!['countable'] = isCountable ? 1 : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final endDate = selectedWeekDate.add(const Duration(days: 4));

    Widget statusWidget = _buildStatusWidget();

    return Scaffold(
      drawer: widget.isTablet
          ? null
          : CustomDrawer(
              selectedTab: widget.selectedTab,
              onTabChange: widget.onTabChange,
            ),
      appBar: RefreshableAppBar(
        title: localizations.weeklyReport,
        onRefresh: null,
        isLoading: _isFetching,
        showRefresh: false,
        isTablet: widget.isTablet,
        leading: widget.isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  // Bigger drawer icon
                  icon: Icon(Icons.menu, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                ),
              ),
        actions: [statusWidget],
      ),
      body: Column(
        children: [
          _buildWeekSelector(endDate),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _weekData == null
                    ? Center(
                        child: Text(
                          localizations.noDataForThisWeek,
                          style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                        )
                      )
                    : _buildReportView(),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: ResponsiveUtils.getButtonHeight(context) + 25,
        height: ResponsiveUtils.getButtonHeight(context) + 25,
        child: FloatingActionButton(
          onPressed: _showWeeksWithData,
          tooltip: localizations.showWeeksWithDataTooltip,
          child: Icon(Icons.list_alt, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    // While fetching, the main app bar shows a loading indicator.
    // Here, we just show the icon based on the current data.
    if (_isFetching || _weekData == null) {
      // Return a fixed-size box to prevent layout shifts during loading.
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: SizedBox(width: 24, height: 24),
      );
    }

    final bool isCountable = (_weekData!['countable'] ?? 0) == 1;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Icon(
          key: ValueKey<bool>(isCountable),
          isCountable ? Icons.check_circle : Icons.cancel_outlined,
          color: isCountable ? Colors.green : Colors.red,
          size: ResponsiveUtils.getIconSize(context, baseSize: 24),
        ),
      ),
    );
  }


Future<void> _showWeeksWithData() async {
    _statusChanged = false; // Reset the flag
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => WeeksListPage(
          reader: _reader,
          updater: _updater,
          // Pass the currently displayed week date to the list page
          currentWeekDate: dateToString(selectedWeekDate),
          // Pass the new callback function
          onStatusChanged: (date, newStatus) {
            _statusChanged = true; // Mark that a change occurred
            // If the status of the currently viewed week was changed, update it
            if (date == dateToString(selectedWeekDate)) {
              _updateCountableStatus(newStatus);
            }
          },
        ),
      ),
    );

    // This handles the case where the user taps a week to navigate to it
    if (result != null && mounted) {
      final newSelectedDate = DateTime.parse(result['date']);
      if (newSelectedDate != selectedWeekDate) {
        setState(() {
          selectedWeekDate = newSelectedDate;
        });
        await fetchWeekData(selectedWeekDate);
      } else if (_statusChanged) {
        // If the same week was re-selected but status changed, refresh
        await fetchWeekData(selectedWeekDate);
      }
    } else if (_statusChanged && mounted) {
      // If no week was selected but a status changed, refresh the current week's data
      await fetchWeekData(selectedWeekDate);
    }
  }

  Widget _buildWeekSelector(DateTime endDate) {
    final canGoForward = selectedWeekDate.isBefore(getFirstDateOfWeek(getScopedDate()));
    final arrowSize = ResponsiveUtils.getIconSize(context, baseSize: 30);
    final listPad = ResponsiveUtils.getListPadding(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeWeek(-7),
          icon: const Icon(Icons.arrow_back_ios_sharp),
          iconSize: arrowSize,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: listPad.vertical * 2),
          child: GestureDetector(
            onTap: _selectWeek,
            child: Text(
              "${DateFormat('dd.MM.yyyy').format(selectedWeekDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: canGoForward ? () => _changeWeek(7) : null,
          icon: const Icon(Icons.arrow_forward_ios_sharp),
          iconSize: arrowSize,
        ),
      ],
    );
  } 

  Widget _buildReportView() {
    final localizations = AppLocalizations.of(context);
    final int maleWith = _weekData!['migration_male'] ?? 0;
    final int maleWithout = (_weekData!['open_male'] ?? 0) - maleWith;
    final int femaleWith = _weekData!['migration_female'] ?? 0;
    final int femaleWithout = (_weekData!['open_female'] ?? 0) - femaleWith;
    final int diverseWith = _weekData!['migration_diverse'] ?? 0;
    final int diverseWithout = (_weekData!['open_diverse'] ?? 0) - diverseWith;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.getListPadding(context).left,
        ResponsiveUtils.getListPadding(context).top,
        ResponsiveUtils.getListPadding(context).right,
        ResponsiveUtils.getButtonHeight(context) + 40 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          _buildSectionCard(
            title: localizations.ageGroupsTitle,
            icon: Icons.cake_outlined,
            data: {
              localizations.under10: _weekData!['under_10'],
              localizations.age10to13: _weekData!['age_10_13'],
              localizations.age14to17: _weekData!['age_14_17'],
              localizations.age18to24: _weekData!['age_18_24'],
              localizations.over24: _weekData!['over_24'],
            },
          ),
          _buildSectionCard(
            title: localizations.openGender,
            icon: Icons.meeting_room_outlined,
            data: {
              localizations.male: _weekData!['open_male'],
              localizations.female: _weekData!['open_female'],
              localizations.diverse: _weekData!['open_diverse'],
            },
          ),
          _buildSectionCard(
            title: localizations.offersGenderTitle,
            icon: Icons.local_offer_outlined,
            data: {
              localizations.male: _weekData!['offers_male'],
              localizations.female: _weekData!['offers_female'],
              localizations.diverse: _weekData!['offers_diverse'],
            },
          ),
          _buildSectionCard(
            title: localizations.genderTotalTitle,
            icon: Icons.wc,
            data: {
              localizations.male: _weekData!['all_m'],
              localizations.female: _weekData!['all_f'],
              localizations.diverse: _weekData!['all_d'],
            },
          ),
          _buildMigrationSectionCard(
            title: localizations.migrationBackgroundGender,
            icon: Icons.public_outlined,
            maleWith: maleWith,
            maleWithout: maleWithout,
            femaleWith: femaleWith,
            femaleWithout: femaleWithout,
            diverseWith: diverseWith,
            diverseWithout: diverseWithout,
          ),
        ],
      ),
    );
  }

Widget _buildMigrationSectionCard({
  required String title,
  required IconData icon,
  required int maleWith,
  required int maleWithout,
  required int femaleWith,
  required int femaleWithout,
  required int diverseWith,
  required int diverseWithout,
}) {
  final theme = Theme.of(context);
  final cardColor = theme.cardTheme.color ?? theme.cardColor;
  final iconColor = theme.primaryColor;
  final localizations = AppLocalizations.of(context);

  return Card(
    color: cardColor,
    margin: EdgeInsets.only(bottom: ResponsiveUtils.getListPadding(context).vertical * 4),
    elevation: ResponsiveUtils.getCardElevation(context),
    shape: RoundedRectangleBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
    child: Padding(
      padding: ResponsiveUtils.getContentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: ResponsiveUtils.getIconSize(context)),
              SizedBox(width: ResponsiveUtils.getListPadding(context).horizontal / 2 + 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildMigrationGenderRow(
            gender: localizations.male,
            withCount: maleWith,
            withoutCount: maleWithout,
            localizations: localizations,
          ),
          const Divider(height: 12),
          _buildMigrationGenderRow(
            gender: localizations.female,
            withCount: femaleWith,
            withoutCount: femaleWithout,
            localizations: localizations,
          ),
          const Divider(height: 12),
          _buildMigrationGenderRow(
            gender: localizations.diverse,
            withCount: diverseWith,
            withoutCount: diverseWithout,
            localizations: localizations,
          ),
        ],
      ),
    ),
  );
}

Widget _buildMigrationGenderRow({
  required String gender,
  required int withCount,
  required int withoutCount,
  required AppLocalizations localizations,
}) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              gender,
              style: TextStyle(
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.pie_chart, size: ResponsiveUtils.getIconSize(context)),
            onPressed: (withCount + withoutCount > 0)
                ? () => ChartDialogHelper.showChartDialog(
                      context,
                      title: '${localizations.migrationBackground}: $gender',
                      data: {
                        localizations.withAbbreviation: withCount,
                        localizations.withoutAbbreviation: withoutCount,
                      },
                    )
                : null,
          ),
        ],
      ),
      _buildDataRow('${localizations.withAbbreviation} ${localizations.migration}', withCount),
      _buildDataRow('${localizations.withoutAbbreviation} ${localizations.migration}', withoutCount),
    ],
  );
}

Widget _buildSectionCard({
  required String title,
  required IconData icon,
  required Map<String, int> data,
}) {
  final theme = Theme.of(context);
  final cardColor = theme.cardTheme.color ?? theme.cardColor;

  return Card(
    color: cardColor,
    margin: EdgeInsets.only(bottom: ResponsiveUtils.getListPadding(context).vertical * 3),
    elevation: ResponsiveUtils.getCardElevation(context),
    shape: RoundedRectangleBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
    child: Padding(
      padding: ResponsiveUtils.getContentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: ResponsiveUtils.getIconSize(context)),
              SizedBox(width: ResponsiveUtils.getListPadding(context).horizontal / 2  + 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.pie_chart, size: ResponsiveUtils.getIconSize(context)),
                onPressed: () => ChartDialogHelper.showChartDialog(
                  context,
                  title: title,
                  data: data,
                ),
              )
            ],
          ),
          const Divider(height: 24),
          ...data.entries.map((e) => _buildDataRow(e.key, e.value)),
        ],
      ),
    ),
  );
}

Widget _buildDataRow(String label, dynamic value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getListPadding(context).vertical / 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    ),
  );
}

}