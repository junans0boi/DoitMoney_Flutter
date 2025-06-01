// lib/features/auth/screens/reset_password_screen.dart (리팩터 후)

// ignore_for_file: unused_import, use_super_parameters

import 'dart:async';
import 'package:doitmoney_flutter/features/auth/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/common_input.dart';
import '../../../shared/widgets/common_button.dart';

import '../services/auth_service.dart';
import '../../../constants/colors.dart';

enum _ResetStage { enterEmail, enterCode, enterPassword }

class CombinedResetPwPage extends StatefulWidget {
  const CombinedResetPwPage({Key? key}) : super(key: key);

  @override
  State<CombinedResetPwPage> createState() => _CombinedResetPwPageState();
}

class _CombinedResetPwPageState extends State<CombinedResetPwPage> {
  _ResetStage _stage = _ResetStage.enterEmail;
  final _emailCtrl = TextEditingController();
  bool _sendingEmail = false;
  String _emailMsg = '';

  final _codeCtrl = TextEditingController();
  bool _verifyingCode = false;
  String _codeMsg = '';

  final _pw1Ctrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _changingPw = false;
  String _pwMsg = '';

  late String _emailValue;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() => setState(() {}));
    _codeCtrl.addListener(() => setState(() {}));
    _pw1Ctrl.addListener(() => setState(() {}));
    _pw2Ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pw1Ctrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetCodeEmail() async {
    setState(() {
      _sendingEmail = true;
      _emailMsg = '';
    });

    final email = _emailCtrl.text.trim();
    try {
      await AuthService.sendResetMail(email);
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

  Future<void> _changePassword() async {
    setState(() {
      _changingPw = true;
      _pwMsg = '';
    });

    try {
      await AuthService.resetPassword(
        email: _emailValue,
        code: _codeCtrl.text.trim(),
        password: _pw1Ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.')));
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
    final canSendEmail = !_sendingEmail && _emailCtrl.text.trim().isNotEmpty;
    final canVerifyCode = !_verifyingCode && _codeCtrl.text.trim().length == 6;
    final pwLenOk = _pw1Ctrl.text.length >= 8;
    final pwMatch = _pw1Ctrl.text == _pw2Ctrl.text;
    final canChangePw = !_changingPw && pwLenOk && pwMatch;

    Widget body;
    Widget footer;

    switch (_stage) {
      case _ResetStage.enterEmail:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonInput(
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
        footer = CommonElevatedButton(
          text: '인증번호 요청',
          enabled: canSendEmail,
          onPressed: _sendResetCodeEmail,
        );
        break;

      case _ResetStage.enterCode:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이메일: $_emailValue', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            CommonInput(
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
        footer = CommonElevatedButton(
          text: '코드 확인',
          enabled: canVerifyCode,
          onPressed: _verifyResetCode,
        );
        break;

      case _ResetStage.enterPassword:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonInput(
              hint: '새 비밀번호 (최소 8자)',
              controller: _pw1Ctrl,
              obscure: true,
            ),
            const SizedBox(height: 8),
            Text(
              pwLenOk ? '✔ 비밀번호가 8자 이상입니다.' : '✘ 비밀번호는 최소 8자여야 합니다.',
              style: TextStyle(
                color: pwLenOk ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            CommonInput(hint: '비밀번호 확인', controller: _pw2Ctrl, obscure: true),
            const SizedBox(height: 4),
            Text(
              pwMatch ? '✔ 비밀번호가 일치합니다.' : '✘ 비밀번호가 일치하지 않습니다.',
              style: TextStyle(
                color: pwMatch ? Colors.green : Colors.red,
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
        footer = CommonElevatedButton(
          text: '비밀번호 변경',
          enabled: canChangePw,
          onPressed: _changePassword,
        );
        break;
    }

    return AuthScaffold(
      title:
          _stage == _ResetStage.enterEmail
              ? '비밀번호 찾기'
              : _stage == _ResetStage.enterCode
              ? '인증번호 확인'
              : '새 비밀번호 설정',
      body: Column(children: [body]),
      footer: footer,
    );
  }
}
