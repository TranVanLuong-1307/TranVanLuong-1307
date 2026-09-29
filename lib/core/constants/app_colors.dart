import 'package:flutter/material.dart';
import '../enums/notification_category.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF0F172A);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Category Colors
  static Color getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.finance:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationCategory.messaging:
        return const Color(0xFF3B82F6); // Blue
      case NotificationCategory.email:
        return const Color(0xFFEA580C); // Orange
      case NotificationCategory.shopping:
        return const Color(0xFFF59E0B); // Amber
      case NotificationCategory.delivery:
        return const Color(0xFF06B6D4); // Cyan
      case NotificationCategory.social:
        return const Color(0xFF8B5CF6); // Purple
      case NotificationCategory.security:
        return const Color(0xFFEF4444); // Red
      case NotificationCategory.system:
        return const Color(0xFF64748B); // Slate
      case NotificationCategory.entertainment:
        return const Color(0xFFEC4899); // Pink
      case NotificationCategory.general:
        return const Color(0xFF14B8A6); // Teal
      case NotificationCategory.other:
        return const Color(0xFF94A3B8); // Muted Slate
    }
  }

  static IconData getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.finance:
        return Icons.account_balance_wallet_outlined;
      case NotificationCategory.messaging:
        return Icons.chat_bubble_outline;
      case NotificationCategory.email:
        return Icons.mail_outline;
      case NotificationCategory.shopping:
        return Icons.shopping_bag_outlined;
      case NotificationCategory.delivery:
        return Icons.local_shipping_outlined;
      case NotificationCategory.social:
        return Icons.share_outlined;
      case NotificationCategory.security:
        return Icons.shield_outlined;
      case NotificationCategory.system:
        return Icons.settings_suggest_outlined;
      case NotificationCategory.entertainment:
        return Icons.movie_outlined;
      case NotificationCategory.general:
        return Icons.notifications_outlined;
      case NotificationCategory.other:
        return Icons.category_outlined;
    }
  }
}
