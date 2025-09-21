import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class ChartDialogHelper {
  static Future<void> showChartDialog(
    BuildContext context, {
    required String title,
    required Map<String, int> data
  }) {
    final localizations = AppLocalizations.of(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
          ),
          elevation: isTablet ? 12.0 : 8.0,
          contentPadding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
          title: Text(
            '${localizations.statistics}: $title',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 24.0 : 20.0,
                ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: isTablet ? 450 : 350,
            child: _PieChart(data: data, isTablet: isTablet),
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
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18.0 : 14.0,
                ),
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
  final bool isTablet;

  const _PieChart({required this.data, this.isTablet = false});

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
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);

    if (total == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noDataToDisplayInChart,
          style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
        ),
      );
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
              sectionsSpace: isTablet ? 4 : 3,
              centerSpaceRadius: isTablet ? 60 : 50,
              sections: _getSections(total),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 30 : 20),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _getSections(int total) {
    final dataEntries =
        widget.data.entries.where((entry) => entry.value > 0).toList();
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);

    return List.generate(dataEntries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched 
          ? (isTablet ? 22.0 : 18.0) 
          : (isTablet ? 18.0 : 14.0);
      final radius = isTouched 
          ? (isTablet ? 80.0 : 70.0) 
          : (isTablet ? 70.0 : 60.0);
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
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    
    return Wrap(
      spacing: isTablet ? 20 : 16,
      runSpacing: isTablet ? 12 : 8,
      alignment: WrapAlignment.center,
      children: List.generate(dataEntries.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: isTablet ? 20 : 16,
                height: isTablet ? 20 : 16,
                color: _sectionColors[i % _sectionColors.length]),
            SizedBox(width: isTablet ? 10 : 8),
            Text(
              dataEntries[i].key, 
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
          ],
        );
      }),
    );
  }
}