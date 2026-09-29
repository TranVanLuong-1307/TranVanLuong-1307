import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/notification_category.dart';

class CategoryCard extends StatelessWidget {
  final NotificationCategory category;
  final int count;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getCategoryColor(category);
    final icon = AppColors.getCategoryIcon(category);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count thông báo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
