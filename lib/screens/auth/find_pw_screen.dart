import 'package:flutter/material.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../services/auth_service.dart';

class FindPwPage extends StatefulWidget {
  const FindPwPage({super.key});

  @override
  State<FindPwPage> createState() => _FindPwPageState();
}

class _FindPwPageState extends State<FindPwPage> {
  final email = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '비밀번호 재설정',
      body: Column(
        children: [
          AuthInput(hint: '가입 이메일', controller: email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 24),
          if (msg.isNotEmpty) Text(msg),
        ],
      ),
      footer: AuthButton(
        text: '메일 보내기',
        enabled: email.text.isNotEmpty,
        onPressed: () async {
          await AuthService.sendResetMail(email.text);
          setState(() => msg = '메일을 보냈습니다. 메일함을 확인해주세요.');
        },
      ),
    );
  }
}