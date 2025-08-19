import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

class ChartDialogHelper {
  static Future<void> showChartDialog(
    BuildContext context, {
    required String title,
    required Map<String, int> data
  }) {
    final localizations = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 8.0,
          title: Text(
            '${localizations.statistics}: $title',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: _PieChart(data: data),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.close,
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PieChart extends StatefulWidget {
  final Map<String, int> data;

  const _PieChart({required this.data});

  @override
  State<_PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<_PieChart> {
  int touchedIndex = -1;

  final List<Color> _sectionColors = const [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold(0, (sum, item) => sum + item);

    if (total == 0) {
      return Center(
          child: Text(AppLocalizations.of(context).noDataToDisplayInChart));
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: _getSections(total),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _getSections(int total) {
    final dataEntries =
        widget.data.entries.where((entry) => entry.value > 0).toList();

    return List.generate(dataEntries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      final value = dataEntries[i].value;
      final percentage = (value / total * 100);

      return PieChartSectionData(
        color: _sectionColors[i % _sectionColors.length],
        value: value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2),
          ],
        ),
      );
    });
  }

  Widget _buildLegend() {
    final dataEntries =
        widget.data.entries.where((entry) => entry.value > 0).toList();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(dataEntries.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 16,
                height: 16,
                color: _sectionColors[i % _sectionColors.length]),
            const SizedBox(width: 8),
            Text(dataEntries[i].key, style: const TextStyle(fontSize: 14)),
          ],
        );
      }),
    );
  }
}