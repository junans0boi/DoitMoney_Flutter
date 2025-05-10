// lib/screens/auth/signup_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

enum SignupStage { enterEmail, enterCode, enterDetails }

/// 한국 휴대폰번호 마스킹 포맷터: 010-1234-5678
class KoreanPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      buffer.write(digits[i]);
      if ((i == 2 || i == 6) && i != digits.length - 1) {
        buffer.write('-');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  SignupStage stage = SignupStage.enterEmail;

  // controllers
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final pw1Ctrl = TextEditingController();
  final pw2Ctrl = TextEditingController();

  // UI state
  String feedback = '';
  bool emailOk = false;
  String emailMsg = '';

  // one‐time send flag & resend cooldown
  bool _sentOnce = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  double get progress => (stage.index + 1) / SignupStage.values.length;

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_onEmailChanged);
    codeCtrl.addListener(() => setState(() {}));
    pw1Ctrl.addListener(() => setState(() {}));
    pw2Ctrl.addListener(() => setState(() {}));
    phoneCtrl.addListener(() => setState(() {}));
    usernameCtrl.addListener(() => setState(() {}));
  }

  void _onEmailChanged() {
    final email = emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        emailOk = false;
        emailMsg = '⚠ 이메일 형식이 올바르지 않습니다.';
      });
      return;
    }
    AuthService.checkEmailAvailable(email)
        .then((ok) {
          if (!mounted) return;
          setState(() {
            emailOk = ok;
            emailMsg = ok ? '✔ 사용 가능한 이메일입니다.' : '🚫 이미 가입된 이메일입니다.';
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            emailOk = false;
            emailMsg = '⛔ 서버 오류, 잠시 후 시도하세요.';
          });
        });
  }

  void _startResendTimer() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    emailCtrl
      ..removeListener(_onEmailChanged)
      ..dispose();
    codeCtrl.dispose();
    phoneCtrl.dispose();
    usernameCtrl.dispose();
    pw1Ctrl.dispose();
    pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() => feedback = '');

    try {
      switch (stage) {
        case SignupStage.enterEmail:
          // 화면 전환
          setState(() {
            stage = SignupStage.enterCode;
            feedback = '인증번호 요청 중…';
            _sentOnce = true;
          });
          _startResendTimer();
          // 백그라운드 발송
          await AuthService.sendVerificationCode(emailCtrl.text.trim());
          if (!mounted) return;
          setState(() => feedback = '인증번호가 발송되었습니다.');
          break;

        case SignupStage.enterCode:
          final ok = await AuthService.verifyCode(
            emailCtrl.text.trim(),
            codeCtrl.text.trim(),
          );
          if (ok) {
            setState(() => stage = SignupStage.enterDetails);
          }
          break;

        case SignupStage.enterDetails:
          try {
            final rawPhone = phoneCtrl.text.replaceAll('-', '');
            await AuthService.register(
              email: emailCtrl.text.trim(),
              code: codeCtrl.text.trim(),
              phone: rawPhone,
              password: pw1Ctrl.text,
              username: usernameCtrl.text.trim(),
            );
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          } catch (e) {
            setState(() => feedback = '회원가입 실패: ${e.toString()}');
          }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => feedback = '실패: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    Widget footer;

    switch (stage) {
      case SignupStage.enterEmail:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 이메일 입력',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            AuthInput(
              hint: '이메일',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            if (emailMsg.isNotEmpty)
              Text(
                emailMsg,
                style: TextStyle(
                  color: emailOk ? kSuccess : kError,
                  fontSize: 12,
                ),
              ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                feedback,
                style: const TextStyle(color: kError, fontSize: 12),
              ),
            ],
          ],
        );
        footer = AuthButton(
          text: '다음',
          enabled: emailOk && !_sentOnce,
          onPressed: _next,
        );
        break;

      case SignupStage.enterCode:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. 인증번호 입력',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            AuthInput(
              hint: '6자리 코드',
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                feedback,
                style: const TextStyle(color: kError, fontSize: 12),
              ),
            ],
          ],
        );
        footer = Row(
          children: [
            Expanded(
              child: AuthButton(
                text: '다음',
                enabled: codeCtrl.text.trim().length == 6,
                onPressed: _next,
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed:
                  (_resendCooldown == 0)
                      ? () {
                        // resend
                        setState(() {
                          stage = SignupStage.enterEmail;
                          _sentOnce = false;
                        });
                        _next();
                      }
                      : null,
              child: Text(
                _resendCooldown > 0 ? '재전송 (${_resendCooldown}s)' : '재전송',
              ),
            ),
          ],
        );
        break;

      case SignupStage.enterDetails:
        final rawPhone = phoneCtrl.text.replaceAll('-', '');
        final isPhoneOk = rawPhone.length == 11;
        final usernameOk = usernameCtrl.text.trim().length >= 2;
        final pwd = pw1Ctrl.text;
        final confirm = pw2Ctrl.text;
        final isLengthOk = pwd.length >= 8;
        final isMatch = pwd == confirm;

        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. 추가 정보 입력',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            AuthInput(
              hint: '전화번호 (010-1234-5678)',
              controller: phoneCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                KoreanPhoneInputFormatter(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPhoneOk ? '✔ 전화번호 형식이 올바릅니다.' : '✘ 11자리 번호를 입력해주세요.',
              style: TextStyle(
                color: isPhoneOk ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            AuthInput(hint: '사용자 이름 (2자 이상)', controller: usernameCtrl),
            const SizedBox(height: 4),
            Text(
              usernameOk ? '✔ 사용자 이름이 유효합니다.' : '✘ 최소 2자 이상 입력해주세요.',
              style: TextStyle(
                color: usernameOk ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            AuthInput(hint: '비밀번호 (최소 8자)', controller: pw1Ctrl, obscure: true),
            const SizedBox(height: 4),
            Text(
              isLengthOk ? '✔ 비밀번호가 8자 이상입니다.' : '✘ 비밀번호는 8자 이상이어야 합니다.',
              style: TextStyle(
                color: isLengthOk ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            AuthInput(hint: '비밀번호 확인', controller: pw2Ctrl, obscure: true),
            const SizedBox(height: 4),
            Text(
              isMatch ? '✔ 비밀번호가 일치합니다.' : '✘ 비밀번호가 일치하지 않습니다.',
              style: TextStyle(
                color: isMatch ? kSuccess : kError,
                fontSize: 12,
              ),
            ),

            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                feedback,
                style: const TextStyle(color: kError, fontSize: 12),
              ),
            ],
          ],
        );
        footer = AuthButton(
          text: '가입 완료',
          enabled: isPhoneOk && usernameOk && isLengthOk && isMatch,
          onPressed: _next,
        );
        break;
    }

    return AuthScaffold(
      progress: progress,
      body: body,
      footer: footer,
      showBack: stage != SignupStage.enterEmail,
      title: null,
    );
  }
}
