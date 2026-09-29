import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/notification_category.dart';
import '../../models/notification_record.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_card.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, NotificationRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả thông báo'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProv, _) {
              if (notifProv.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all_rounded),
                  tooltip: 'Đánh dấu tất cả đã đọc',
                  onPressed: () async {
                    await notifProv.markAllAsRead();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc')),
                      );
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProv, _) {
          return Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tiêu đề, nội dung, app...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifProv.search('');
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) => notifProv.search(val),
                  onChanged: (val) {
                    if (val.isEmpty) {
                      notifProv.search('');
                    }
                  },
                ),
              ),

              // Filter Chips Carousel
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Active Filters Reset Button
                    if (notifProv.hasActiveFilter) ...[
                      ActionChip(
                        avatar: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Xóa bộ lọc'),
                        backgroundColor: Colors.red.shade50,
                        labelStyle: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
                        onPressed: () {
                          _searchController.clear();
                          notifProv.clearAllFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Favorites Filter Chip
                    FilterChip(
                      avatar: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: notifProv.onlyFavorites ? Colors.amber : Colors.grey,
                      ),
                      label: const Text('Yêu thích'),
                      selected: notifProv.onlyFavorites,
                      onSelected: (_) => notifProv.toggleFavoritesFilter(),
                    ),
                    const SizedBox(width: 8),

                    // Unread Filter Chip
                    FilterChip(
                      avatar: Icon(
                        Icons.mark_email_unread_rounded,
                        size: 16,
                        color: notifProv.onlyUnread ? Colors.blue : Colors.grey,
                      ),
                      label: Text('Chưa đọc (${notifProv.unreadCount})'),
                      selected: notifProv.onlyUnread,
                      onSelected: (_) => notifProv.toggleUnreadFilter(),
                    ),
                    const SizedBox(width: 8),

                    // Package Filter Chip (if selected)
                    if (notifProv.selectedPackageName != null) ...[
                      InputChip(
                        label: Text('App: ${notifProv.selectedPackageName}'),
                        onDeleted: () => notifProv.filterByPackage(null),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Category Filter Chips
                    FilterChip(
                      label: const Text('Tất cả danh mục'),
                      selected: notifProv.selectedCategory == null,
                      onSelected: (_) => notifProv.filterByCategory(null),
                    ),
                    const SizedBox(width: 8),
                    ...NotificationCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat.displayName),
                          selected: notifProv.selectedCategory == cat,
                          onSelected: (_) => notifProv.filterByCategory(cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Notification List / Empty States
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => notifProv.loadNotifications(refresh: true),
                  child: notifProv.isLoading && notifProv.notifications.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : notifProv.notifications.isEmpty
                          ? notifProv.hasActiveFilter
                              ? const EmptyState(
                                  icon: Icons.filter_alt_off_rounded,
                                  title: 'Không tìm thấy kết quả phù hợp',
                                  subtitle: 'Thử tìm từ khóa khác hoặc xóa bớt tiêu chí lọc',
                                )
                              : const EmptyState(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Chưa có thông báo nào được lưu',
                                  subtitle: 'Các thông báo mới xuất hiện trên điện thoại sẽ tự động lưu vào đây',
                                )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: notifProv.notifications.length + (notifProv.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == notifProv.notifications.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }

                                final record = notifProv.notifications[index];
                                return NotificationCard(
                                  record: record,
                                  onTap: () => _navigateToDetail(context, record),
                                  onFavoriteToggle: () => notifProv.toggleFavorite(record),
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
