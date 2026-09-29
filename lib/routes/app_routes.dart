import 'package:flutter/material.dart';
import '../screens/apps/apps_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String categories = '/categories';
  static const String apps = '/apps';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const MainNavigationScreen(),
        dashboard: (context) => const DashboardScreen(),
        notifications: (context) => const NotificationsScreen(),
        categories: (context) => const CategoriesScreen(),
        apps: (context) => const AppsScreen(),
        settings: (context) => const SettingsScreen(),
      };
}
