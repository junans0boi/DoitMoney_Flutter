import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _enabled = prefs.getBool('sms_alert_enabled') ?? false);
    if (_enabled) {
      await SmsService().init();
    }
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_alert_enabled', value);
    setState(() => _enabled = value);
    if (value) {
      await SmsService().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '문자 알림 서비스',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SwitchListTile(
          title: const Text('문자 알림 받기'),
          value: _enabled,
          activeColor: kPrimaryColor,
          // onChanged: (v) => setState(() => _enabled = v),
          onChanged: _toggle,
        ),
      ),
    );
  }
}
