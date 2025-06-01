// lib/features/transaction/screens/upload_complete_page.dart (리팩터 후)

// ignore_for_file: unused_import, use_super_parameters

import 'package:doitmoney_flutter/shared/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/styles.dart';
import '../../account/services/account_service.dart' show Account;

class UploadCompletePage extends StatelessWidget {
  final Account account;
  final int count;

  const UploadCompletePage({
    Key? key,
    required this.account,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final last4 =
        account.accountNumber.length >= 4
            ? account.accountNumber.substring(account.accountNumber.length - 4)
            : account.accountNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Image.asset(
              'assets/images/upload_avatar.gif',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              '${account.institutionName}($last4) 계좌로\n거래 등록을 성공했어요!',
              textAlign: TextAlign.center,
              style: kTitleText.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('입금 계좌', style: kBodyText),
                        SizedBox(height: 4),
                        Text('등록 건수', style: kBodyText),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${account.institutionName}($last4)',
                          style: kBodyText,
                        ),
                        const SizedBox(height: 4),
                        Text('$count개 거래', style: kBodyText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CommonElevatedButton(
                text: '확인',
                onPressed: () {
                  context.go('/ledger');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
