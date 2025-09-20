import 'package:attendly/frontend/pages/yearly_report/year_stats_model.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/widgets/chart_dialog_helper.dart'; 
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class YearStatsPage extends StatefulWidget {
  final Database dbCon;
  final int selectedTab;
  final void Function(int) onTabChange;
  final bool isTablet;

  const YearStatsPage({
    super.key,
    required this.dbCon,
    required this.selectedTab,
    required this.onTabChange,
    required this.isTablet
  });

  @override
  State<StatefulWidget> createState() => YearStatsPageState();
}

class YearStatsPageState extends State<YearStatsPage> {
  late DbSelection _reader;
  late HelperAllPerson _helper;
  
  bool _isLoading = false;
  YearStatsModel? _statsModel;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _reader = DbSelection(widget.dbCon);
    _helper = HelperAllPerson();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchYearStats();
    });
  }

  Future<void> fetchYearStats() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final localizations = AppLocalizations.of(context);
    _helper.showLoadingDialog(context, localizations.loading);

    try {
      final data = await _reader.getYearStats();
      final weekCount = await _reader.getWeekCount();

      if (mounted) {
        if (data.isNotEmpty && data.first.values.any((v) => v != null)) {
          setState(() {
            _statsModel = YearStatsModel(stats: data.first, weekCount: weekCount);
          });
        } else {
          setState(() {
            _statsModel = null;
          });
        }
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
        setState(() {
            _hasError = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching year stats: $e');
      if (mounted) {
        setState(() {
            _hasError = true;
        });
        _helper.showErrorMessage(
            context, 'Failed to load year statistics: ${e.toString()}', stackTrace: stackTrace);
      }
    } finally {
        if(mounted){
            _helper.hideLoadingDialog(context);
            setState(() {
                _isLoading = false;
            });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      drawer: widget.isTablet
          ? null
          : CustomDrawer(
              selectedTab: widget.selectedTab,
              onTabChange: widget.onTabChange,
            ),
      appBar: RefreshableAppBar(
        title: localizations.yearlyStats,
        onRefresh: null, 
        isLoading: _isLoading, 
        showRefresh: false,
        leading: widget.isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  // Bigger drawer icon
                  icon: Icon(Icons.menu, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                ),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final localizations = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: ResponsiveUtils.getIconSize(context, baseSize: 60), color: Colors.red),
            SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 4),
            Text("Error loading data", style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
            SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
            ElevatedButton(
              onPressed: fetchYearStats,
              child: Text('Retry', style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
            ),
          ],
        ),
      );
    } else if (_statsModel == null) {
      return Center(
        child: Text(
          localizations.noDataForThisYear,
          style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context), color: Colors.grey.shade600),
        ),
      );
    }
    return _buildReportView(_statsModel!);
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
          ResponsiveUtils.getListPadding(context).bottom + MediaQuery.of(context).padding.bottom,
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
                _buildDataRow(
                    localizations.age10to13, stats['age_10_13'], weekCount),
                _buildDataRow(
                    localizations.age14to17, stats['age_14_17'], weekCount),
                _buildDataRow(
                    localizations.age18to24, stats['age_18_24'], weekCount),
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
                _buildDataRow(
                    localizations.diverse, stats['open_diverse'], weekCount),
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
                _buildDataRow(
                    localizations.female, stats['offers_female'], weekCount),
                _buildDataRow(
                    localizations.diverse, stats['offers_diverse'], weekCount),
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
                Icon(icon, color: Theme.of(context).primaryColor, size: ResponsiveUtils.getIconSize(context)),
                SizedBox(width: ResponsiveUtils.getListPadding(context).horizontal),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildHeaderRow(),
            _buildMigrationGenderRow(
              gender: localizations.male,
              withCount: maleWith,
              withoutCount: maleWithout,
              weekCount: weekCount,
              localizations: localizations,
            ),
            const Divider(height: 12),
            _buildMigrationGenderRow(
              gender: localizations.female,
              withCount: femaleWith,
              withoutCount: femaleWithout,
              weekCount: weekCount,
              localizations: localizations,
            ),
            const Divider(height: 12),
            _buildMigrationGenderRow(
              gender: localizations.diverse,
              withCount: diverseWith,
              withoutCount: diverseWithout,
              weekCount: weekCount,
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
    required int weekCount,
    required AppLocalizations localizations,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                gender,
                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context), fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
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
              ),
            ),
          ],
        ),
        _buildDataRow('${localizations.withAbbreviation} ${localizations.migration}', withCount, weekCount),
        _buildDataRow('${localizations.withoutAbbreviation} ${localizations.migration}', withoutCount, weekCount),
      ],
    );
  }

  Widget _buildHeaderRow() {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getListPadding(context).vertical / 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              localizations.categoryAbbreviation,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: AppLocalizations.of(context).total,
              child: Center(
                child: Icon(
                  Icons.groups_2_outlined,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 35),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: AppLocalizations.of(context).average,
              child: Center(
                child: Icon(
                  Icons.show_chart,
                  size: ResponsiveUtils.getIconSize(context),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
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
                Icon(icon, color: Theme.of(context).primaryColor, size: ResponsiveUtils.getIconSize(context)),
                SizedBox(width: ResponsiveUtils.getListPadding(context).horizontal),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (showChart && data.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.pie_chart, size: ResponsiveUtils.getIconSize(context)),
                    onPressed: () => ChartDialogHelper.showChartDialog(context, title: title, data: data),
                  )
              ],
            ),
            if (children.isNotEmpty) const Divider(height: 24),
            if (children.isNotEmpty) _buildHeaderRow(),
            ...children,
            if (children.isNotEmpty) ...[
              const Divider(height: 12, thickness: 1),
              _buildDataRow(
                localizations.total,
                data.values.fold(0, (a, b) => a + b),
                weekCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value, int weekCount) {
    final total = value ?? 0;
    final avg = weekCount > 0 ? total / weekCount : 0.0;
    final body = ResponsiveUtils.getBodyFontSize(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getListPadding(context).vertical / 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: TextStyle(fontSize: body)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              total.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: body, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              avg.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: body, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}