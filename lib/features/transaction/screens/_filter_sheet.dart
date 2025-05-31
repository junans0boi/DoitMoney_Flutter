import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/colors.dart';
import '../../providers/transaction_providers.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accAsync = ref.watch(accountsProvider);

    // 초기값 복사
    final initAcc = [...ref.read(selectedAccountsProvider)];
    final initRange = ref.read(dateRangeProvider);

    // 임시 상태
    final tmpAcc = <String>{...initAcc};
    DateTimeRange? tmpRange = initRange;

    void save() {
      ref.read(selectedAccountsProvider.notifier).state = tmpAcc.toList();
      ref.read(dateRangeProvider.notifier).state = tmpRange;
      Navigator.pop(context);
    }

    return accAsync.when(
      data:
          (list) => StatefulBuilder(
            builder:
                (ctx, setState) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '필터',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // 계좌 체크박스
                      ...list.map(
                        (a) => CheckboxListTile(
                          dense: true,
                          value: tmpAcc.contains(a.institutionName),
                          title: Text(a.institutionName),
                          onChanged:
                              (v) => setState(
                                () =>
                                    v!
                                        ? tmpAcc.add(a.institutionName)
                                        : tmpAcc.remove(a.institutionName),
                              ),
                        ),
                      ),

                      const Divider(),

                      // 날짜 범위 선택
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: Text(
                          tmpRange == null
                              ? '전체 기간'
                              : '\${DateFormat.yMd().format(tmpRange!.start)}  –  \${DateFormat.yMd().format(tmpRange!.end)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(now.year - 10),
                            lastDate: DateTime(now.year + 1),
                            initialDateRange:
                                tmpRange ?? DateTimeRange(start: now, end: now),
                          );
                          if (picked != null) setState(() => tmpRange = picked);
                        },
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                            ),
                            onPressed: save,
                            child: const Text(
                              '적용',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
      loading:
          () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Text('오류: \$e'),
          ),
    );
  }
}
