// lib/features/more/screens/terms_of_service_page.dart

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '이용약관',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text('''여기에 실제 이용약관 내용을 넣으세요.
            
제1조 (목적)  
이 약관은 DoitMoney 서비스...  

제2조 (약관의 명시, 효력 및 변경)  
1. 이용약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로 그 효력을 발생합니다.  
2. ...  
(이하 생략)  
''', style: TextStyle(fontSize: 14, height: 1.6)),
        ),
      ),
    );
  }
}
