import '../../core/enums/notification_category.dart';
import '../../core/utils/text_normalizer.dart';
import '../../models/notification_data.dart';

abstract class ICategoryClassifier {
  NotificationCategory classify(NotificationData data);
}

class CategoryClassifier implements ICategoryClassifier {
  // Regex matching financial currency amounts (e.g. "200.000đ", "500,000 VND", "+50.000 d", "$50")
  static final RegExp _currencyPattern = RegExp(
    r'\d+(?:[.,]\d+)*\s*(?:đ|vnd|dong|usd|\$)',
    caseSensitive: false,
  );

  // Regex matching OTP or verification codes (e.g. "Mã OTP 123456", "code is 849201")
  static final RegExp _otpPattern = RegExp(
    r'(?:otp|ma\s+xac\s+thuc|verification\s+code|security\s+code)[^\d]*(\d{4,8})',
    caseSensitive: false,
  );

  @override
  NotificationCategory classify(NotificationData data) {
    final pkg = data.packageName.toLowerCase();
    final combinedText = '${data.title ?? ''} ${data.content ?? ''}'.trim();
    final normalizedText = TextNormalizer.normalize(combinedText);

    // -------------------------------------------------------------
    // RULE 1: HIGHEST PRIORITY - Security & Verification / OTP
    // Even if from a bank or messaging app, OTP codes are Security!
    // -------------------------------------------------------------
    if (_otpPattern.hasMatch(normalizedText) ||
        TextNormalizer.containsAny(combinedText, [
          'ma xac thuc',
          'ma xac minh',
          'ma bao mat',
          'verification code',
          'security code',
          'one time password',
          'reset password',
          'khoi phuc mat khau',
          'dang nhap tu thiet bi moi',
          'canh bao bao mat',
        ])) {
      return NotificationCategory.security;
    }

    // -------------------------------------------------------------
    // RULE 2: Specific Known Application Packages
    // -------------------------------------------------------------
    if (pkg.contains('com.google.android.gm') ||
        pkg.contains('.mail') ||
        pkg.contains('outlook') ||
        pkg.contains('thunderbird')) {
      return NotificationCategory.email;
    }

    if (pkg.contains('zalo') ||
        pkg.contains('whatsapp') ||
        pkg.contains('telegram') ||
        pkg.contains('orca') || // Facebook Messenger
        pkg.contains('viber') ||
        pkg.contains('messaging') ||
        pkg.contains('mms')) {
      return NotificationCategory.messaging;
    }

    if (pkg.contains('shopee') ||
        pkg.contains('lazada') ||
        pkg.contains('tiki') ||
        pkg.contains('sendo') ||
        pkg.contains('aliexpress') ||
        pkg.contains('amazon')) {
      // If shopping app specifically mentions delivery in content, route to DELIVERY
      if (TextNormalizer.containsAny(combinedText, [
        'dang giao',
        'da giao',
        'giao hang',
        'shipper',
        'dang tren duong giao',
      ])) {
        return NotificationCategory.delivery;
      }
      return NotificationCategory.shopping;
    }

    if (pkg.contains('grab') ||
        pkg.contains('gojek') ||
        pkg.contains('ahamove') ||
        pkg.contains('delivery') ||
        pkg.contains('shopeefood') ||
        pkg.contains('be.com')) {
      return NotificationCategory.delivery;
    }

    if (pkg.contains('facebook') ||
        pkg.contains('instagram') ||
        pkg.contains('tiktok') ||
        pkg.contains('twitter') ||
        pkg.contains('threads') ||
        pkg.contains('weibo')) {
      return NotificationCategory.social;
    }

    if (pkg.contains('youtube') ||
        pkg.contains('spotify') ||
        pkg.contains('netflix') ||
        pkg.contains('zingmp3') ||
        pkg.contains('soundcloud')) {
      return NotificationCategory.entertainment;
    }

    if (pkg.contains('bank') ||
        pkg.contains('momo') ||
        pkg.contains('zalopay') ||
        pkg.contains('vnpay') ||
        pkg.contains('vietinbank') ||
        pkg.contains('techcombank') ||
        pkg.contains('bidv')) {
      return NotificationCategory.finance;
    }

    if (pkg == 'com.android.systemui' ||
        pkg == 'com.android.settings' ||
        pkg == 'android' ||
        pkg == 'com.google.android.packageinstaller') {
      return NotificationCategory.system;
    }

    // -------------------------------------------------------------
    // RULE 3: Content & Context Keyword Matching
    // -------------------------------------------------------------

    // A. DELIVERY
    if (TextNormalizer.containsAny(combinedText, [
      'don hang dang duoc giao',
      'don hang dang giao',
      'da giao thanh cong',
      'giao hang thanh cong',
      'tai xe dang den',
      'shipper dang den',
      'dang tren duong giao',
      'shipped',
      'out for delivery',
      'delivered',
      'tracking number',
    ])) {
      return NotificationCategory.delivery;
    }

    // B. FINANCE
    if (_currencyPattern.hasMatch(combinedText) ||
        TextNormalizer.containsAny(combinedText, [
          'bien dong so du',
          'so du tk',
          'chuyen khoan thanh cong',
          'nhan tien tu',
          'giao dich thanh cong',
          'thanh toan thanh cong',
          'so du kha dung',
          'nap tien thanh cong',
          'rut tien thanh cong',
        ])) {
      return NotificationCategory.finance;
    }

    // C. SHOPPING
    if (TextNormalizer.containsAny(combinedText, [
      'ma giam gia',
      'voucher',
      'flash sale',
      'dat hang thanh cong',
      'xac nhan don hang',
      'gio hang cua ban',
      'san pham dang giam gia',
      'deal hot',
      'khuyen mai dac biet',
    ])) {
      return NotificationCategory.shopping;
    }

    // D. MESSAGING
    if (TextNormalizer.containsAny(combinedText, [
      'da gui tin nhan',
      'da gui mot tin nhan',
      'nhan tin cho ban',
      'da gui cho ban mot anh',
      'da gui mot video',
      'cuoc goi nho tu',
      'da nhac den ban trong mot cuoc tro chuyen',
      'new message from',
      'sent you a message',
    ])) {
      return NotificationCategory.messaging;
    }

    // E. EMAIL
    if (TextNormalizer.containsAny(combinedText, [
      'email moi',
      'thu moi tu',
      'hop thu den',
      'new email from',
      'unread email',
    ])) {
      return NotificationCategory.email;
    }

    // F. SOCIAL
    if (TextNormalizer.containsAny(combinedText, [
      'da thich bai viet',
      'da binh luan',
      'da chia se bai viet',
      'da theo doi ban',
      'liked your post',
      'commented on your',
      'started following you',
    ])) {
      return NotificationCategory.social;
    }

    // G. SYSTEM
    if (TextNormalizer.containsAny(combinedText, [
      'pin yeu',
      'pin day',
      'sac pin',
      'bo nho day',
      'dung luong con lai thap',
      'cap nhat phan mem',
      'cap nhat he thong',
      'system update',
      'battery full',
      'low battery',
    ])) {
      return NotificationCategory.system;
    }

    // H. ENTERTAINMENT
    if (TextNormalizer.containsAny(combinedText, [
      'video moi tu',
      'bai hat moi',
      'dang phat',
      'tap phim moi',
      'livestream bat dau',
      'now playing',
    ])) {
      return NotificationCategory.entertainment;
    }

    // Default Fallback
    return NotificationCategory.other;
  }
}
