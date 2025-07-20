import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../account/services/account_service.dart'
    show Account, AccountService;

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return AccountService.fetchAccounts();
});
