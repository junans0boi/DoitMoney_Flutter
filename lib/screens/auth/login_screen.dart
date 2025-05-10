// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/sns_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool get formOk => email.text.isNotEmpty && password.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // 리스너 등록: 텍스트가 바뀔 때마다 rebuild
    email.addListener(_onFormChanged);
    password.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    email
      ..removeListener(_onFormChanged)
      ..dispose();
    password
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!formOk) return;
    final success = await AuthService.login(email.text, password.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('로그인 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'DoitMoney',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            '로그인',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          AuthInput(
            hint: '아이디 (이메일)',
            controller: email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthInput(
            hint: '비밀번호',
            controller: password,
            obscure: true,
          ),
          const SizedBox(height: 24),
          AuthButton(
            text: '로그인하기',
            enabled: formOk,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text.rich(
              TextSpan(
                text: 'SNS',
                style: TextStyle(fontWeight: FontWeight.bold),
                children: [TextSpan(text: ' 계정으로 로그인하기')],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _snsRow(),
        ],
      ),
      footer: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/find-id'),
                child: const Text('아이디 찾기'),
              ),
              Container(width: 1, height: 14, color: Colors.grey.shade400),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/find-password'),
                child: const Text('비밀번호 찾기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthButton(
            text: '계정이 없으신가요? 간편가입하기',
            outline: true,
            onPressed: () => Navigator.pushNamed(context, '/signup'),
          ),
        ],
      ),
    );
  }

  Widget _snsRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SnsButton(
            background: const Color(0xFF03C75A),
            child: const Text(
              'N',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            onTap: () {}, // 네이버 로그인
          ),
          const SizedBox(width: 20),
          SnsButton(
            background: const Color(0xFFFEE500),
            child: const Text(
              'K',
              style: TextStyle(
                color: Color(0xFF191600),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () {}, // 카카오 로그인
          ),
          const SizedBox(width: 20),
          SnsButton(
            background: const Color(0xFF4267B2),
            child: const Icon(Icons.facebook, color: Colors.white),
            onTap: () {}, // 페이스북 로그인
          ),
          const SizedBox(width: 20),
          SnsButton(
            background: Colors.black,
            child: const Icon(Icons.apple, color: Colors.white),
            onTap: () {}, // Apple 로그인
          ),
        ],
      );
}