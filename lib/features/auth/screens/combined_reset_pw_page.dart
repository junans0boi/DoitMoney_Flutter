// lib/screens/auth/combined_reset_pw_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

enum _ResetStage { enterEmail, enterCode, enterPassword }

/// ─── 한 페이지에서 “이메일 입력 → 인증번호 발송 → 인증번호 입력 → 새 비밀번호 입력” 흐름 구현 ───
///
/// 1) 처음에는 이메일 입력란만 보여줍니다.
/// 2) “인증번호 요청” 버튼 누르면 서버에 /recover/reset-mail 호출. 성공 시 _stage 를 enterCode 로 변경.
/// 3) enterCode 단계에서는 인증번호 입력란과 “코드 확인” 버튼을 보여줍니다.
///    - 인증번호 검증 성공하면 _stage 를 enterPassword 로 변경.
/// 4) enterPassword 단계에서는 새 비밀번호 입력란(새 비밀번호 / 비밀번호 확인)과 “비밀번호 변경” 버튼을 보여줍니다.
///    - 최종 성공 시 '/login' 으로 돌아갑니다.
///
/// ※ 중요한 점: initState() 안에서 절대로 `GoRouterState.of(context)` 나 `Theme.of(context)` 등
///    context 기반 작업을 하면 안 됩니다. build() 안이나 버튼의 onPressed 콜백에서 context 를 사용하세요.
class CombinedResetPwPage extends StatefulWidget {
  const CombinedResetPwPage({Key? key}) : super(key: key);

  @override
  State<CombinedResetPwPage> createState() => _CombinedResetPwPageState();
}

class _CombinedResetPwPageState extends State<CombinedResetPwPage> {
  // 현재 단계
  _ResetStage _stage = _ResetStage.enterEmail;

  // ① 이메일 단계
  final _emailCtrl = TextEditingController();
  bool _sendingEmail = false;
  String _emailMsg = '';

  // ② 인증번호(코드) 단계
  final _codeCtrl = TextEditingController();
  bool _verifyingCode = false;
  String _codeMsg = '';

  // ③ 새 비밀번호 단계
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();
  bool _changingPw = false;
  String _pwMsg = '';

  // 단계 간에 공유할 _email 값 (초기 이메일 입력한 이후 보관)
  late String _emailValue;

  @override
  void initState() {
    super.initState();
    // initState 에서는 절대로 context를 사용하지 않습니다.
    // 이메일, 인증번호, 패스워드 컨트롤러에 리스너 추가
    _emailCtrl.addListener(() => setState(() {}));
    _codeCtrl.addListener(() => setState(() {}));
    _pw1.addListener(() => setState(() {}));
    _pw2.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  // ─── 1) 이메일로 인증번호 요청 ───
  Future<void> _sendResetCodeEmail() async {
    setState(() {
      _sendingEmail = true;
      _emailMsg = '';
    });

    final email = _emailCtrl.text.trim();
    try {
      await AuthService.sendResetMail(email);
      // 성공하면 _emailValue 에 저장하고 단계 전환
      _emailValue = email;
      setState(() {
        _emailMsg = '인증번호가 메일로 발송되었습니다.';
        _stage = _ResetStage.enterCode;
      });
    } catch (e) {
      final text = e.toString();
      if (text.contains('404') || text.contains('회원이 아님')) {
        setState(() {
          _emailMsg = '가입되지 않은 이메일입니다.';
        });
      } else {
        setState(() {
          _emailMsg = '인증번호 발송 중 오류가 발생했습니다.';
        });
      }
    } finally {
      setState(() {
        _sendingEmail = false;
      });
    }
  }

  // ─── 2) 인증번호(코드) 검증 ───
  Future<void> _verifyResetCode() async {
    setState(() {
      _verifyingCode = true;
      _codeMsg = '';
    });

    try {
      final ok = await AuthService.verifyResetCode(
        email: _emailValue,
        code: _codeCtrl.text.trim(),
      );
      if (ok) {
        setState(() {
          _codeMsg = '인증번호가 확인되었습니다.';
          _stage = _ResetStage.enterPassword;
        });
      } else {
        setState(() {
          _codeMsg = '인증번호가 올바르지 않습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _codeMsg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _verifyingCode = false;
      });
    }
  }

  // ─── 3) 새 비밀번호 저장 ───
  Future<void> _changePassword() async {
    setState(() {
      _changingPw = true;
      _pwMsg = '';
    });

    try {
      await AuthService.resetPassword(
        email: _emailValue,
        code: _codeCtrl.text.trim(),
        password: _pw1.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.')));
      // 성공 시 로그인 페이지로 돌아감
      context.go('/login');
    } catch (e) {
      setState(() {
        _pwMsg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _changingPw = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 버튼 활성화 조건
    final canSendEmail = !_sendingEmail && _emailCtrl.text.trim().isNotEmpty;
    final canVerifyCode = !_verifyingCode && _codeCtrl.text.trim().length == 6;
    final pwLenOk = _pw1.text.length >= 8;
    final pwMatch = _pw1.text == _pw2.text;
    final canChangePw = !_changingPw && pwLenOk && pwMatch;

    Widget body;
    Widget footer;

    switch (_stage) {
      case _ResetStage.enterEmail:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthInput(
              hint: '가입 이메일',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            if (_emailMsg.isNotEmpty)
              Text(
                _emailMsg,
                style: TextStyle(
                  color:
                      _emailMsg.contains('발송되었습니다') ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        );
        footer = AuthButton(
          text: '인증번호 요청',
          enabled: canSendEmail,
          onPressed: _sendResetCodeEmail,
        );
        break;

      case _ResetStage.enterCode:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이메일은 화면에 고정으로 보여줘도 좋습니다.
            Text('이메일: $_emailValue', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            AuthInput(
              hint: '6자리 인증번호',
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 8),
            if (_codeMsg.isNotEmpty)
              Text(
                _codeMsg,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        );
        footer = AuthButton(
          text: '코드 확인',
          enabled: canVerifyCode,
          onPressed: _verifyResetCode,
        );
        break;

      case _ResetStage.enterPassword:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthInput(hint: '새 비밀번호 (최소 8자)', controller: _pw1, obscure: true),
            const SizedBox(height: 8),
            Text(
              pwLenOk ? '✔ 비밀번호가 8자 이상입니다.' : '✘ 비밀번호는 최소 8자여야 합니다.',
              style: TextStyle(
                color: pwLenOk ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            AuthInput(hint: '비밀번호 확인', controller: _pw2, obscure: true),
            const SizedBox(height: 4),
            Text(
              pwMatch ? '✔ 비밀번호가 일치합니다.' : '✘ 비밀번호가 일치하지 않습니다.',
              style: TextStyle(
                color: pwMatch ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (_pwMsg.isNotEmpty)
              Text(
                _pwMsg,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        );
        footer = AuthButton(
          text: '비밀번호 변경',
          enabled: canChangePw,
          onPressed: _changePassword,
        );
        break;
    }

    return AuthScaffold(
      // AppBar에 제목을 두고 싶으면 title을 적어주세요.
      title:
          _stage == _ResetStage.enterEmail
              ? '비밀번호 찾기'
              : _stage == _ResetStage.enterCode
              ? '인증번호 확인'
              : '새 비밀번호 설정',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [body],
      ),
      footer: footer,
    );
  }
}
