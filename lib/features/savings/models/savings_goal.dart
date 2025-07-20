// lib/features/savings/models/savings_goal.dart
import 'saving_type.dart';

class SavingsGoal {
  final int id;
  final String title;
  final int targetAmount;
  final int savedAmount;
  final int? targetAccountId; // <-- int? 로 변경

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.targetAccountId, // <-- nullable
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
    id: j['id'] as int,
    title: j['title'] as String,
    targetAmount: (j['targetAmount'] as num).toInt(),
    savedAmount: (j['savedAmount'] as num).toInt(),
    targetAccountId:
        j['targetAccountId'] != null
            ? (j['targetAccountId'] as num).toInt()
            : null, // <-- null 체크 후 캐스트
  );

  double get progress => targetAmount == 0 ? 0 : savedAmount / targetAmount;
}
