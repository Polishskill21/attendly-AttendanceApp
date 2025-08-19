import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:flutter/material.dart';

class WeeksListPage extends StatefulWidget {
  final DbSelection reader;
  final DbUpdater updater;
  final String currentWeekDate;
  final Function(String, bool)? onStatusChanged;

  const WeeksListPage({
    super.key,
    required this.reader,
    required this.updater,
    required this.currentWeekDate,
    this.onStatusChanged,
  });

  @override
  State<WeeksListPage> createState() => _WeeksListPageState();
}

class _WeeksListPageState extends State<WeeksListPage> {
  late Future<List<Map<String, dynamic>>> _weeksDataFuture;
  List<Map<String, dynamic>> _weeksData = [];
  final HelperAllPerson _helper = HelperAllPerson();

  @override
  void initState() {
    super.initState();
    _weeksDataFuture = _fetchAllWeeksData();
  }

  Future<List<Map<String, dynamic>>> _fetchAllWeeksData() async {
    try {
      final data = await widget.reader.getAllWeeklyEntries();
      // Sort the list so the most recent weeks are at the top
      //data.sort((a, b) => (b['dates'] as String).compareTo(a['dates'] as String));
      _weeksData = data.map((week) => Map<String, dynamic>.from(week)).toList();
      return _weeksData;
    } catch (e, stackTrace) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           _helper.showErrorMessage(context, 'Failed to load weeks data: ${e.toString()}', stackTrace: stackTrace);
           Navigator.of(context).pop(); 
        }
      });
      return []; 
    }
  }

  Future<void> _toggleCountable(int index) async {
    final week = _weeksData[index];
    final String weekDate = week['dates'];
    final int currentValue = week['countable'] ?? 0;
    final int newValue = 1 - currentValue;

    try {
      await widget.updater.updateCountableCol(weekDate, newValue);
      // Update the local list optimistically to feel instant
      setState(() {
        _weeksData[index]['countable'] = newValue;
       });

      // Fire the callback to update the previous page if it's the current week
      widget.onStatusChanged?.call(weekDate, newValue == 1);

    } catch (e, stackTrace) {
        if (mounted) {
             _helper.showErrorMessage(context, 'Failed to update status: ${e.toString()}', stackTrace: stackTrace);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).weeksWithData), 
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _weeksDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                snapshot.hasError ? 'An error occurred.' : 'No weekly entries found.',
                 style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return ListView.builder(
            itemCount: _weeksData.length,
            itemBuilder: (context, index) {
              final weekData = _weeksData[index];
              final startDate = DateTime.parse(weekData['dates']);
              final endDate = startDate.add(const Duration(days: 4));
              final displayStr = "${dateToString(startDate)} - ${dateToString(endDate)}";
              final bool isCountable = (weekData['countable'] ?? 0) == 1;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: weekData['dates'] == widget.currentWeekDate
                      ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop({
                      'date': weekData['dates'],
                      'isCountable': isCountable
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isCountable ? Icons.check_circle : Icons.cancel_outlined,
                                color: isCountable ? Colors.green : Colors.red,
                                size: 30,
                              ),
                              tooltip: isCountable ? AppLocalizations.of(context).excludeFromYearReport : AppLocalizations.of(context).includeInYearReport,
                              onPressed: () => _toggleCountable(index),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
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

  Widget _buildWeekDataDetails(Map<String, dynamic> weekData) {
    final Map<String, int> keyStats = {};
    final localizations = AppLocalizations.of(context);

    // Calculate total visitors from open categories
    final totalVisitors = (weekData['open_male'] as int? ?? 0) +
        (weekData['open_female'] as int? ?? 0) +
        (weekData['open_diverse'] as int? ?? 0);
    
    // Select a few key statistics to display as chips
    final int maleCount = weekData['open_male'] as int? ?? 0;
    final int femaleCount = weekData['open_female'] as int? ?? 0;

    if (maleCount > 0) keyStats[localizations.male] = maleCount;
    if (femaleCount > 0) keyStats[localizations.female] = femaleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              '${localizations.totalVisitors}: $totalVisitors',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (keyStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: keyStats.entries.map((entry) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                label: Text(entry.key),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}