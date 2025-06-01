// lib/features/more/screens/customer_service_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../auth/providers/user_provider.dart';
import '../services/customer_service.dart';

class CustomerServicePage extends ConsumerStatefulWidget {
  const CustomerServicePage({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerServicePage> createState() =>
      _CustomerServicePageState();
}

class _CustomerServicePageState extends ConsumerState<CustomerServicePage> {
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _busy = false;
  String _msg = '';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = ref.read(userProvider);
    if (me == null) {
      setState(() {
        _msg = '로그인 상태에서만 문의할 수 있습니다.';
      });
      return;
    }
    if (_subjectCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      setState(() {
        _msg = '제목과 내용을 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _msg = '';
    });

    try {
      await CustomerService.sendInquiry(
        userEmail: me.email,
        subject: _subjectCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문의가 성공적으로 전송되었습니다.')));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _msg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '고객센터',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_msg.isNotEmpty) ...[
                Text(
                  _msg,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                '제목',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectCtrl,
                decoration: InputDecoration(
                  hintText: '문의 제목을 입력하세요',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '내용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '문의 내용을 자세히 입력하세요',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _busy
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            '보내기',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
