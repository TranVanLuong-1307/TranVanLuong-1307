class AppNameResolver {
  AppNameResolver._();

  static const Map<String, String> _knownPackages = {
    // Messaging & Social
    'com.zing.zalo': 'Zalo',
    'com.facebook.orca': 'Messenger',
    'com.facebook.katana': 'Facebook',
    'com.instagram.android': 'Instagram',
    'com.whatsapp': 'WhatsApp',
    'org.telegram.messenger': 'Telegram',
    'com.viber.voip': 'Viber',
    'com.twitter.android': 'X (Twitter)',
    'com.zhiliaoapp.musically': 'TikTok',

    // Email & Work
    'com.google.android.gm': 'Gmail',
    'com.microsoft.office.outlook': 'Outlook',
    'com.microsoft.teams': 'Microsoft Teams',
    'com.slack': 'Slack',

    // E-commerce & Delivery
    'com.shopee.vn': 'Shopee',
    'com.lazada.android': 'Lazada',
    'vn.tiki.app.tikiandroid': 'Tiki',
    'com.grabtaxi.passenger': 'Grab',
    'xyz.be.customer': 'Be',
    'com.gojek.app': 'Gojek',
    'com.shopeefood.consumer': 'ShopeeFood',
    'vn.ahamove.supporter': 'Ahamove',

    // Banking & Wallets
    'com.vcb.digibank': 'VCB Digibank',
    'com.mservice.momotransaction': 'MoMo',
    'com.vnpay.momo': 'VNPay',
    'vn.com.techcombank.bb.app': 'Techcombank',
    'com.mbmobile': 'MBBank',
    'com.vietinbank.ipay': 'VietinBank iPay',
    'com.bplus.bidv': 'BIDV SmartBanking',
    'com.vnpay.zalopay': 'ZaloPay',

    // Entertainment
    'com.google.android.youtube': 'YouTube',
    'com.spotify.music': 'Spotify',
    'com.netflix.mediaclient': 'Netflix',

    // System
    'com.android.systemui': 'Hệ thống Android',
    'com.android.settings': 'Cài đặt',
    'android': 'Hệ điều hành Android',
    'com.google.android.packageinstaller': 'Trình cài đặt gói',
  };

  /// Resolves a human-readable app name from package name, with safe fallback.
  static String resolve(String? packageName) {
    if (packageName == null || packageName.trim().isEmpty) {
      return 'Ứng dụng không xác định';
    }

    final lower = packageName.trim().toLowerCase();

    // Check direct known mapping
    if (_knownPackages.containsKey(lower)) {
      return _knownPackages[lower]!;
    }

    // Check partial package hint
    for (final entry in _knownPackages.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Safe fallback: extract last segment formatted cleanly
    final parts = lower.split('.');
    if (parts.isNotEmpty) {
      final last = parts.last;
      if (last.isNotEmpty) {
        return last[0].toUpperCase() + last.substring(1);
      }
    }

    return 'Ứng dụng ($packageName)';
  }
}
