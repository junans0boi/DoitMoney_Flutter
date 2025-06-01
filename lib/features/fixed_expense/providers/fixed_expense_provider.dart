// lib/features/fixed_expense/providers/fixed_expense_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fixed_expense_service.dart';

final fixedExpensesProvider = FutureProvider.autoDispose<List<FixedExpense>>(
  (_) => FixedExpenseService.fetchFixedExpenses(),
);
