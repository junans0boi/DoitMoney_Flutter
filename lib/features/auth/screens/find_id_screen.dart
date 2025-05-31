// lib/screens/auth/find_id_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../services/auth_service.dart';

/// 전화번호로 가입된 이메일(아이디)을 찾는 화면
class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  final _phoneCtrl = TextEditingController();
  String _result = '';

  bool get _canSubmit => _phoneCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _phoneCtrl
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final email = await AuthService.findIdByPhone(_phoneCtrl.text.trim());
    setState(() {
      _result = email != null ? '가입된 이메일: $email' : '일치하는 정보가 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '아이디 찾기',
      body: Column(
        children: [
          AuthInput(
            hint: '전화번호 (01012345678)',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          if (_result.isNotEmpty) Text(_result),
        ],
      ),
      footer: AuthButton(text: '찾기', enabled: _canSubmit, onPressed: _find),
    );
  }
}
