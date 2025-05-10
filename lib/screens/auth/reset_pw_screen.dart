import 'package:flutter/material.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../services/auth_service.dart';

class ResetPwPage extends StatefulWidget {
  const ResetPwPage({super.key});

  @override
  State<ResetPwPage> createState() => _ResetPwPageState();
}

class _ResetPwPageState extends State<ResetPwPage> {
  final pw1 = TextEditingController();
  final pw2 = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    final ok = pw1.text == pw2.text && pw1.text.length >= 8;

    return AuthScaffold(
      title: '비밀번호 재설정',
      body: Column(
        children: [
          AuthInput(hint: '새 비밀번호', controller: pw1, obscure: true),
          const SizedBox(height: 12),
          AuthInput(hint: '비밀번호 확인', controller: pw2, obscure: true),
          if (msg.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(msg, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
      footer: AuthButton(
        text: '변경하기',
        enabled: ok,
        onPressed: () async {
          await AuthService.resetPassword('TOKEN_FROM_LINK', pw1.text);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          }
        },
      ),
    );
  }
}