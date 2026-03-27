import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:attendly/provider/weekly_repo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WeeksListPage extends ConsumerStatefulWidget {
  final DateTime currentWeekDate;
  final Function(DateTime, bool)? onStatusChanged;
  final bool isTablet;

  const WeeksListPage({
    super.key,
    required this.currentWeekDate,
    this.onStatusChanged,
    this.isTablet = false,
  });

  @override
  ConsumerState<WeeksListPage> createState() => _WeeksListPageState();
}

class _WeeksListPageState extends ConsumerState<WeeksListPage> {
  final HelperAllPerson _helper = HelperAllPerson();


  Future<void> _toggleCountableWeek(WeeklyEntryData week) async {
    final repo = ref.read(weeklyRepositoryProvider);
    final newValue = !week.countable;

    try {
      await repo.updateCountableStatus(week.dates, newValue);
      
      // ref.invalidate(allWeeksProvider);
      
      // ref.invalidate(weeklyReportProvider(week.dates));

      widget.onStatusChanged?.call(week.dates, newValue);

    } on custom_db_exceptions.DatabaseNotReadyException {
      return;
    } catch (e, stackTrace) {
      if (mounted) {
        _helper.showErrorMessage(context, 'Failed to update status: ${e.toString()}', stackTrace: stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    
    final asyncWeeksList = ref.watch(allWeeksProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).weeksWithData,
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // body: asyncWeeksList.when(
      //   loading: () => const Center(child: CircularProgressIndicator()),
      //   error: (error, _) => Center(
      //     child: Text(
      //       'An error occurred: $error',
      //       style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.w500),
      //     )
      //   ),
      //   data: (weeksData) {
      //     if (weeksData.isEmpty) {
      body: asyncWeeksList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            if (error is custom_db_exceptions.DatabaseNotReadyException) {
              return const Center(child: CircularProgressIndicator());
            }
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ref.read(databaseManagerProvider.notifier).reportDatabaseError(error);
            });
            return const Center(child: CircularProgressIndicator());
          },
          data: (weeksData) {
            if (weeksData.isEmpty) {
            return Center(
              child: Text(
                'No weekly entries found.',
                style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.w500),
              )
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getListPadding(context).vertical,
              horizontal: ResponsiveUtils.getListPadding(context).horizontal,
            ),
            itemCount: weeksData.length,
            itemBuilder: (context, index) {
              final weekData = weeksData[index];
              final DateTime startDate = weekData.dates;
              final DateTime endDate = startDate.add(const Duration(days: 4));
              final displayStr = "${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}";
              
              final bool isCountable = weekData.countable;
              final isCurrentWeek = weekData.dates == widget.currentWeekDate;

              return Card(
                elevation: ResponsiveUtils.getCardElevation(context),
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getListPadding(context).horizontal / 2, 
                  vertical: ResponsiveUtils.getListPadding(context).vertical * 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                  side: isCurrentWeek
                      ? BorderSide(color: Theme.of(context).primaryColor, width: isTablet ? 2.0 : 1.5)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                  onTap: () {
                    Navigator.of(context).pop({
                      'date': weekData.dates.toIso8601String(),
                      'isCountable': isCountable
                    });
                  },
                  child: Padding(
                    padding: ResponsiveUtils.getContentPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isCountable ? Icons.check_circle : Icons.cancel_outlined,
                                color: isCountable ? Colors.green : Colors.red,
                                size: ResponsiveUtils.getIconSize(context, baseSize: 34),
                              ),
                              tooltip: isCountable 
                                  ? AppLocalizations.of(context).excludeFromYearReport 
                                  : AppLocalizations.of(context).includeInYearReport,
                              onPressed: () => _toggleCountableWeek(weekData),
                              padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context).vertical / 4),
                            ),
                          ],
                        ),
                        Divider(height: ResponsiveUtils.getListPadding(context).vertical * 3),
                        _buildWeekDataDetails(weekData),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWeekDataDetails(WeeklyEntryData weekData) {
    final Map<String, int> keyStats = {};
    final localizations = AppLocalizations.of(context);

    // Calculate total visitors from open categories
    final totalVisitors = weekData.openMale + weekData.openFemale + weekData.openDiverse;

    // Select a few key statistics to display as chips
    final int maleCount = weekData.openMale;
    final int femaleCount = weekData.openFemale;

    if (maleCount > 0) keyStats[localizations.male] = maleCount;
    if (femaleCount > 0) keyStats[localizations.female] = femaleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.groups, 
              size: ResponsiveUtils.getIconSize(context, baseSize: 18), 
              color: Colors.blueGrey,
            ),
            SizedBox(width: ResponsiveUtils.getListPadding(context).horizontal / 2),
            Text(
              '${localizations.totalVisitors}: $totalVisitors',
              style: TextStyle(
                fontSize: ResponsiveUtils.getBodyFontSize(context), 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (keyStats.isNotEmpty) ...[
          SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
          Wrap(
            spacing: ResponsiveUtils.getListPadding(context).horizontal / 2,
            runSpacing: ResponsiveUtils.getListPadding(context).vertical / 2,
            children: keyStats.entries.map((entry) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context) - 6,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(
                  entry.key,
                  style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context) - 4),
                ),
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context).vertical / 2),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}