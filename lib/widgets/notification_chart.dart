import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/notification_category.dart';

class NotificationCategoryChart extends StatelessWidget {
  final Map<NotificationCategory, int> categoryCounts;

  const NotificationCategoryChart({
    super.key,
    required this.categoryCounts,
  });

  @override
  Widget build(BuildContext context) {
    final validEntries = categoryCounts.entries.where((e) => e.value > 0).toList();

    if (validEntries.isEmpty) {
      return Card(
        child: Container(
          height: 180,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Text(
            'Chưa có dữ liệu thống kê',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final total = validEntries.fold<int>(0, (sum, item) => sum + item.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân bổ theo danh mục',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: validEntries.map((e) {
                          final pct = ((e.value / total) * 100).toStringAsFixed(0);
                          return PieChartSectionData(
                            color: AppColors.getCategoryColor(e.key),
                            value: e.value.toDouble(),
                            title: '$pct%',
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: validEntries.take(4).map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryColor(e.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key.displayName,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${e.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
