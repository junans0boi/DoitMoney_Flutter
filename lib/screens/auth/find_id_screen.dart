import 'package:flutter/material.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../services/auth_service.dart';

class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  final phone = TextEditingController();
  String result = '';

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '아이디 찾기',
      body: Column(
        children: [
          AuthInput(hint: '전화번호 (- 없이)', controller: phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          if (result.isNotEmpty) Text(result),
        ],
      ),
      footer: AuthButton(
        text: '찾기',
        enabled: phone.text.isNotEmpty,
        onPressed: () async {
          final email = await AuthService.findIdByPhone(phone.text);
          setState(() {
            result = email != null ? '가입 이메일: $email' : '일치하는 정보가 없습니다.';
          });
        },
      ),
    );
  }
}