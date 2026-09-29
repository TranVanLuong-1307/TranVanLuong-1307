import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/notification_dao.dart';
import 'data/repositories/notification_repository.dart';
import 'providers/app_provider.dart';
import 'providers/category_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_routes.dart';
import 'services/analyzer/notification_analyzer.dart';
import 'services/notification/notification_filter.dart';
import 'services/notification/notification_service.dart';

class NotificationInsightApp extends StatelessWidget {
  const NotificationInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate repository, services and providers for pipeline
    final dao = NotificationDao();
    final repository = NotificationRepository(dao: dao);
    final notificationService = NotificationService();
    final filter = NotificationFilter();
    final analyzer = NotificationAnalyzer();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            repository: repository,
            notificationService: notificationService,
            filter: filter,
            analyzer: analyzer,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => AppProvider(repository: repository),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.initial,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
