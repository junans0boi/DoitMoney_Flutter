// lib/core/services/notification_handler_service.dart
import 'dart:math' as developer;

import '../../core/utils/transaction_message_parser.dart';
import '../../features/transaction/services/transaction_service.dart';

/// SMS/푸시 메시지를 공통으로 처리하는 서비스
/// - parseMessage()로 ParsedTxn을 얻고
/// - TransactionService.addTransaction() 호출
class NotificationHandlerService {
  /// [body]가 null이 아니면 파싱을 시도하고, 유효하다면 서버에 등록
  static Future<void> handleIncomingMessage(String? body) async {
    if (body == null) return;
    final parsed = parseMessage(body);
    if (parsed == null) return;

    try {
      final tx = parsed.toModel();
      await TransactionService.addTransaction(tx);
    } catch (e, st) {
      developer.log('Notification 오류: $e\n$st' as num);
    }
  }
}
