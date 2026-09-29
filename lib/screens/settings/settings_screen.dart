import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial permission check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().checkPermission();
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
      // User returned from Android Settings screen -> automatically refresh permission status
      final settingsProv = context.read<SettingsProvider>();
      final notifProv = context.read<NotificationProvider>();
      settingsProv.checkPermission().then((_) {
        if (settingsProv.isPermissionGranted && !notifProv.isListening) {
          notifProv.startNotificationPipeline(
            isTrackingEnabled: settingsProv.isTrackingEnabled,
          );
        }
      });
    }
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa dữ liệu'),
        content: const Text(
          'Toàn bộ lịch sử thông báo lưu trữ cục bộ sẽ bị xóa vĩnh viễn khỏi SQLite. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final notifProv = context.read<NotificationProvider>();
              final catProv = context.read<CategoryProvider>();
              final appProv = context.read<AppProvider>();
              Navigator.pop(ctx);
              try {
                // Clear SQLite and refresh all providers
                await notifProv.clearAll();
                await catProv.loadCategoryStats();
                await appProv.loadTrackedApps();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa toàn bộ dữ liệu thông báo thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa dữ liệu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa dữ liệu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: Consumer2<SettingsProvider, NotificationProvider>(
        builder: (context, settingsProv, notifProv, _) {
          final isGranted = settingsProv.isPermissionGranted;

          return ListView(
            children: [
              // Error Banner if any
              if (settingsProv.errorMessage != null)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          settingsProv.errorMessage!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => settingsProv.clearError(),
                      ),
                    ],
                  ),
                ),

              // Permission section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'QUYỀN HỆ THỐNG ANDROID',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            color: isGranted ? Colors.green : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notification Access',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isGranted ? 'Trạng thái: Enabled (Đã cấp quyền)' : 'Trạng thái: Disabled (Chưa cấp quyền)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isGranted ? Colors.green.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isGranted
                            ? 'Ứng dụng đang có quyền tiếp nhận thông báo từ hệ thống Android.'
                            : 'Hệ điều hành Android yêu cầu cấp quyền Notification Access để ứng dụng có thể đọc và quản lý thông báo.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGranted ? Colors.grey.shade100 : Colors.blue,
                            foregroundColor: isGranted ? Colors.blue.shade900 : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(isGranted ? Icons.refresh_rounded : Icons.settings_rounded),
                          label: Text(
                            isGranted ? 'Kiểm tra lại quyền' : 'Mở cài đặt Notification Access',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final granted = await settingsProv.requestPermission();
                            if (granted) {
                              notifProv.startNotificationPipeline(
                                isTrackingEnabled: settingsProv.isTrackingEnabled,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tracking section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'THEO DÕI & THU THẬP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bật theo dõi thông báo'),
                      subtitle: const Text('Tự động tiếp nhận, phân loại và lưu thông báo mới vào SQLite'),
                      value: settingsProv.isTrackingEnabled,
                      onChanged: (val) {
                        settingsProv.setTrackingEnabled(val);
                        notifProv.updateTrackingStatus(val);
                      },
                    ),
                  ],
                ),
              ),

              // Privacy & Data section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'BẢO MẬT & DỮ LIỆU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.security_rounded, color: Colors.blue),
                      title: Text('Xử lý cục bộ 100% (Local-only)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Toàn bộ nội dung thông báo được xử lý và lưu trữ hoàn toàn cục bộ trên thiết bị của bạn qua SQLite. '
                        'Ứng dụng không gửi dữ liệu ra ngoài, không sử dụng server đám mây (cloud) và không có backend trong bản MVP.',
                      ),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.lock_outline_rounded, color: Colors.indigo),
                      title: Text('Không can thiệp ứng dụng khác', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Ứng dụng không truy cập vào cơ sở dữ liệu riêng của các ứng dụng khác và tuyệt đối không sử dụng dịch vụ Hỗ trợ tiếp cận (Accessibility Service).',
                      ),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: Colors.grey),
                      title: Text('Phạm vi tiếp nhận thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Ứng dụng chỉ tiếp nhận các thông báo được hệ điều hành Android chuyển tiếp công khai qua NotificationListenerService. '
                        'Khả năng nhận thông báo có thể bị gián đoạn nếu thiết bị của bạn áp dụng chính sách tối ưu hóa pin hoặc tắt dịch vụ chạy ngầm.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      title: const Text('Xóa toàn bộ dữ liệu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Xóa vĩnh viễn toàn bộ lịch sử thông báo đã lưu trong SQLite cục bộ'),
                      onTap: () => _confirmClearData(context),
                    ),
                  ],
                ),
              ),

              // About section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'THÔNG TIN ỨNG DỤNG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(AppConstants.appName),
                  subtitle: const Text('Phiên bản: ${AppConstants.appVersion} (Full Pipeline & Analytics)'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
