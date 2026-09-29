import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/notification_priority.dart';
import '../core/utils/date_formatter.dart';
import '../models/notification_record.dart';

class NotificationCard extends StatelessWidget {
  final NotificationRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const NotificationCard({
    super.key,
    required this.record,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.getCategoryColor(record.category);
    final catIcon = AppColors.getCategoryIcon(record.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Badge with Unread Indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catIcon, color: catColor, size: 22),
                  ),
                  if (!record.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: record.isRead ? FontWeight.w500 : FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatRelative(record.dateTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (record.priority == NotificationPriority.urgent || record.priority == NotificationPriority.high) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: record.priority == NotificationPriority.urgent ? Colors.red.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.priority.displayName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: record.priority == NotificationPriority.urgent ? Colors.red : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (record.title != null && record.title!.isNotEmpty)
                      Text(
                        record.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: record.isRead ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                    if (record.content != null && record.content!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.content!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: record.isRead ? Colors.grey.shade600 : Colors.black87,
                          fontWeight: record.isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Favorite Toggle Button
              IconButton(
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  record.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: record.isFavorite ? Colors.amber : Colors.grey.shade400,
                ),
                onPressed: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
