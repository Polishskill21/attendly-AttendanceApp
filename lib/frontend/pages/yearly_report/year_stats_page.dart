import 'package:attendly/data/local/config/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/frontend/pages/yearly_report/year_stats_model.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:attendly/provider/yearly_repo_provider.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/widgets/chart_dialog_helper.dart'; 
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YearStatsPage extends ConsumerStatefulWidget {
  final int selectedTab;
  final void Function(int) onTabChange;
  final bool isTablet;

  const YearStatsPage({
    super.key,
    required this.selectedTab,
    required this.onTabChange,
    required this.isTablet
  });

  @override
  ConsumerState<YearStatsPage> createState() => YearStatsPageState();
}

class YearStatsPageState extends ConsumerState<YearStatsPage> {
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
  }

  void fetchYearStats() {
    ref.invalidate(yearlyStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final asyncStats = ref.watch(yearlyStatsProvider);

    return Scaffold(
      drawer: widget.isTablet
          ? null
          : CustomDrawer(
              selectedTab: widget.selectedTab,
              onTabChange: widget.onTabChange,
            ),
      appBar: RefreshableAppBar(
        title: localizations.yearlyStats,
        showRefresh: true,
        isLoading: asyncStats.isLoading || 
                   asyncStats.isReloading || 
                   _isManualRefreshing, 
        onRefresh: () async {
          setState(() => _isManualRefreshing = true);
          debugPrint("Invalidating Yearly Stream");
          fetchYearStats(); 

          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) setState(() => _isManualRefreshing = false);
        },
        isTablet: widget.isTablet,
        leading: widget.isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(Icons.menu,
                      size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                ),
              ),
      ),
      body: asyncStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error, stack),
        data: (statsModel) {
          if (statsModel == null) {
            return Center(
              child: Text(
                localizations.noDataForThisYear,
                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
              ),
            );
          }
          return _buildReportView(statsModel);
        },
      ),
    );
  }

  Widget _buildErrorState(Object error, StackTrace stackTrace) {

    // // Check for your specific custom exceptions
    // if (error is custom_db_exceptions.DatabaseOperationException) {
    //   displayMessage = error.message;
    // } else if (error is custom_db_exceptions.DbConnectionException) {
    //   displayMessage = "Database connection lost. Please try again.";
    // }

    if (error is custom_db_exceptions.DatabaseNotReadyException) {
      return const Center(child: CircularProgressIndicator());
    }
    
    String displayMessage = "An unexpected error occurred.";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(databaseManagerProvider.notifier).reportDatabaseError(error);
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveUtils.getIconSize(context, baseSize: 60),
            color: Colors.red,
          ),
          SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 4),
          
          // Display the actual error message dynamically
          Text(
            displayMessage,
            style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
          ElevatedButton(
            onPressed: fetchYearStats, 
            child: Text('Retry', style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView(YearStatsModel statsModel) {
    final localizations = AppLocalizations.of(context);
    final stats = statsModel.stats;
    final weekCount = statsModel.weekCount;

    final int maleWith = (stats['migration_male'] ?? 0) as int;
    final int maleWithout = ((stats['open_male'] ?? 0) as int) - maleWith;
    final int femaleWith = (stats['migration_female'] ?? 0) as int;
    final int femaleWithout = ((stats['open_female'] ?? 0) as int) - femaleWith;
    final int diverseWith = (stats['migration_diverse'] ?? 0) as int;
    final int diverseWithout = ((stats['open_diverse'] ?? 0) as int) - diverseWith;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.getListPadding(context).left,
        ResponsiveUtils.getListPadding(context).top,
        ResponsiveUtils.getListPadding(context).right,
        ResponsiveUtils.getListPadding(context).bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          _buildSectionCard(
            title: localizations.summaryForWeeks(statsModel.weekCount),
            icon: Icons.calendar_today_outlined,
            children: [],
            data: {},
            weekCount: weekCount,
            showChart: false,
          ),
          _buildSectionCard(
            title: localizations.ageGroupsTitle,
            icon: Icons.cake_outlined,
            weekCount: weekCount,
            data: {
              localizations.under10: (stats['under_10'] ?? 0) as int,
              localizations.age10to13: (stats['age_10_13'] ?? 0) as int,
              localizations.age14to17: (stats['age_14_17'] ?? 0) as int,
              localizations.age18to24: (stats['age_18_24'] ?? 0) as int,
              localizations.over24: (stats['over_24'] ?? 0) as int,
            },
            children: [
              _buildDataRow(localizations.under10, stats['under_10'], weekCount),
              _buildDataRow(localizations.age10to13, stats['age_10_13'], weekCount),
              _buildDataRow(localizations.age14to17, stats['age_14_17'], weekCount),
              _buildDataRow(localizations.age18to24, stats['age_18_24'], weekCount),
              _buildDataRow(localizations.over24, stats['over_24'], weekCount),
            ],
          ),
          _buildSectionCard(
            title: localizations.openGender,
            icon: Icons.meeting_room_outlined,
            weekCount: weekCount,
            data: {
              localizations.male: (stats['open_male'] ?? 0) as int,
              localizations.female: (stats['open_female'] ?? 0) as int,
              localizations.diverse: (stats['open_diverse'] ?? 0) as int,
            },
            children: [
              _buildDataRow(localizations.male, stats['open_male'], weekCount),
              _buildDataRow(localizations.female, stats['open_female'], weekCount),
              _buildDataRow(localizations.diverse, stats['open_diverse'], weekCount),
            ],
          ),
          _buildSectionCard(
            title: localizations.offersGenderTitle,
            icon: Icons.local_offer_outlined,
            weekCount: weekCount,
            data: {
              localizations.male: (stats['offers_male'] ?? 0) as int,
              localizations.female: (stats['offers_female'] ?? 0) as int,
              localizations.diverse: (stats['offers_diverse'] ?? 0) as int,
            },
            children: [
              _buildDataRow(localizations.male, stats['offers_male'], weekCount),
              _buildDataRow(localizations.female, stats['offers_female'], weekCount),
              _buildDataRow(localizations.diverse, stats['offers_diverse'], weekCount),
            ],
          ),
          _buildSectionCard(
            title: localizations.genderTotalTitle,
            icon: Icons.wc,
            weekCount: weekCount,
            data: {
              localizations.male: (stats['all_m'] ?? 0) as int,
              localizations.female: (stats['all_f'] ?? 0) as int,
              localizations.diverse: (stats['all_d'] ?? 0) as int,
            },
            children: [
              _buildDataRow(localizations.male, stats['all_m'], weekCount),
              _buildDataRow(localizations.female, stats['all_f'], weekCount),
              _buildDataRow(localizations.diverse, stats['all_d'], weekCount),
            ],
          ),
          _buildMigrationSectionCard(
            title: localizations.migrationBackgroundGender,
            icon: Icons.public_outlined,
            weekCount: weekCount,
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required Map<String, int> data,
    required int weekCount,
    bool showChart = true,
  }) {
    final localizations = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.getListPadding(context).vertical * 3),
      elevation: ResponsiveUtils.getCardElevation(context),
      shape: RoundedRectangleBorder(
          borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
      child: Padding(
        padding: ResponsiveUtils.getContentPadding(context),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                color: Theme.of(context).primaryColor,
                size: ResponsiveUtils.getIconSize(context)),
            SizedBox(
                width: ResponsiveUtils.getListPadding(context).horizontal),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),
            if (showChart && data.isNotEmpty)
              IconButton(
                icon: Icon(Icons.pie_chart,
                    size: ResponsiveUtils.getIconSize(context)),
                onPressed: () => ChartDialogHelper.showChartDialog(context,
                    title: title, data: data),
              ),
          ]),
          if (children.isNotEmpty) ...[
            const Divider(height: 24),
            _buildHeaderRow(),
            ...children,
            const Divider(height: 12, thickness: 1),
            _buildDataRow(localizations.total,
                data.values.fold(0, (a, b) => a + b), weekCount),
          ],
        ]),
      ),
    );
  }

  Widget _buildMigrationSectionCard({
    required String title,
    required IconData icon,
    required int weekCount,
    required int maleWith,
    required int maleWithout,
    required int femaleWith,
    required int femaleWithout,
    required int diverseWith,
    required int diverseWithout,
  }) {
    final localizations = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.getListPadding(context).vertical * 4),
      elevation: ResponsiveUtils.getCardElevation(context),
      shape: RoundedRectangleBorder(
          borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
      child: Padding(
        padding: ResponsiveUtils.getContentPadding(context),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                color: Theme.of(context).primaryColor,
                size: ResponsiveUtils.getIconSize(context)),
            SizedBox(
                width: ResponsiveUtils.getListPadding(context).horizontal),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),
          ]),
          const Divider(height: 24),
          _buildHeaderRow(),
          _buildMigrationGenderRow(
              gender: localizations.male,
              withCount: maleWith,
              withoutCount: maleWithout,
              weekCount: weekCount,
              localizations: localizations),
          const Divider(height: 12),
          _buildMigrationGenderRow(
              gender: localizations.female,
              withCount: femaleWith,
              withoutCount: femaleWithout,
              weekCount: weekCount,
              localizations: localizations),
          const Divider(height: 12),
          _buildMigrationGenderRow(
              gender: localizations.diverse,
              withCount: diverseWith,
              withoutCount: diverseWithout,
              weekCount: weekCount,
              localizations: localizations),
        ]),
      ),
    );
  }

  Widget _buildMigrationGenderRow({
    required String gender,
    required int withCount,
    required int withoutCount,
    required int weekCount,
    required AppLocalizations localizations,
  }) {
    return Column(children: [
      Row(children: [
        Expanded(
          flex: 4,
          child: Text(gender,
              style: TextStyle(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.pie_chart,
                  size: ResponsiveUtils.getIconSize(context)),
              onPressed: (withCount + withoutCount > 0)
                  ? () => ChartDialogHelper.showChartDialog(
                        context,
                        title:
                            '${localizations.migrationBackground}: $gender',
                        data: {
                          localizations.withAbbreviation: withCount,
                          localizations.withoutAbbreviation: withoutCount,
                        },
                      )
                  : null,
            ),
          ),
        ),
      ]),
      _buildDataRow(
          '${localizations.withAbbreviation} ${localizations.migration}',
          withCount,
          weekCount),
      _buildDataRow(
          '${localizations.withoutAbbreviation} ${localizations.migration}',
          withoutCount,
          weekCount),
    ]);
  }

  Widget _buildHeaderRow() {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: ResponsiveUtils.getListPadding(context).vertical / 2),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: Text(localizations.categoryAbbreviation,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getBodyFontSize(context))),
        ),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: localizations.total,
            child: Center(
              child: Icon(Icons.groups_2_outlined,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 35),
                  color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: localizations.average,
            child: Center(
              child: Icon(Icons.show_chart,
                  size: ResponsiveUtils.getIconSize(context),
                  color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDataRow(String label, dynamic value, int weekCount) {
    final total = value ?? 0;
    final avg = weekCount > 0 ? total / weekCount : 0.0;
    final body = ResponsiveUtils.getBodyFontSize(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.getListPadding(context).vertical / 2),
      child: Row(children: [
        Expanded(
            flex: 4, child: Text(label, style: TextStyle(fontSize: body))),
        Expanded(
          flex: 2,
          child: Text(total.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: body,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor)),
        ),
        Expanded(
          flex: 2,
          child: Text(avg.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: body,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary)),
        ),
      ]),
    );
  }
}