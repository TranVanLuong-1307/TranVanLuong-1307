import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/enums/notification_category.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/notification_repository.dart';
import '../../models/notification_data.dart';
import '../../models/notification_record.dart';
import '../../services/analyzer/notification_analyzer.dart';
import '../../services/notification/notification_filter.dart';
import '../../services/notification/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _tag = 'NotificationProvider';

  final INotificationRepository _repository;
  final INotificationService _notificationService;
  final INotificationFilter _filter;
  final INotificationAnalyzer _analyzer;

  StreamSubscription<NotificationData>? _notificationSubscription;
  bool _isTrackingEnabled = true;

  // Notification list & loading state
  List<NotificationRecord> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 50;
  int _currentOffset = 0;

  // Filter criteria
  String _searchQuery = '';
  NotificationCategory? _selectedCategory;
  String? _selectedPackageName;
  bool _onlyFavorites = false;
  bool _onlyUnread = false;

  // Dashboard & Badge metrics
  int _totalCount = 0;
  int _todayCount = 0;
  int _favoriteCount = 0;
  int _unreadCount = 0;

  NotificationProvider({
    INotificationRepository? repository,
    INotificationService? notificationService,
    INotificationFilter? filter,
    INotificationAnalyzer? analyzer,
  })  : _repository = repository ?? NotificationRepository(),
        _notificationService = notificationService ?? NotificationService(),
        _filter = filter ?? NotificationFilter(),
        _analyzer = analyzer ?? NotificationAnalyzer();

  List<NotificationRecord> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  NotificationCategory? get selectedCategory => _selectedCategory;
  String? get selectedPackageName => _selectedPackageName;
  bool get onlyFavorites => _onlyFavorites;
  bool get onlyUnread => _onlyUnread;

  int get totalCount => _totalCount;
  int get todayCount => _todayCount;
  int get favoriteCount => _favoriteCount;
  int get unreadCount => _unreadCount;
  Map<String, int> _dailyCountsLast7Days = {};
  Map<String, int> get dailyCountsLast7Days => _dailyCountsLast7Days;

  bool get hasActiveFilter =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedPackageName != null ||
      _onlyFavorites ||
      _onlyUnread;

  bool get isListening => _notificationSubscription != null && _notificationService.isListening;

  /// Start listening to incoming notification stream from Android OS
  void startNotificationPipeline({bool isTrackingEnabled = true}) {
    _isTrackingEnabled = isTrackingEnabled;

    if (_notificationSubscription != null) {
      AppLogger.debug(_tag, 'Pipeline already subscribed. Re-subscribing safely.');
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
    }

    _notificationService.startListening();
    _notificationSubscription = _notificationService.notificationStream.listen(
      _onIncomingNotification,
      onError: (error) {
        AppLogger.error(_tag, 'Error from notification stream', error);
      },
    );

    AppLogger.info(_tag, 'Notification ingestion pipeline started.');
  }

  /// Update tracking toggle dynamically from Settings
  void updateTrackingStatus(bool enabled) {
    _isTrackingEnabled = enabled;
    AppLogger.info(_tag, 'Notification tracking status updated: enabled=$enabled');
  }

  /// Core Pipeline Handler for each incoming notification
  Future<void> _onIncomingNotification(NotificationData data) async {
    try {
      // 1. NotificationFilter
      final filterResult = _filter.evaluate(data, isTrackingEnabled: _isTrackingEnabled);
      if (!filterResult.isAccepted) {
        AppLogger.debug(_tag, 'Notification rejected by filter: ${filterResult.reason}');
        return;
      }

      // 2. NotificationAnalyzer
      final record = _analyzer.process(data);
      if (record == null) {
        AppLogger.debug(_tag, 'Analyzer returned null record. Skipping save.');
        return;
      }

      // 3. Duplicate Handling Check
      final isDuplicate = await _repository.hasRecentDuplicate(
        record.packageName,
        record.title,
        record.content,
        record.timestamp,
        windowMs: 3000,
      );
      if (isDuplicate) {
        AppLogger.debug(_tag, 'Duplicate notification detected. Skipping SQLite insertion.');
        return;
      }

      // 4. SQLite Persistence via Repository
      final insertedId = await _repository.saveNotification(record);
      final savedRecord = record.copyWith(id: insertedId);

      // 5. Update in-memory state if matches current active filters
      if (_matchesActiveFilters(savedRecord)) {
        _notifications.insert(0, savedRecord);
      }
      _totalCount++;
      _todayCount++;
      _unreadCount++;

      AppLogger.info(_tag, 'New notification ingested & persisted: id=$insertedId, app="${savedRecord.appName}"');

      // 6. Notify UI
      notifyListeners();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process incoming notification in pipeline', e);
    }
  }

  bool _matchesActiveFilters(NotificationRecord r) {
    if (_onlyFavorites && !r.isFavorite) return false;
    if (_onlyUnread && r.isRead) return false;
    if (_selectedCategory != null && r.category != _selectedCategory) return false;
    if (_selectedPackageName != null && r.packageName != _selectedPackageName) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final titleMatch = r.title?.toLowerCase().contains(q) ?? false;
      final contentMatch = r.content?.toLowerCase().contains(q) ?? false;
      final appMatch = r.appName.toLowerCase().contains(q);
      final pkgMatch = r.packageName.toLowerCase().contains(q);
      if (!titleMatch && !contentMatch && !appMatch && !pkgMatch) return false;
    }
    return true;
  }

  /// Load notifications from SQLite with current filters and pagination
  Future<void> loadNotifications({bool refresh = true}) async {
    if (refresh) {
      _currentOffset = 0;
      _hasMore = true;
      _isLoading = true;
      notifyListeners();
    }

    try {
      final items = await _repository.getFilteredNotifications(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        packageName: _selectedPackageName,
        isFavorite: _onlyFavorites ? true : null,
        isRead: _onlyUnread ? false : null,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (refresh) {
        _notifications = items;
      } else {
        _notifications.addAll(items);
      }

      _hasMore = items.length == _pageSize;
      _currentOffset += items.length;

      await _refreshCounts();
    } catch (e) {
      AppLogger.error(_tag, 'Error loading notifications', e);
      if (refresh) _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more items when reaching the end of the scroll view
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await loadNotifications(refresh: false);
  }

  // --- Search & Filter Methods ---

  Future<void> search(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query.trim();
    await loadNotifications(refresh: true);
  }

  Future<void> filterByCategory(NotificationCategory? category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadNotifications(refresh: true);
  }

  Future<void> filterByPackage(String? packageName) async {
    if (_selectedPackageName == packageName) return;
    _selectedPackageName = packageName;
    await loadNotifications(refresh: true);
  }

  Future<void> toggleFavoritesFilter() async {
    _onlyFavorites = !_onlyFavorites;
    await loadNotifications(refresh: true);
  }

  Future<void> toggleUnreadFilter() async {
    _onlyUnread = !_onlyUnread;
    await loadNotifications(refresh: true);
  }

  Future<void> clearAllFilters() async {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPackageName = null;
    _onlyFavorites = false;
    _onlyUnread = false;
    await loadNotifications(refresh: true);
  }

  // --- Item State Mutation (Persisted to SQLite) ---

  Future<void> toggleFavorite(NotificationRecord record) async {
    if (record.id == null) return;
    final newStatus = !record.isFavorite;
    final success = await _repository.toggleFavorite(record.id!, newStatus);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == record.id);
      if (index != -1) {
        _notifications[index] = record.copyWith(isFavorite: newStatus);
        await _refreshCounts();
        notifyListeners();
      }
    }
  }

  Future<void> toggleReadStatus(NotificationRecord record) async {
    if (record.id == null) return;
    final newStatus = !record.isRead;
    final success = newStatus
        ? await _repository.markAsRead(record.id!)
        : await _repository.markAsUnread(record.id!);

    if (success) {
      final index = _notifications.indexWhere((n) => n.id == record.id);
      if (index != -1) {
        _notifications[index] = record.copyWith(isRead: newStatus);
        await _refreshCounts();
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(NotificationRecord record) async {
    if (record.id == null || record.isRead) return;
    final success = await _repository.markAsRead(record.id!);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == record.id);
      if (index != -1) {
        _notifications[index] = record.copyWith(isRead: true);
        await _refreshCounts();
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    _isLoading = true;
    notifyListeners();
    await _repository.markAllAsRead();
    await loadNotifications(refresh: true);
  }

  Future<void> deleteNotification(NotificationRecord record) async {
    if (record.id == null) return;
    final success = await _repository.deleteNotification(record.id!);
    if (success) {
      _notifications.removeWhere((n) => n.id == record.id);
      await _refreshCounts();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _isLoading = true;
    notifyListeners();
    await _repository.clearAllNotifications();
    _notifications = [];
    _currentOffset = 0;
    _hasMore = false;
    await _refreshCounts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshCounts() async {
    _totalCount = await _repository.getTotalCount();
    _todayCount = await _repository.getTodayCount();
    _favoriteCount = await _repository.getFavoriteCount();
    _unreadCount = await _repository.getUnreadCount();
    _dailyCountsLast7Days = await _repository.getDailyCountsLast7Days();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notificationService.dispose();
    AppLogger.debug(_tag, 'NotificationProvider disposed and subscriptions cancelled.');
    super.dispose();
  }
}
