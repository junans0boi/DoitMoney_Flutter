// lib/features/more/screens/sms_alert_page.dart

import 'package:flutter/material.dart';
import '../../../core/services/secure_storage_service.dart';
import '../services/sms_parser_service.dart';
import '../../../constants/colors.dart';

class SmsAlertPage extends StatefulWidget {
  const SmsAlertPage({super.key});

  @override
  State<SmsAlertPage> createState() => _SmsAlertPageState();
}

class _SmsAlertPageState extends State<SmsAlertPage> {
  bool _enabled = false;
  final _secure = SecureStorageService();
  final SmsService _smsService = SmsService();

  @override
  void initState() {
    super.initState();
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
    await _secure.write('sms_alert_enabled', value.toString());
    if (value) {
      await _smsService.init(); // 켜질 때 초기화
    }
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
