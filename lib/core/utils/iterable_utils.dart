// lib/core/utils/iterable_utils.dart

/// 같은 기준으로 key를 뽑아서 그룹핑하는 유틸
Map<K, List<T>> groupBy<T, K>(List<T> list, K Function(T) keyFn) {
  final Map<K, List<T>> result = {};
  for (var element in list) {
    final k = keyFn(element);
    result.putIfAbsent(k, () => []).add(element);
  }
  return result;
}

/// 리스트 중 amount > 0일 때 모두 더하기 (수입 합계)
int sumPositiveAmounts<T>(Iterable<T> list, int Function(T) amountFn) {
  return list.where((e) => amountFn(e) > 0).fold(0, (s, e) => s + amountFn(e));
}

/// 리스트 중 amount < 0일 때 절댓값으로 더하기 (지출 합계)
int sumNegativeAbsAmounts<T>(Iterable<T> list, int Function(T) amountFn) {
  return list
      .where((e) => amountFn(e) < 0)
      .fold(0, (s, e) => s + amountFn(e).abs());
}
