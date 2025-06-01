import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doitmoney_flutter/features/auth/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../auth/providers/user_provider.dart';
import '../../../core/api/dio_client.dart'; // ← dio import
import '../../auth/services/auth_service.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _usernameCtrl = TextEditingController();
  String? _currentImageUrl; // 서버에서 내려온 profileImageUrl ("/static/…")
  File? _pickedImageFile;

  // 비밀번호 변경용 컨트롤러
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _newPwConfirmCtrl = TextEditingController();

  bool _busyProfile = false;
  bool _busyPassword = false;

  String _profileMsg = '';
  String _passwordMsg = '';

  @override
  void initState() {
    super.initState();
    final me = ref.read(userProvider);
    if (me != null) {
      _usernameCtrl.text = me.username;
      _currentImageUrl = me.profileImageUrl; // ex) "/static/profiles/xxx.png"
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _newPwConfirmCtrl.dispose();
    super.dispose();
  }

  /// 1) 이미지 선택
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path);
      });
    }
  }

  /// 2) 프로필 정보(이름 + 이미지) 서버로 전송
  Future<void> _saveProfile() async {
    final me = ref.read(userProvider);
    if (me == null) return;

    final newName = _usernameCtrl.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _profileMsg = '사용자 이름을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _busyProfile = true;
      _profileMsg = '';
    });

    try {
      final formData = FormData();

      // 1) username 필드
      formData.fields.add(MapEntry('username', newName));

      // 2) image 파일이 선택되었다면
      if (_pickedImageFile != null) {
        final fileName = _pickedImageFile!.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              _pickedImageFile!.path,
              filename: fileName,
            ),
          ),
        );
      }

      final res = await dio.put(
        '/user/me',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.statusCode == 200) {
        // 3) 업데이트된 프로필 정보 다시 요청
        await ref.read(userProvider.notifier).loadProfile();
        final updated = ref.read(userProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 변경되었습니다.')));

        setState(() {
          // 로컬 상태에도 반영
          _currentImageUrl = updated?.profileImageUrl;
          _pickedImageFile = null;
        });
      } else {
        setState(() {
          _profileMsg = '프로필 저장 실패 (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _profileMsg = '프로필 저장 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyProfile = false;
        });
      }
    }
  }

  /// 3) 비밀번호 변경
  Future<void> _changePassword() async {
    final oldPw = _oldPwCtrl.text.trim();
    final newPw = _newPwCtrl.text.trim();
    final confirmPw = _newPwConfirmCtrl.text.trim();

    if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      setState(() {
        _passwordMsg = '모든 필드를 입력해주세요.';
      });
      return;
    }
    if (newPw.length < 8) {
      setState(() {
        _passwordMsg = '새 비밀번호는 최소 8자 이상이어야 합니다.';
      });
      return;
    }
    if (newPw != confirmPw) {
      setState(() {
        _passwordMsg = '새 비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    setState(() {
      _busyPassword = true;
      _passwordMsg = '';
    });

    try {
      await UserService.changePassword(oldPassword: oldPw, newPassword: newPw);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')));

      // 비밀번호 변경 성공 시 입력 필드 초기화
      _oldPwCtrl.clear();
      _newPwCtrl.clear();
      _newPwConfirmCtrl.clear();
    } catch (e) {
      setState(() {
        final msg = e.toString().replaceFirst('Exception: ', '');
        _passwordMsg = msg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(userProvider); // UserProfile 객체

    // 아래 코드: dio.options.baseUrl 에서 "/api" 제거 후 이미지 URL 구성
    String? imageUrl;
    if (me?.profileImageUrl != null && me!.profileImageUrl.isNotEmpty) {
      // dio.options.baseUrl 예: "http://doitmoney.kro.kr/api"
      final hostOnly = dio.options.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      imageUrl =
          me.profileImageUrl.startsWith('http')
              ? me.profileImageUrl
              : '$hostOnly${me.profileImageUrl}';
      // imageUrl 예: "http://doitmoney.kro.kr/static/profiles/abcdef.png"
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '프로필 편집',
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
              // ───── 프로필 이미지 ─────
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl) : null,
                      child:
                          imageUrl == null
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ───── 사용자 이름 ─────
              const Text(
                '사용자 이름',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  hintText: '사용자 이름',
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
              const SizedBox(height: 8),
              if (_profileMsg.isNotEmpty)
                Text(
                  _profileMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 16),

              // ───── 프로필 저장 버튼 ─────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busyProfile ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _busyProfile
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            '저장',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              // ───── 비밀번호 변경 섹션 ─────
              const Text(
                '비밀번호 변경',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // 현재 비밀번호
              const Text('현재 비밀번호', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              TextField(
                controller: _oldPwCtrl,
                decoration: InputDecoration(
                  hintText: '현재 비밀번호',
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
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // 새 비밀번호
              const Text('새 비밀번호 (최소 8자)', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              TextField(
                controller: _newPwCtrl,
                decoration: InputDecoration(
                  hintText: '새 비밀번호',
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
                obscureText: true,
              ),
              const SizedBox(height: 4),
              Text(
                _newPwCtrl.text.length >= 8
                    ? '✔ 비밀번호가 8자 이상입니다.'
                    : '✘ 비밀번호는 8자 이상이어야 합니다.',
                style: TextStyle(
                  color: _newPwCtrl.text.length >= 8 ? kSuccess : kError,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // 새 비밀번호 확인
              const Text('새 비밀번호 확인', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              TextField(
                controller: _newPwConfirmCtrl,
                decoration: InputDecoration(
                  hintText: '새 비밀번호 확인',
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
                obscureText: true,
              ),
              const SizedBox(height: 4),
              Text(
                _newPwConfirmCtrl.text.isEmpty
                    ? ''
                    : (_newPwCtrl.text == _newPwConfirmCtrl.text
                        ? '✔ 비밀번호가 일치합니다.'
                        : '✘ 비밀번호가 일치하지 않습니다.'),
                style: TextStyle(
                  color:
                      _newPwCtrl.text == _newPwConfirmCtrl.text
                          ? kSuccess
                          : kError,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              if (_passwordMsg.isNotEmpty)
                Text(
                  _passwordMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 16),

              // 비밀번호 변경 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busyPassword ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _busyPassword
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            '비밀번호 변경',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
