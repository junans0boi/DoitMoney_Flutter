// /Users/junzzang_m1/Documents/GitHub/DoitMoney_Flutter/lib/providers/transaction_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_service.dart';
import '../services/transaction_service.dart';

/// 선택된 월
final selectedMonthProvider = StateProvider<DateTime>((_) => DateTime.now());

/// 마지막 새로고침 시간
final lastRefreshProvider = StateProvider<DateTime>((_) => DateTime.now());

/// 선택된 계좌 목록
final selectedAccountsProvider = StateProvider<List<String>>((_) => []);

/// 선택된 날짜 범위 (null = 전체)
final dateRangeProvider = StateProvider<DateTimeRange?>((_) => null);

/// 모든 거래 데이터
final allTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>(
  (_) => TransactionService.fetchTransactions(),
);

/// 필터된 거래 리스트
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref
      .watch(allTransactionsProvider)
      .maybeWhen(data: (list) => list, orElse: () => <Transaction>[]);
  final accounts = ref.watch(selectedAccountsProvider);
  final range = ref.watch(dateRangeProvider);
  final month = ref.watch(selectedMonthProvider);

  return all.where((t) {
    final inAccount = accounts.isEmpty || accounts.contains(t.accountName);

    if (range != null) {
      // If a dateRange is set, ignore the month-picker
      return inAccount &&
          !t.transactionDate.isBefore(range.start) &&
          !t.transactionDate.isAfter(range.end);
    } else {
      // Otherwise filter by selected month
      return inAccount &&
          t.transactionDate.year == month.year &&
          t.transactionDate.month == month.month;
    }
  }).toList();
});

/// 계좌-목록
final accountsProvider = FutureProvider.autoDispose(
  (_) => AccountService.fetchAccounts(),
);
