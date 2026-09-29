import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/utils/text_normalizer.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/services/analyzer/category_classifier.dart';
import 'package:notification_insight/services/analyzer/finance_analyzer.dart';
import 'package:notification_insight/services/analyzer/generic_analyzer.dart';
import 'package:notification_insight/services/analyzer/messaging_analyzer.dart';
import 'package:notification_insight/services/analyzer/shopping_analyzer.dart';

void main() {
  group('Phase 3 - Specialized Analyzers & Extraction Tests', () {
    late FinanceAnalyzer financeAnalyzer;
    late ShoppingAnalyzer shoppingAnalyzer;
    late MessagingAnalyzer messagingAnalyzer;
    late GenericAnalyzer genericAnalyzer;
    late CategoryClassifier classifier;

    setUp(() {
      financeAnalyzer = FinanceAnalyzer();
      shoppingAnalyzer = ShoppingAnalyzer();
      messagingAnalyzer = MessagingAnalyzer();
      genericAnalyzer = GenericAnalyzer();
      classifier = CategoryClassifier();
    });

    test('Finance: extractAmount should extract real amount when present', () {
      expect(financeAnalyzer.extractAmount('Tài khoản +500.000đ tại VCB'), contains('500.000đ'));
      expect(financeAnalyzer.extractAmount('Số dư thay đổi: -200,000 VND'), contains('200,000 VND'));
      expect(financeAnalyzer.extractAmount('Bạn nhận được \$25.50 từ PayPal'), contains('\$25.50'));
    });

    test('Finance: extractAmount should return null when amount is absent (NO fabrication)', () {
      expect(financeAnalyzer.extractAmount('Thông báo bảo trì hệ thống ngân hàng'), isNull);
      expect(financeAnalyzer.extractAmount(''), isNull);
      expect(financeAnalyzer.extractAmount(null), isNull);
    });

    test('Shopping: extractOrderId should extract real order ID when present', () {
      expect(shoppingAnalyzer.extractOrderId('Đơn hàng #123 đang được đóng gói'), '123');
      expect(shoppingAnalyzer.extractOrderId('Đơn hàng #SPX987654 đã bàn giao vận chuyển'), 'SPX987654');
      expect(shoppingAnalyzer.extractOrderId('Xác nhận đơn hàng 892341 thành công'), '892341');
    });

    test('Shopping: extractOrderId should return null when no order ID is present (NO fabrication)', () {
      expect(shoppingAnalyzer.extractOrderId('Chào mừng bạn đến với chương trình Flash Sale'), isNull);
      expect(shoppingAnalyzer.extractOrderId(null), isNull);
    });

    test('Security: extractOtpCode should extract real numeric OTP code when present', () {
      expect(genericAnalyzer.extractOtpCode('Mã OTP của bạn là 849201. Hiệu lực 2 phút.'), '849201');
      expect(genericAnalyzer.extractOtpCode('Your verification code is 4321'), '4321');
    });

    test('Security: extractOtpCode should return null when OTP code is absent (NO fabrication)', () {
      expect(genericAnalyzer.extractOtpCode('Cảnh báo đăng nhập từ thiết bị lạ'), isNull);
      expect(genericAnalyzer.extractOtpCode(null), isNull);
    });

    test('Messaging: extractSender should extract real sender name when formatted', () {
      expect(messagingAnalyzer.extractSender('Nguyễn Văn A: Chiều nay họp nhé', null), 'Nguyễn Văn A');
      expect(messagingAnalyzer.extractSender('Lan đã gửi tin nhắn', null), 'Lan');
      expect(messagingAnalyzer.extractSender('Trần Tuấn', 'Alo bạn ơi'), 'Trần Tuấn');
    });

    test('Text Normalization: cleans Unicode Vietnamese, excess spaces, lowercase while preserving original', () {
      const original = '  ĐỒNG   Ý    và   Thanh   Toán  !  ';
      final normalized = TextNormalizer.normalize(original);

      expect(normalized, 'dong y va thanh toan !');
      // Original string remains unchanged
      expect(original, '  ĐỒNG   Ý    và   Thanh   Toán  !  ');
    });

    test('Contextual collision test: words with sub-tokens should not falsely trigger categories', () {
      // "cô đơn" contains "đơn" but is NOT a delivery order!
      const lonelyData = NotificationData(
        packageName: 'com.music.player',
        title: 'Bài hát: Cô đơn trên sofa',
        content: 'Đang phát bài hát',
        timestamp: 1000,
      );
      final lonelyCategory = classifier.classify(lonelyData);
      expect(lonelyCategory, isNot(NotificationCategory.delivery));

      // "đồng ý" contains "đồng" but is NOT a financial currency amount!
      const consentData = NotificationData(
        packageName: 'com.game.app',
        title: 'Điều khoản dịch vụ',
        content: 'Nhấn đồng ý để tiếp tục vào trò chơi',
        timestamp: 1000,
      );
      final consentCategory = classifier.classify(consentData);
      expect(consentCategory, isNot(NotificationCategory.finance));
    });
  });
}
