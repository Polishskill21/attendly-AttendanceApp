import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/frontend/pages/weekly_report/weekly_list_page.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:attendly/provider/weekly_repo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
// import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/widgets/chart_dialog_helper.dart'; 
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class WeeklyReportPage extends ConsumerStatefulWidget {
  final int selectedTab;
  final void Function(int) onTabChange;
  final bool isTablet;

  const WeeklyReportPage({
    super.key,
    required this.selectedTab,
    required this.onTabChange,
    this.isTablet = false,
  });

  @override
  ConsumerState<WeeklyReportPage> createState() => WeeklyReportPageState();
}

class WeeklyReportPageState extends ConsumerState<WeeklyReportPage> {
  // final HelperAllPerson _helper = HelperAllPerson();
  late DateTime selectedWeekDate;
  bool _statusChanged = false;
  bool _isManualRefreshing = false;


  @override
  void initState() {
    super.initState();
    
    final dbYear = ref.read(databaseManagerProvider).dbYear;
    selectedWeekDate = getFirstDateOfWeek(getScopedDate(dbYear: dbYear));
  }

  void fetchWeekData(DateTime weekDate) {
    ref.invalidate(weeklyReportProvider(weekDate));
  }

  Future<void> _selectWeek() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedWeekDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime val) => val.weekday == DateTime.monday,
      keyboardType: const TextInputType.numberWithOptions(),
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
      setState(() => selectedWeekDate = picked);
    }
  }

  void _changeWeek(int days) {
    setState(() => selectedWeekDate = selectedWeekDate.add(Duration(days: days)));
  }

  // void _updateCountableStatus(bool isCountable) {
  //   if (_weekData != null) {
  //     setState(() {
  //       _weekData = _weekData!.copyWith(countable: isCountable);
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final endDate = selectedWeekDate.add(const Duration(days: 4));
    
    // Watch the specific week's data
    final asyncWeekData = ref.watch(weeklyReportProvider(selectedWeekDate));

    // Handle errors globally via listener
    // ref.listen<AsyncValue<WeeklyEntryData?>>(
    //   weeklyReportProvider(selectedWeekDate),
    //   (previous, next) {
    //     if (next is AsyncError) {
    //       if (next.error is custom_db_exceptions.DbConnectionException) {
    //         DbConnectionValidator.handleConnectionError(context);
    //       } else {
    //         _helper.showErrorMessage(
    //           context, 
    //           'Failed to load week data: ${next.error.toString()}', 
    //           stackTrace: next.stackTrace,
    //         );
    //       }
    //     }
    //   },
    // );
    ref.listen<AsyncValue<WeeklyEntryData?>>(
      weeklyReportProvider(selectedWeekDate),
      (previous, next) {
        if (next is AsyncError) {
          final error = next.error;
          if (error != null && error is! custom_db_exceptions.DatabaseNotReadyException) {
            ref.read(databaseManagerProvider.notifier).reportDatabaseError(error);
          }
        }
      },
    );

    return Scaffold(
      drawer: widget.isTablet
          ? null
          : CustomDrawer(selectedTab: widget.selectedTab, onTabChange: widget.onTabChange),
      appBar: RefreshableAppBar(
        title: localizations.weeklyReport,
        showRefresh: true,
        isLoading: asyncWeekData.isLoading || 
                   asyncWeekData.isReloading || 
                   _isManualRefreshing,
        onRefresh: () async {
          setState(() => _isManualRefreshing = true);
          debugPrint("Invalidating Weekly Stream");
          fetchWeekData(selectedWeekDate); 

          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) setState(() => _isManualRefreshing = false);
        },
        isTablet: widget.isTablet,
        leading: widget.isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(Icons.menu, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                ),
              ),
        actions: [_buildStatusWidget(asyncWeekData)],
      ),
      body: Column(
        children: [
          _buildWeekSelector(endDate),
          Expanded(
            child: asyncWeekData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              // error: (error, _) => Center(
              //   child: ElevatedButton(
              //     onPressed: () => fetchWeekData(selectedWeekDate),
              //     child: const Text("Retry"),
              //   )
              // ),
              error: (error, _) {
                if (error is custom_db_exceptions.DatabaseNotReadyException) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const Center(child: CircularProgressIndicator());
              },
              data: (weekData) => weekData == null
                  ? Center(
                      child: Text(
                        localizations.noDataForThisWeek,
                        style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                      )
                    )
                  : _buildReportView(weekData),
            ),
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

  Widget _buildStatusWidget(AsyncValue<WeeklyEntryData?> asyncWeekData) {
    return asyncWeekData.maybeWhen(
      data: (weekData) {
        if (weekData == null) {
          return const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(width: 24, height: 24),
          );
        }
        final bool isCountable = weekData.countable;
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
      },
      orElse: () => const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: SizedBox(width: 24, height: 24),
      ),
    );
  }


  Future<void> _showWeeksWithData() async {
    _statusChanged = false;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => WeeksListPage(
          currentWeekDate: selectedWeekDate,
          onStatusChanged: (DateTime date, bool newStatus) {
            _statusChanged = true;
          },
        ),
      ),
    );

    if (result != null && mounted) {
      final newSelectedDate = DateTime.parse(result['date']);
      if (newSelectedDate != selectedWeekDate) {
        setState(() => selectedWeekDate = newSelectedDate);
      } else if (_statusChanged) {
        fetchWeekData(selectedWeekDate);
      }
    } else if (_statusChanged && mounted) {
      fetchWeekData(selectedWeekDate);
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

  Widget _buildReportView(WeeklyEntryData weekData) {
    final localizations = AppLocalizations.of(context);
    final int maleWith = weekData.migrationMale;
    final int maleWithout = weekData.openMale - maleWith;
    final int femaleWith = weekData.migrationFemale;
    final int femaleWithout = weekData.openFemale - femaleWith;
    final int diverseWith = weekData.migrationDiverse;
    final int diverseWithout = weekData.openDiverse - diverseWith;

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
              localizations.under10: weekData.under_10,
              localizations.age10to13: weekData.age_10_13,
              localizations.age14to17: weekData.age_14_17,
              localizations.age18to24: weekData.age_18_24,
              localizations.over24: weekData.over_24,
            },
          ),
          _buildSectionCard(
            title: localizations.openGender,
            icon: Icons.meeting_room_outlined,
            data: {
              localizations.male: weekData.openMale,
              localizations.female: weekData.openFemale,
              localizations.diverse: weekData.openDiverse,
            },
          ),
          _buildSectionCard(
            title: localizations.offersGenderTitle,
            icon: Icons.local_offer_outlined,
            data: {
              localizations.male: weekData.offersMale,
              localizations.female: weekData.offersFemale,
              localizations.diverse: weekData.offersDiverse,
            },
          ),
          _buildSectionCard(
            title: localizations.genderTotalTitle,
            icon: Icons.wc,
            data: {
              localizations.male: weekData.allM,
              localizations.female: weekData.allF,
              localizations.diverse: weekData.allD,
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