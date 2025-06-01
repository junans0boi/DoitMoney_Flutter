import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/colors.dart';

/// 거래내역 파일 선택 진입점
class ImportTransactionsPage extends StatelessWidget {
  const ImportTransactionsPage({super.key});

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx'],
    );
    if (result == null) return;

    final file = result.files.single;

    // 파일 확장자에 따라 라우트 분기
    if (file.extension?.toLowerCase() == 'pdf') {
      context.push('/pdf-preview', extra: file.path!); // pdf: 경로(String)
    } else {
      context.push('/xlsx-preview', extra: file); // xlsx: PlatformFile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('거래 내역 가져오기')),
      body: Center(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => _pickFile(context),
          icon: const Icon(Icons.upload_file),
          label: const Text('파일 선택'),
        ),
      ),
    );
  }
}
