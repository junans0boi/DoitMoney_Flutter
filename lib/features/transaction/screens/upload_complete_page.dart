// lib/features/transaction/screens/upload_complete_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/common_button.dart';
import '../../../constants/styles.dart';
import 'package:doitmoney_flutter/features/account/services/account_service.dart'
    show Account;

class UploadCompletePage extends StatelessWidget {
  final Account account;
  final int uploadedCount;
  final int duplicateCount;

  const UploadCompletePage({
    Key? key,
    required this.account,
    required this.uploadedCount,
    required this.duplicateCount,
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
              '${account.institutionName}($last4) 계좌로\n$uploadedCount건 업로드 완료',
              textAlign: TextAlign.center,
              style: kTitleText.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            if (duplicateCount > 0)
              Text(
                '$duplicateCount건은 이미 등록되어\n업로드되지 않았습니다.',
                textAlign: TextAlign.center,
                style: kBodyText.copyWith(color: Colors.red),
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
                        Text('성공 등록 건수', style: kBodyText),
                        SizedBox(height: 4),
                        Text('중복 건수', style: kBodyText),
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
                        Text('$uploadedCount 건', style: kBodyText),
                        const SizedBox(height: 4),
                        Text('$duplicateCount 건', style: kBodyText),
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
                onPressed: () => context.go('/ledger'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
