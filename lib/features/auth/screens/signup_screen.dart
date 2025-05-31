// lib/screens/auth/signup_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

enum SignupStage { enterEmail, enterCode, enterDetails }

class KoreanPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      buf.write(digits[i]);
      if ((i == 2 || i == 6) && i != digits.length - 1) {
        buf.write('-');
      }
    }
    final formatted = buf.toString();
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
  SignupStage _stage = SignupStage.enterEmail;

  // controllers
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _phone = TextEditingController();
  final _user = TextEditingController();
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();

  // UI state
  String _feedback = '';
  bool _emailOk = false, _emailSent = false;
  bool _phoneFormatOk = false, _phoneAvailable = false;
  String _phoneMsg = '';
  int _cooldown = 0;
  Timer? _timer;

  double get _progress => (_stage.index + 1) / SignupStage.values.length;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onEmailChanged);
    _code.addListener(() => setState(() {}));
    _pw1.addListener(() => setState(() {}));
    _pw2.addListener(() => setState(() {}));
    _phone.addListener(_onPhoneChanged);
    _user.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _phone.dispose();
    _user.dispose();
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final e = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      setState(() {
        _emailOk = false;
        _feedback = '⚠ 이메일 형식이 올바르지 않습니다.';
      });
      return;
    }
    AuthService.checkEmailAvailable(e)
        .then((ok) {
          if (!mounted) return;
          setState(() {
            _emailOk = ok;
            _feedback = ok ? '✔ 사용 가능한 이메일입니다.' : '🚫 이미 가입된 이메일입니다.';
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _emailOk = false;
            _feedback = '서버 오류, 잠시 후 시도하세요.';
          });
        });
  }

  void _onPhoneChanged() {
    final raw = _phone.text.replaceAll('-', '');
    final fmtOk = raw.length == 11;
    setState(() {
      _phoneFormatOk = fmtOk;
      _phoneAvailable = false;
      _phoneMsg = fmtOk ? '⏳ 중복 확인 중…' : '✘ 11자리 번호를 입력해주세요.';
    });
    if (fmtOk) {
      AuthService.checkPhoneAvailable(raw)
          .then((ok) {
            if (!mounted) return;
            setState(() {
              _phoneAvailable = ok;
              _phoneMsg = ok ? '✔ 사용 가능한 번호입니다.' : '🚫 이미 가입된 번호입니다.';
            });
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() {
              _phoneAvailable = false;
              _phoneMsg = '서버 오류, 잠시 후 시도하세요.';
            });
          });
    }
  }

  void _startCooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown == 0) {
        t.cancel();
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _next() async {
    setState(() => _feedback = '');
    try {
      switch (_stage) {
        case SignupStage.enterEmail:
          // 1) 이메일 → 인증번호 요청
          setState(() {
            _stage = SignupStage.enterCode;
            _emailSent = true;
          });
          _startCooldown();
          await AuthService.sendVerificationCode(_email.text.trim());
          setState(() => _feedback = '인증번호가 발송되었습니다.');
          break;

        case SignupStage.enterCode:
          // 2) 인증번호 검증
          if (await AuthService.verifyCode(
            _email.text.trim(),
            _code.text.trim(),
          )) {
            setState(() => _stage = SignupStage.enterDetails);
          } else {
            setState(() => _feedback = '인증번호가 올바르지 않습니다.');
          }
          break;

        case SignupStage.enterDetails:
          // 3) 최종 가입
          await AuthService.register(
            email: _email.text.trim(),
            code: _code.text.trim(),
            phone: _phone.text.replaceAll('-', ''),
            password: _pw1.text,
            username: _user.text.trim(),
          );
          // 성공 시에만 이동
          if (!mounted) return;
          context.go('/login');
          break;
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _feedback = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body, footer;

    switch (_stage) {
      case SignupStage.enterEmail:
        final can = _emailOk && !_emailSent;
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
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            if (_feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _feedback,
                style: TextStyle(
                  color: _emailOk ? kSuccess : kError,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
        footer = AuthButton(text: '다음', enabled: can, onPressed: _next);
        break;

      case SignupStage.enterCode:
        final can = _code.text.trim().length == 6;
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
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            if (_feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _feedback,
                style: const TextStyle(color: kError, fontSize: 12),
              ),
            ],
          ],
        );
        footer = Row(
          children: [
            Expanded(
              child: AuthButton(text: '다음', enabled: can, onPressed: _next),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed:
                  _cooldown == 0
                      ? () {
                        setState(() {
                          _stage = SignupStage.enterEmail;
                          _emailSent = false;
                        });
                        _next();
                      }
                      : null,
              child: Text(_cooldown > 0 ? '재전송 (${_cooldown}s)' : '재전송'),
            ),
          ],
        );
        break;

      case SignupStage.enterDetails:
        final pwLenOk = _pw1.text.length >= 8;
        final pwMatch = _pw1.text == _pw2.text;
        final can =
            _phoneFormatOk &&
            _phoneAvailable &&
            _user.text.trim().length >= 2 &&
            pwLenOk &&
            pwMatch;

        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. 추가 정보 입력',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // 전화번호
            AuthInput(
              hint: '전화번호 (010-1234-5678)',
              controller: _phone,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                KoreanPhoneInputFormatter(),
              ],
            ),
            Text(
              _phoneMsg,
              style: TextStyle(
                color: _phoneAvailable ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            // 사용자 이름
            AuthInput(hint: '사용자 이름 (2자 이상)', controller: _user),
            const SizedBox(height: 4),

            // 비밀번호
            AuthInput(hint: '비밀번호 (최소 8자)', controller: _pw1, obscure: true),
            Text(
              pwLenOk ? '✔ 비밀번호가 8자 이상입니다.' : '✘ 비밀번호는 8자 이상이어야 합니다.',
              style: TextStyle(
                color: pwLenOk ? kSuccess : kError,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            AuthInput(hint: '비밀번호 확인', controller: _pw2, obscure: true),
            Text(
              pwMatch ? '✔ 비밀번호가 일치합니다.' : '✘ 비밀번호가 일치하지 않습니다.',
              style: TextStyle(
                color: pwMatch ? kSuccess : kError,
                fontSize: 12,
              ),
            ),

            if (_feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _feedback,
                style: const TextStyle(color: kError, fontSize: 12),
              ),
            ],
          ],
        );
        footer = AuthButton(text: '가입 완료', enabled: can, onPressed: _next);
        break;
    }

    return AuthScaffold(
      progress: _progress,
      body: body,
      footer: footer,
      showBack: _stage != SignupStage.enterEmail,
      title: null,
    );
  }
}
