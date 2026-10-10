import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/weekly_report/pages/week_list_page.dart';
import 'package:attendly/core/utils/date_utils.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/weekly_report/providers/weekly_report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/shared/widgets/tab_app_bar.dart';
import 'package:attendly/shared/shell/shell_tab.dart';
import 'package:attendly/shared/widgets/chart_dialog.dart'; 
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/core/responsive/responsive.dart';

/// Weekly totals for one week (Monday to Friday), and the list of all weeks.
class WeeklyReportTab extends ShellTab {
  const WeeklyReportTab();

  @override
  PreferredSizeWidget buildAppBar(BuildContext context, WidgetRef ref) {
    final selectedWeekDate = ref.watch(selectedWeekProvider);
    final asyncWeekData = ref.watch(weeklyReportProvider(selectedWeekDate));

    return TabAppBar(
      title: AppLocalizations.of(context).weeklyReport,
      leading: DrawerMenuButton.forShell(context),
      actions: [_buildStatusWidget(context, asyncWeekData)],
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) => const _WeeklyReportBody();

  @override
  Widget buildFab(BuildContext context, WidgetRef ref) {
    final responsive = Responsive.of(context);
    return SizedBox(
      width: responsive.buttonHeight + 25,
      height: responsive.buttonHeight + 25,
      child: FloatingActionButton(
        onPressed: () => _showWeeksWithData(context, ref),
        tooltip: AppLocalizations.of(context).showWeeksWithDataTooltip,
        child: Icon(Icons.list_alt, size: responsive.iconSize(baseSize: 35)),
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, AsyncValue<WeeklyEntryData?> asyncWeekData) {
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
              size: Responsive.of(context).iconSize(baseSize: 24),
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

  Future<void> _showWeeksWithData(BuildContext context, WidgetRef ref) async {
    final selectedWeekDate = ref.read(selectedWeekProvider);
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => WeekListPage(
          currentWeekDate: selectedWeekDate,
        ),
      ),
    );
    if (!context.mounted) return;

    // A changed "countable" status needs no refresh: the week stream re-emits.
    if (result != null) {
      ref.read(selectedWeekProvider.notifier).state = DateTime.parse(result['date']);
    }
  }
}

class _WeeklyReportBody extends ConsumerStatefulWidget {
  const _WeeklyReportBody();

  @override
  ConsumerState<_WeeklyReportBody> createState() => _WeeklyReportBodyState();
}

class _WeeklyReportBodyState extends ConsumerState<_WeeklyReportBody> {
  DateTime get selectedWeekDate => ref.read(selectedWeekProvider);

  Future<void> _selectWeek() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedWeekDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime val) => val.weekday == DateTime.monday,
      keyboardType: const TextInputType.numberWithOptions(),
      builder: (context, child) {
        if (!Responsive.of(context).isTablet || child == null) return child ?? const SizedBox.shrink();

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

    if (picked != null && picked != selectedWeekDate && mounted) {
      ref.read(selectedWeekProvider.notifier).state = picked;
    }
  }

  void _changeWeek(int days) {
    ref.read(selectedWeekProvider.notifier).state = selectedWeekDate.add(Duration(days: days));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final selectedWeekDate = ref.watch(selectedWeekProvider);
    final endDate = selectedWeekDate.add(const Duration(days: 4));

    // Watch the specific week's data
    final asyncWeekData = ref.watch(weeklyReportProvider(selectedWeekDate));

    ref.listen<AsyncValue<WeeklyEntryData?>>(
      weeklyReportProvider(selectedWeekDate),
      (previous, next) {
        if (next is AsyncError) {
          final error = next.error;
          if (error != null && error is! custom_db_exceptions.DatabaseNotReadyException) {
            ref.read(databaseProvider.notifier).reportDatabaseError(error);
          }
        }
      },
    );

    return Column(
      children: [
        _buildWeekSelector(endDate),
        Expanded(
          child: asyncWeekData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            // Errors are reported to the startup gate by the listener above.
            error: (error, _) => const Center(child: CircularProgressIndicator()),
            data: (weekData) => weekData == null
                ? Center(
                    child: Text(
                      localizations.noDataForThisWeek,
                      style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    )
                  )
                : _buildReportView(weekData),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSelector(DateTime endDate) {
    final canGoForward = selectedWeekDate.isBefore(getFirstDateOfWeek(getScopedDate()));
    final arrowSize = Responsive.of(context).iconSize(baseSize: 30);
    final listPad = Responsive.of(context).listPadding;

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
                fontSize: Responsive.of(context).titleFontSize,
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
        Responsive.of(context).listPadding.left,
        Responsive.of(context).listPadding.top,
        Responsive.of(context).listPadding.right,
        Responsive.of(context).buttonHeight + 40 + MediaQuery.of(context).padding.bottom,
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
      margin: EdgeInsets.only(bottom: Responsive.of(context).listPadding.vertical * 4),
      elevation: Responsive.of(context).cardElevation,
      shape: RoundedRectangleBorder(borderRadius: Responsive.of(context).cardBorderRadius),
      child: Padding(
        padding: Responsive.of(context).contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: Responsive.of(context).iconSize()),
                SizedBox(width: Responsive.of(context).listPadding.horizontal / 2 + 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.of(context).titleFontSize,
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
                  fontSize: Responsive.of(context).bodyFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.pie_chart, size: Responsive.of(context).iconSize()),
              onPressed: (withCount + withoutCount > 0)
                  ? () => ChartDialog.show(
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
      margin: EdgeInsets.only(bottom: Responsive.of(context).listPadding.vertical * 3),
      elevation: Responsive.of(context).cardElevation,
      shape: RoundedRectangleBorder(borderRadius: Responsive.of(context).cardBorderRadius),
      child: Padding(
        padding: Responsive.of(context).contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: Responsive.of(context).iconSize()),
                SizedBox(width: Responsive.of(context).listPadding.horizontal / 2  + 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.of(context).titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.pie_chart, size: Responsive.of(context).iconSize()),
                  onPressed: () => ChartDialog.show(
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
      padding: EdgeInsets.symmetric(vertical: Responsive.of(context).listPadding.vertical / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: Responsive.of(context).bodyFontSize)),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: Responsive.of(context).bodyFontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
