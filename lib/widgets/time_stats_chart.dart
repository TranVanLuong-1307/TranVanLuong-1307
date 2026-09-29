import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class TimeStatsChart extends StatelessWidget {
  final Map<String, int> dailyCounts;

  const TimeStatsChart({
    super.key,
    required this.dailyCounts,
  });

  @override
  Widget build(BuildContext context) {
    final entries = dailyCounts.entries.toList();
    final hasData = entries.any((e) => e.value > 0);

    if (!hasData) {
      return Card(
        child: Container(
          height: 180,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Chưa có dữ liệu thống kê 7 ngày qua',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final maxCount = entries.fold<int>(0, (prev, e) => e.value > prev ? e.value : prev);
    final maxY = (maxCount > 5) ? (maxCount * 1.25).ceilToDouble() : 5.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xu hướng 7 ngày gần nhất',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = entries[group.x.toInt()];
                        return BarTooltipItem(
                          '${entry.key}\n${rod.toY.toInt()} thông báo',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (maxY / 4).ceilToDouble(),
                        getTitlesWidget: (val, meta) {
                          if (val % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            val.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                          final dateStr = entries[idx].key;
                          final parts = dateStr.split('-');
                          final label = parts.length == 3 ? '${parts[2]}/${parts[1]}' : dateStr;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(entries.length, (i) {
                    final e = entries[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          color: AppColors.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
