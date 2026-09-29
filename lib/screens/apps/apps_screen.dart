import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/app_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';

class AppsScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AppsScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng dụng theo dõi'),
      ),
      body: Consumer2<AppProvider, NotificationProvider>(
        builder: (context, appProv, notifProv, _) {
          if (appProv.isLoading && appProv.trackedApps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appProv.trackedApps.isEmpty) {
            return const EmptyState(
              icon: Icons.apps_outage_rounded,
              title: 'Chưa có ứng dụng nào',
              subtitle: 'Khi thiết bị nhận được thông báo từ các ứng dụng thực tế, danh sách sẽ tự động tổng hợp tại đây',
            );
          }

          return RefreshIndicator(
            onRefresh: () => appProv.loadTrackedApps(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: appProv.trackedApps.length,
              itemBuilder: (context, index) {
                final app = appProv.trackedApps[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      // Filter notifications by this application package
                      await notifProv.clearAllFilters();
                      await notifProv.filterByPackage(app.packageName);
                      onNavigateToTab?.call(1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.shade50,
                            child: Text(
                              app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.appName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  app.packageName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gần nhất: ${DateFormatter.formatRelative(app.lastReceivedTime)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${app.notificationCount}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
