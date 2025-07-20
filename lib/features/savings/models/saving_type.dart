// ** 추후 현금 기능 추가 예정 **
enum SavingType { ACCOUNT }

extension SavingTypeExt on SavingType {
  String get name => toString().split('.').last;
  String get display {
    switch (this) {
      case SavingType.ACCOUNT:
        return '계좌 자동적립';
    }
  }
}
