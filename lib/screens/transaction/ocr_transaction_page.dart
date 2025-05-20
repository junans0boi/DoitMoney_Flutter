import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';

/// OCR로 읽은 거래 항목 모델
class OcrTransaction {
  final String date;
  final String time;
  final String description;
  final int amount;
  final int balance;

  OcrTransaction({
    required this.date,
    required this.time,
    required this.description,
    required this.amount,
    required this.balance,
  });
}

class OcrTransactionPage extends StatefulWidget {
  const OcrTransactionPage({Key? key}) : super(key: key);

  @override
  State<OcrTransactionPage> createState() => _OcrTransactionPageState();
}

class _OcrTransactionPageState extends State<OcrTransactionPage> {
  File? _image;
  String _recognizedText = '';
  List<OcrTransaction> _transactions = [];
  final _picker = ImagePicker();

  /// 이미지 선택 및 OCR 수행
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => _image = File(picked.path));

      final inputImage = InputImage.fromFilePath(picked.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      // 블록 단위로 텍스트 합치기
      final raw = result.blocks.map((b) => b.text).join('\n');
      final parsed = _parseOcrText(raw);

      setState(() {
        _recognizedText = raw;
        _transactions = parsed;
      });
    } catch (e, st) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR 실패: \$e')));
      debugPrint('Ocr error: \$e\n\$st');
    }
  }

  /// 숫자 문자열 정제 (콤마 그룹이 3자리 초과 시 자르기)
  String _cleanNumeric(String s) {
    final parts = s.split(',');
    if (parts.length > 1 && parts.last.length > 3) {
      parts[parts.length - 1] = parts.last.substring(0, 3);
    }
    return parts.join(',');
  }

  /// OCR 텍스트를 행 단위로 파싱하여 거래 항목 생성
  List<OcrTransaction> _parseOcrText(String text) {
    final lines =
        text
            .split(RegExp(r'\r?\n'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    final List<OcrTransaction> result = [];

    // 패턴 정의
    final dateDescRe = RegExp(r'^(\d{1,2}\.\d{1,2})\s+(.+)\$');
    final timeRe = RegExp(r'^(\d{1,2}):(\d{2})\$');
    final amtRe = RegExp(r'^(-?\d{1,3}(?:,\d{3})*)원?\$');
    final balRe = RegExp(r'^(\d{1,3}(?:,\d{3})*)원?\$');

    String? date;
    String? desc;
    String? time;
    int? amt;
    int? bal;

    for (final line in lines) {
      // 1) 날짜+설명 한 줄에 있을 때
      final md = dateDescRe.firstMatch(line);
      if (md != null) {
        date = md.group(1)!;
        desc = md.group(2)!;
        time = null;
        amt = null;
        bal = null;
        continue;
      }

      // 2) 시간 (분이 60 미만인지 검증)
      if (date != null && time == null) {
        final mt = timeRe.firstMatch(line);
        if (mt != null) {
          final minute = int.tryParse(mt.group(2)!) ?? 0;
          if (minute < 60) {
            time = mt.group(0)!;
          }
          continue;
        }
      }

      // 3) 금액
      if (date != null && time != null && amt == null) {
        final ma = amtRe.firstMatch(line);
        if (ma != null) {
          final rawNum = _cleanNumeric(ma.group(1)!);
          amt = int.parse(rawNum.replaceAll(',', ''));
          continue;
        }
      }

      // 4) 잔액
      if (date != null && time != null && amt != null && bal == null) {
        final mb = balRe.firstMatch(line);
        if (mb != null) {
          final rawNum = _cleanNumeric(mb.group(1)!);
          bal = int.parse(rawNum.replaceAll(',', ''));

          // 모든 정보가 준비되었으므로 결과에 추가
          result.add(
            OcrTransaction(
              date: date,
              time: time!,
              description: desc ?? '',
              amount: amt,
              balance: bal,
            ),
          );

          // 다음 거래를 위해 초기화
          date = null;
          desc = null;
          time = null;
          amt = null;
          bal = null;
        }
        continue;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR 거래 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('사진 선택'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),

            if (_image != null) ...[
              Image.file(_image!, height: 200),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '▶ Raw OCR Text',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_recognizedText),
                      const SizedBox(height: 24),

                      const Text(
                        '▶ Parsed Transactions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // 표 형태로 파싱 결과 출력
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('날짜')),
                            DataColumn(label: Text('시간')),
                            DataColumn(label: Text('설명')),
                            DataColumn(label: Text('금액')),
                            DataColumn(label: Text('잔액')),
                          ],
                          rows:
                              _transactions.map((t) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(t.date)),
                                    DataCell(Text(t.time)),
                                    DataCell(Text(t.description)),
                                    DataCell(Text('${t.amount}원')),
                                    DataCell(Text('${t.balance}원')),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
