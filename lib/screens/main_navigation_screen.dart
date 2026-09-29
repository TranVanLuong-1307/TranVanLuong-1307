import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/category_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import 'apps/apps_screen.dart';
import 'categories/categories_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'notifications/notifications_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (!mounted) return;
    final settingsProv = context.read<SettingsProvider>();
    final notifProv = context.read<NotificationProvider>();

    await settingsProv.checkPermission();
    if (settingsProv.isPermissionGranted && !notifProv.isListening) {
      notifProv.startNotificationPipeline(
        isTrackingEnabled: settingsProv.isTrackingEnabled,
      );
    }
  }

  Future<void> _initAppData() async {
    if (!mounted) return;
    final settingsProv = context.read<SettingsProvider>();
    final notifProv = context.read<NotificationProvider>();
    final catProv = context.read<CategoryProvider>();
    final appProv = context.read<AppProvider>();

    await settingsProv.initSettings();
    await notifProv.loadNotifications();
    await catProv.loadCategoryStats();
    await appProv.loadTrackedApps();

    // Start pipeline if permission granted or ready
    notifProv.startNotificationPipeline(
      isTrackingEnabled: settingsProv.isTrackingEnabled,
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const NotificationsScreen(),
      CategoriesScreen(onNavigateToTab: _onTabTapped),
      AppsScreen(onNavigateToTab: _onTabTapped),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Danh mục',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Ứng dụng',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
