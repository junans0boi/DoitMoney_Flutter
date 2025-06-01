// lib/features/more/screens/privacy_policy_page.dart

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '개인정보처리방침',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text('''여기에 실제 개인정보처리방침 내용을 넣으세요.

1. 개인정보의 처리 목적  
“DoitMoney” 은(는) 다음의 목적을 위하여 개인정보를 처리합니다.  
가. 회원가입 및 관리  
회원 가입 의사 확인, 회원제 서비스 제공에 따른 본인 식별 · 인증, 회원자격 유지·관리 등  

2. 개인정보 처리 및 보유 기간  
회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 처리·보유합니다.  
... (이하 생략)
''', style: TextStyle(fontSize: 14, height: 1.6)),
        ),
      ),
    );
  }
}
