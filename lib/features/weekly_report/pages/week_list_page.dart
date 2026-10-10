import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/weekly_report/providers/weekly_report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WeekListPage extends ConsumerStatefulWidget {
  final DateTime currentWeekDate;

  const WeekListPage({
    super.key,
    required this.currentWeekDate,
  });

  @override
  ConsumerState<WeekListPage> createState() => _WeekListPageState();
}

class _WeekListPageState extends ConsumerState<WeekListPage> {

  Future<void> _toggleCountableWeek(WeeklyEntryData week) async {
    final repo = ref.read(weeklyRepositoryProvider);
    final newValue = !week.countable;

    try {
      await repo.updateCountableStatus(week.weekDate, newValue);
    } on custom_db_exceptions.DatabaseNotReadyException {
      return;
    } catch (e, stackTrace) {
      if (mounted) {
        AppDialogs.showError(context, 'Failed to update status: ${e.toString()}', stackTrace: stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.of(context).isTablet;
    final iconSize = Responsive.of(context).iconSize();
    
    final asyncWeeksList = ref.watch(allWeeksProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).weeksWithData,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: asyncWeeksList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            if (error is custom_db_exceptions.DatabaseNotReadyException) {
              return const Center(child: CircularProgressIndicator());
            }
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ref.read(databaseProvider.notifier).reportDatabaseError(error);
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
              vertical: Responsive.of(context).listPadding.vertical,
              horizontal: Responsive.of(context).listPadding.horizontal,
            ),
            itemCount: weeksData.length,
            itemBuilder: (context, index) {
              final weekData = weeksData[index];
              final DateTime startDate = weekData.weekDate;
              final DateTime endDate = startDate.add(const Duration(days: 4));
              final displayStr = "${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}";
              
              final bool isCountable = weekData.countable;
              final isCurrentWeek = weekData.weekDate == widget.currentWeekDate;

              return Card(
                elevation: Responsive.of(context).cardElevation,
                margin: EdgeInsets.symmetric(
                  horizontal: Responsive.of(context).listPadding.horizontal / 2, 
                  vertical: Responsive.of(context).listPadding.vertical * 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: Responsive.of(context).cardBorderRadius,
                  side: isCurrentWeek
                      ? BorderSide(color: Theme.of(context).primaryColor, width: isTablet ? 2.0 : 1.5)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: Responsive.of(context).cardBorderRadius,
                  onTap: () {
                    Navigator.of(context).pop({
                      'date': weekData.weekDate.toIso8601String(),
                      'isCountable': isCountable
                    });
                  },
                  child: Padding(
                    padding: Responsive.of(context).contentPadding,
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
                                  fontSize: Responsive.of(context).bodyFontSize + 2,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isCountable ? Icons.check_circle : Icons.cancel_outlined,
                                color: isCountable ? Colors.green : Colors.red,
                                size: Responsive.of(context).iconSize(baseSize: 34),
                              ),
                              tooltip: isCountable 
                                  ? AppLocalizations.of(context).excludeFromYearReport 
                                  : AppLocalizations.of(context).includeInYearReport,
                              onPressed: () => _toggleCountableWeek(weekData),
                              padding: EdgeInsets.all(Responsive.of(context).contentPadding.vertical / 4),
                            ),
                          ],
                        ),
                        Divider(height: Responsive.of(context).listPadding.vertical * 3),
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
              size: Responsive.of(context).iconSize(baseSize: 18), 
              color: Colors.blueGrey,
            ),
            SizedBox(width: Responsive.of(context).listPadding.horizontal / 2),
            Text(
              '${localizations.totalVisitors}: $totalVisitors',
              style: TextStyle(
                fontSize: Responsive.of(context).bodyFontSize, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (keyStats.isNotEmpty) ...[
          SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
          Wrap(
            spacing: Responsive.of(context).listPadding.horizontal / 2,
            runSpacing: Responsive.of(context).listPadding.vertical / 2,
            children: keyStats.entries.map((entry) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: Responsive.of(context).bodyFontSize - 6,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(
                  entry.key,
                  style: TextStyle(fontSize: Responsive.of(context).bodyFontSize - 4),
                ),
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: EdgeInsets.all(Responsive.of(context).contentPadding.vertical / 2),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
