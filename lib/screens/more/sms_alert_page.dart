import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/sms_service.dart';

class SmsAlertPage extends StatefulWidget {
  const SmsAlertPage({super.key});

  @override
  State<SmsAlertPage> createState() => _SmsAlertPageState();
}

class _SmsAlertPageState extends State<SmsAlertPage> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    // 더 이상 SharedPreferences로 초기화하지 않습니다.
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
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
