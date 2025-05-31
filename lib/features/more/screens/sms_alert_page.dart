import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/sms_service.dart';
import '../../services/secure_storage_service.dart'; //추가가

class SmsAlertPage extends StatefulWidget {
  const SmsAlertPage({super.key});

  @override
  State<SmsAlertPage> createState() => _SmsAlertPageState();
}

class _SmsAlertPageState extends State<SmsAlertPage> {
  bool _enabled = false;
  //추가가
  final _secure = SecureStorageService();
  final SmsService _smsService = SmsService();

  @override
  void initState() {
    super.initState();
    // 더 이상 SharedPreferences로 초기화하지 않습니다.
    //밑에 추가가
    _secure.read('sms_alert_enabled').then((value) {
      if (value != null) {
        setState(() {
          _enabled = value == 'true';
        });
      }
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    //추가
    // 상태 저장
    await _secure.write('sms_alert_enabled', value.toString());

    if (value) {
      await SmsService().init(); // 켜질 때 바로 초기화
    }
    // 꺼질 때 별도 처리 필요 없으면 그냥 끝
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문자 알림 서비스')),
      body: Center(
        child: SwitchListTile(
          title: const Text('문자 알림 받기'),
          value: _enabled,
          activeColor: kPrimaryColor,
          onChanged: _toggle,
        ),
      ),
    );
  }
}
