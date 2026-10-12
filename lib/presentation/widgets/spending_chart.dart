import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key, required this.totals});

  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No spending in this month.')),
      );
    }
    final labels = totals.keys.toList();
    final values = labels.map((label) => totals[label]!).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Spending by category',
      child: SizedBox(
        height: 220,
        child: BarChart(
          duration: Duration.zero,
          BarChartData(
            maxY: maxValue * 1.25,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[index],
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var index = 0; index < values.length; index++)
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: values[index],
                      width: 18,
                      color: scheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
