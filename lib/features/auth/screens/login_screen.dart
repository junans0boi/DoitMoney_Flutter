// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/sns_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool get _formOk => email.text.isNotEmpty && password.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    email.addListener(_onChanged);
    password.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    email
      ..removeListener(_onChanged)
      ..dispose();
    password
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formOk) return;

    final ok = await ref
        .read(authProvider.notifier)
        .signIn(email.text.trim(), password.text.trim());

    if (!mounted) return;
    if (ok) {
      // 로그인 성공 시 홈 화면으로 이동
      context.go('/');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 실패')));
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
          AuthInput(hint: '비밀번호', controller: password, obscure: true),
          const SizedBox(height: 24),
          AuthButton(text: '로그인하기', enabled: _formOk, onPressed: _handleLogin),
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
                onPressed: () => context.push('/find-id'),
                child: const Text('아이디 찾기'),
              ),
              Container(width: 1, height: 14, color: Colors.grey.shade400),
              TextButton(
                onPressed: () => context.push('/find-pw'),
                child: const Text('비밀번호 찾기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthButton(
            text: '계정이 없으신가요? 간편가입하기',
            outline: true,
            onPressed: () => context.push('/signup'),
          ),
        ],
      ),
    );
  }

  Widget _snsRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      SnsButton(
        background: Color(0xFF03C75A),
        child: Text(
          'N',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      SizedBox(width: 20),
      SnsButton(
        background: Color(0xFFFEE500),
        child: Text(
          'K',
          style: TextStyle(
            color: Color(0xFF191600),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      SizedBox(width: 20),
      SnsButton(
        background: Color(0xFF4267B2),
        child: Icon(Icons.facebook, color: Colors.white),
      ),
      SizedBox(width: 20),
      SnsButton(
        background: Colors.black,
        child: Icon(Icons.apple, color: Colors.white),
      ),
    ],
  );
}
