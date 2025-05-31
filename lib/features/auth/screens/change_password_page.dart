// lib/screens/auth/change_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../constants/colors.dart';
import '../../services/user_service.dart';
import '../../providers/user_provider.dart';

/// 로그인(마이페이지) 상태에서 “현재 비밀번호 / 새 비밀번호 / 새 비밀번호 확인” 입력 후 비밀번호 변경
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _oldPw = TextEditingController();
  final _newPw1 = TextEditingController();
  final _newPw2 = TextEditingController();

  String _msg = '';
  bool _busy = false;

  bool get _canSubmit =>
      !_busy &&
      _oldPw.text.isNotEmpty &&
      _newPw1.text.length >= 8 &&
      _newPw1.text == _newPw2.text;

  @override
  void initState() {
    super.initState();
    _oldPw.addListener(() => setState(() {}));
    _newPw1.addListener(() => setState(() {}));
    _newPw2.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldPw.dispose();
    _newPw1.dispose();
    _newPw2.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _busy = true;
      _msg = '';
    });

    try {
      await UserService.changePassword(
        oldPassword: _oldPw.text.trim(),
        newPassword: _newPw1.text.trim(),
      );
      // 성공 시 프로필을 다시 불러오고, 안내 메시지
      await ref.read(userProvider.notifier).loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')));
      Navigator.of(context).pop(); // 이전 화면(마이페이지)로 복귀
    } catch (e) {
      setState(() {
        _msg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '비밀번호 변경',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthInput(hint: '현재 비밀번호', controller: _oldPw, obscure: true),
          const SizedBox(height: 12),
          AuthInput(hint: '새 비밀번호 (최소 8자)', controller: _newPw1, obscure: true),
          const SizedBox(height: 4),
          Text(
            _newPw1.text.length >= 8
                ? '✔ 비밀번호가 8자 이상입니다.'
                : '✘ 비밀번호는 8자 이상이어야 합니다.',
            style: TextStyle(
              color: _newPw1.text.length >= 8 ? kSuccess : kError,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          AuthInput(hint: '새 비밀번호 확인', controller: _newPw2, obscure: true),
          const SizedBox(height: 4),
          Text(
            (_newPw2.text.isEmpty)
                ? ''
                : (_newPw1.text == _newPw2.text
                    ? '✔ 비밀번호가 일치합니다.'
                    : '✘ 비밀번호가 일치하지 않습니다.'),
            style: TextStyle(
              color: _newPw1.text == _newPw2.text ? kSuccess : kError,
              fontSize: 12,
            ),
          ),
          if (_msg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_msg, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      footer: AuthButton(
        text: '비밀번호 변경',
        enabled: _canSubmit,
        onPressed: _changePassword,
      ),
    );
  }
}
