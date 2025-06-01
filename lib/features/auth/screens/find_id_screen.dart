import 'package:doitmoney_flutter/features/auth/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/common_input.dart';
import '../../../shared/widgets/common_button.dart';
import '../services/auth_service.dart';

class FindIdPage extends ConsumerStatefulWidget {
  const FindIdPage({super.key});

  @override
  ConsumerState<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends ConsumerState<FindIdPage> {
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
          CommonInput(
            hint: '전화번호 (01012345678)',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          if (_result.isNotEmpty) Text(_result),
        ],
      ),
      footer: CommonElevatedButton(
        text: '찾기',
        enabled: _canSubmit,
        onPressed: _find,
      ),
    );
  }
}
