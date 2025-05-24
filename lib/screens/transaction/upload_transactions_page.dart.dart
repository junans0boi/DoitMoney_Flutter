// lib/screens/transaction/import_transactions_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'pdf_parsing_page.dart';
import 'xlsx_parsing_page.dart';

/// 파일 선택 후 PDF/XLSX 파싱 페이지로 이동
class ImportTransactionsPage extends StatelessWidget {
  const ImportTransactionsPage({Key? key}) : super(key: key);

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf', 'xlsx'],
      type: FileType.custom,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final path = file.path!;
    final bytes = file.bytes!;

    if (path.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfParsingPage(path: path)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => XlsxParsingPage(bytes: bytes)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('거래 내역 가져오기')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _pickFile(context),
          icon: const Icon(Icons.attach_file),
          label: const Text('파일 선택'),
        ),
      ),
    );
  }
}
