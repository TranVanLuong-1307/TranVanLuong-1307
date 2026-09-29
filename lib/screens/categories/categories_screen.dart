import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/notification_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/category_card.dart';

class CategoriesScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const CategoriesScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục thông báo'),
      ),
      body: Consumer2<CategoryProvider, NotificationProvider>(
        builder: (context, catProv, notifProv, _) {
          return RefreshIndicator(
            onRefresh: () => catProv.loadCategoryStats(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: NotificationCategory.values.length,
              itemBuilder: (context, index) {
                final category = NotificationCategory.values[index];
                final count = catProv.getCount(category);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CategoryCard(
                    category: category,
                    count: count,
                    onTap: () async {
                      // Set filter and switch to All Notifications Tab
                      await notifProv.clearAllFilters();
                      await notifProv.filterByCategory(category);
                      onNavigateToTab?.call(1);
                    },
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
