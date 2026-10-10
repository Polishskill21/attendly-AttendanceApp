import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/yearly_report/models/year_stats.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/yearly_report/providers/yearly_report_providers.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:attendly/shared/shell/shell_tab.dart';
import 'package:attendly/shared/widgets/refreshable_app_bar.dart';
import 'package:attendly/shared/widgets/chart_dialog.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Totals and weekly averages over all countable weeks of the year.
class YearlyReportTab extends ShellTab {
  const YearlyReportTab();

  @override
  PreferredSizeWidget buildAppBar(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(yearlyStatsProvider);

    return RefreshableAppBar(
      title: AppLocalizations.of(context).yearlyStats,
      showRefresh: true,
      isLoading: asyncStats.isLoading ||
                 asyncStats.isReloading,
      onRefresh: () {
        AppLogger.d("Yearly", "Invalidating yearly stream");
        ref.invalidate(yearlyStatsProvider);
      },
      leading: DrawerMenuButton.forShell(context),
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) => const _YearlyReportBody();
}

class _YearlyReportBody extends ConsumerStatefulWidget {
  const _YearlyReportBody();

  @override
  ConsumerState<_YearlyReportBody> createState() => _YearlyReportBodyState();
}

class _YearlyReportBodyState extends ConsumerState<_YearlyReportBody> {
  void fetchYearStats() {
    ref.invalidate(yearlyStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final asyncStats = ref.watch(yearlyStatsProvider);

    return asyncStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error, stack),
      data: (statsModel) {
        if (statsModel == null) {
          return Center(
            child: Text(
              localizations.noDataForThisYear,
              style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
            ),
          );
        }
        return _buildReportView(statsModel);
      },
    );
  }

  Widget _buildErrorState(Object error, StackTrace stackTrace) {

    if (error is custom_db_exceptions.DatabaseNotReadyException) {
      return const Center(child: CircularProgressIndicator());
    }
    
    String displayMessage = "An unexpected error occurred.";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(databaseProvider.notifier).reportDatabaseError(error);
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Responsive.of(context).iconSize(baseSize: 60),
            color: Colors.red,
          ),
          SizedBox(height: Responsive.of(context).listPadding.vertical * 4),
          
          // Display the actual error message dynamically
          Text(
            displayMessage,
            style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
          ElevatedButton(
            onPressed: fetchYearStats, 
            child: Text('Retry', style: TextStyle(fontSize: Responsive.of(context).bodyFontSize)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView(YearStats statsModel) {
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
        Responsive.of(context).listPadding.left,
        Responsive.of(context).listPadding.top,
        Responsive.of(context).listPadding.right,
        Responsive.of(context).listPadding.bottom +
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
          bottom: Responsive.of(context).listPadding.vertical * 3),
      elevation: Responsive.of(context).cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: Responsive.of(context).cardBorderRadius),
      child: Padding(
        padding: Responsive.of(context).contentPadding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                color: Theme.of(context).primaryColor,
                size: Responsive.of(context).iconSize()),
            SizedBox(
                width: Responsive.of(context).listPadding.horizontal),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: Responsive.of(context).titleFontSize,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),
            if (showChart && data.isNotEmpty)
              IconButton(
                icon: Icon(Icons.pie_chart,
                    size: Responsive.of(context).iconSize()),
                onPressed: () => ChartDialog.show(context,
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
          bottom: Responsive.of(context).listPadding.vertical * 4),
      elevation: Responsive.of(context).cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: Responsive.of(context).cardBorderRadius),
      child: Padding(
        padding: Responsive.of(context).contentPadding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                color: Theme.of(context).primaryColor,
                size: Responsive.of(context).iconSize()),
            SizedBox(
                width: Responsive.of(context).listPadding.horizontal),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: Responsive.of(context).titleFontSize,
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
                  fontSize: Responsive.of(context).bodyFontSize,
                  fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.pie_chart,
                  size: Responsive.of(context).iconSize()),
              onPressed: (withCount + withoutCount > 0)
                  ? () => ChartDialog.show(
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
          bottom: Responsive.of(context).listPadding.vertical / 2),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: Text(localizations.categoryAbbreviation,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.of(context).bodyFontSize)),
        ),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: localizations.total,
            child: Center(
              child: Icon(Icons.groups_2_outlined,
                  size: Responsive.of(context).iconSize(baseSize: 35),
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
                  size: Responsive.of(context).iconSize(),
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
    final body = Responsive.of(context).bodyFontSize;
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: Responsive.of(context).listPadding.vertical / 2),
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
