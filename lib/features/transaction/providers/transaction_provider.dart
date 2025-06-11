import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/services/account_service.dart';
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
final dateFilteredTransactionsProvider = Provider<List<Transaction>>((ref) {
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

/// 1) 검색어 상태
final searchQueryProvider = StateProvider<String>((_) => '');

/// 2) 날짜·계좌 필터 후, 검색어까지 적용한 최종 필터된 거래 리스트
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final byDate = ref.watch(dateFilteredTransactionsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return byDate;

  return byDate.where((tx) {
    return tx.description.toLowerCase().contains(query) ||
        tx.category.toLowerCase().contains(query) ||
        tx.amount.toString().contains(query);
  }).toList();
});

/// 계좌-목록
final accountsProvider = FutureProvider.autoDispose(
  (_) => AccountService.fetchAccounts(),
);
