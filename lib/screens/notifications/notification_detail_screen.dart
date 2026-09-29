import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/notification_record.dart';
import '../../providers/notification_provider.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationRecord record;

  const NotificationDetailScreen({super.key, required this.record});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late NotificationRecord _currentRecord;

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.record;

    // Automatically mark as read when user opens detail view
    if (!_currentRecord.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().markAsRead(_currentRecord);
        setState(() {
          _currentRecord = _currentRecord.copyWith(isRead: true);
        });
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label vào bộ nhớ tạm'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thông báo này?'),
        content: const Text('Thông báo này sẽ bị xóa vĩnh viễn khỏi SQLite.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<NotificationProvider>().deleteNotification(_currentRecord);
              if (mounted) {
                Navigator.pop(context); // Go back to list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa thông báo')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.getCategoryColor(_currentRecord.category);
    final catIcon = AppColors.getCategoryIcon(_currentRecord.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        actions: [
          // Favorite action
          IconButton(
            icon: Icon(
              _currentRecord.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _currentRecord.isFavorite ? Colors.amber : null,
            ),
            tooltip: _currentRecord.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
            onPressed: () async {
              await context.read<NotificationProvider>().toggleFavorite(_currentRecord);
              setState(() {
                _currentRecord = _currentRecord.copyWith(isFavorite: !_currentRecord.isFavorite);
              });
            },
          ),
          // Delete action
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Xóa thông báo',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Card: App Info & Category Badge
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(catIcon, color: catColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentRecord.appName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentRecord.packageName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _currentRecord.category.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Ưu tiên: ${_currentRecord.priority.displayName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification Content Card (Original Text Preserved)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NỘI DUNG GỐC',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      if (_currentRecord.content != null && _currentRecord.content!.isNotEmpty)
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.copy_rounded, color: Colors.blue),
                          tooltip: 'Sao chép nội dung',
                          onPressed: () => _copyToClipboard(_currentRecord.content!, 'nội dung'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_currentRecord.title != null && _currentRecord.title!.isNotEmpty) ...[
                    SelectableText(
                      _currentRecord.title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentRecord.content != null && _currentRecord.content!.isNotEmpty) ...[
                    SelectableText(
                      _currentRecord.content!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '(Thông báo không có nội dung text mở rộng)',
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata & Timestamp Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMetaRow(
                    Icons.access_time_rounded,
                    'Thời gian nhận',
                    '${DateFormatter.formatDateTime(_currentRecord.dateTime)} (${DateFormatter.formatRelative(_currentRecord.dateTime)})',
                  ),
                  const Divider(height: 20),
                  _buildMetaRow(
                    Icons.mark_email_read_outlined,
                    'Trạng thái',
                    _currentRecord.isRead ? 'Đã đọc' : 'Chưa đọc',
                    trailingAction: TextButton(
                      onPressed: () async {
                        await context.read<NotificationProvider>().toggleReadStatus(_currentRecord);
                        setState(() {
                          _currentRecord = _currentRecord.copyWith(isRead: !_currentRecord.isRead);
                        });
                      },
                      child: Text(_currentRecord.isRead ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc'),
                    ),
                  ),
                  const Divider(height: 20),
                  _buildMetaRow(
                    Icons.fingerprint_rounded,
                    'Database ID',
                    '#${_currentRecord.id ?? "N/A"}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String title, String value, {Widget? trailingAction}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ?trailingAction,
      ],
    );
  }
}
