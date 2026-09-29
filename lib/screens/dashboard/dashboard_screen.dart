import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/notification_chart.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/time_stats_chart.dart';
import '../notifications/notification_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer3<NotificationProvider, CategoryProvider, AppProvider>(
        builder: (context, notifProv, catProv, appProv, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await notifProv.loadNotifications();
              await catProv.loadCategoryStats();
              await appProv.loadTrackedApps();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // 5 Summary Metrics: Total, Today, Unread, Favorites, Apps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      SummaryCard(
                        title: 'Tổng thông báo',
                        value: '${notifProv.totalCount}',
                        icon: Icons.notifications_none_rounded,
                        color: AppColors.primary,
                      ),
                      SummaryCard(
                        title: 'Hôm nay',
                        value: '${notifProv.todayCount}',
                        icon: Icons.today_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      SummaryCard(
                        title: 'Chưa đọc',
                        value: '${notifProv.unreadCount}',
                        icon: Icons.mark_email_unread_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                      SummaryCard(
                        title: 'Quan trọng / Fav',
                        value: '${notifProv.favoriteCount}',
                        icon: Icons.star_border_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      SummaryCard(
                        title: 'Ứng dụng',
                        value: '${appProv.totalAppsCount}',
                        icon: Icons.apps_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category Distribution Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: NotificationCategoryChart(
                    categoryCounts: catProv.categoryCounts,
                  ),
                ),
                const SizedBox(height: 16),

                // 7-day Time Statistics Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TimeStatsChart(
                    dailyCounts: notifProv.dailyCountsLast7Days,
                  ),
                ),
                const SizedBox(height: 16),

                // Recent Notifications Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Thông báo gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (notifProv.notifications.isEmpty)
                  const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Chưa có thông báo nào',
                    subtitle: 'Các thông báo mới sẽ tự động xuất hiện tại đây',
                  )
                else
                  ...notifProv.notifications.take(5).map(
                    (record) => NotificationCard(
                      record: record,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationDetailScreen(record: record),
                          ),
                        );
                      },
                      onFavoriteToggle: () => notifProv.toggleFavorite(record),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
