// lib/features/savings/providers/savings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_goal.dart';
import '../services/savings_service.dart';

final savingsGoalsProvider = FutureProvider.autoDispose<List<SavingsGoal>>((
  ref,
) {
  return SavingsService.fetchGoals();
});
