// lib/features/more/screens/notification_alert_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/secure_storage_service.dart';
import '../services/notification_service.dart';
import '../../../constants/colors.dart';
import 'package:permission_handler/permission_handler.dart'; // 알림 접근 권한 유도

class NotificationAlertPage extends StatefulWidget {
  const NotificationAlertPage({Key? key}) : super(key: key);

  @override
  State<NotificationAlertPage> createState() => _NotificationAlertPageState();
}

class _NotificationAlertPageState extends State<NotificationAlertPage> {
  bool _enabled = false;
  final _secure = SecureStorageService();
  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _secure.read('notif_alert_enabled').then((value) {
      if (value != null) {
        setState(() {
          _enabled = value == 'true';
        });
        if (_enabled) {
          _notifService.init();
        }
      }
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await _secure.write('notif_alert_enabled', value.toString());

    if (value) {
      // 1) 사용자가 알림 접근 권한(Notification access)을 허용했는지 확인
      final isGranted = await _checkNotificationAccess();
      if (!isGranted) {
        // 알림 접근 권한이 없으면, 설정 화면으로 유도
        await _showPermissionDialog();
        setState(() => _enabled = false);
        await _secure.write('notif_alert_enabled', 'false');
        return;
      }

      // 2) NotificationService 초기화
      await _notifService.init();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('앱 알림 수집이 활성화되었습니다.')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('앱 알림 수집이 비활성화되었습니다.')));
      }
      // 실제 서비스 해제 로직은 NotificationListenerService 측에서
      // Service를 중지할 수 없으므로, 다음 앱 재실행까지 비활성화 상태 유지
    }
  }

  /// 알림 접근 권한이 시스템에서 허용되어 있는지 확인
  Future<bool> _checkNotificationAccess() async {
    // permission_handler 플러그인 사용
    final status = await Permission.notification.isGranted;
    if (status) return true;
    // Android의 Notification Listener 권한은 permission_handler로 직접 조회 불가 -> 우회 방법
    // 일단 사용자가 수동으로 설정해주도록 유도
    return false;
  }

  /// 사용자에게 알림 접근 설정 화면으로 이동하라고 안내하는 다이얼로그
  Future<void> _showPermissionDialog() async {
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('알림 접근 권한 필요'),
            content: const Text(
              '다른 앱의 알림을 읽어오기 위해 “알림 접근(Notification access)” 권한이 필요합니다.\n'
              '설정 화면으로 이동하여 “DoitMoney”에 알림 접근을 허용해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  // Android 알림 접근 권한 설정 화면으로 이동
                  MethodChannel(
                    'doitmoney.flutter.dev/notification',
                  ).invokeMethod('openNotificationSettings');
                  Navigator.pop(ctx);
                },
                child: const Text('설정 열기'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 알림 수집')),
      body: Center(
        child: SwitchListTile(
          title: const Text('앱 알림 읽기'),
          value: _enabled,
          activeColor: kPrimaryColor,
          onChanged: _toggle,
        ),
      ),
    );
  }
}
