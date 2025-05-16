// lib/providers/transaction_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/account_service.dart';

/// 계좌 목록 Provider
final accountsProvider = FutureProvider.autoDispose<List<Account>>(
  (_) => AccountService.fetchAccounts(),
);
