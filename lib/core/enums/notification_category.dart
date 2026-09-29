enum NotificationCategory {
  general,
  messaging,
  email,
  finance,
  shopping,
  delivery,
  social,
  security,
  system,
  entertainment,
  other;

  String get displayName {
    switch (this) {
      case NotificationCategory.general:
        return 'Chung';
      case NotificationCategory.messaging:
        return 'Tin nhắn';
      case NotificationCategory.email:
        return 'Email';
      case NotificationCategory.finance:
        return 'Tài chính';
      case NotificationCategory.shopping:
        return 'Mua sắm';
      case NotificationCategory.delivery:
        return 'Giao hàng';
      case NotificationCategory.social:
        return 'Mạng xã hội';
      case NotificationCategory.security:
        return 'Bảo mật / OTP';
      case NotificationCategory.system:
        return 'Hệ thống';
      case NotificationCategory.entertainment:
        return 'Giải trí';
      case NotificationCategory.other:
        return 'Khác';
    }
  }

  static NotificationCategory fromString(String? name) {
    if (name == null) return NotificationCategory.other;
    return NotificationCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => NotificationCategory.other,
    );
  }
}
