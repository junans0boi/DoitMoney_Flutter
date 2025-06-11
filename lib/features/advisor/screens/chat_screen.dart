// lib/features/advisor/screens/chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/advisor_model.dart';
import '../services/advisor_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AdvisorService _advisorService = AdvisorService();
  final TextEditingController _textController = TextEditingController();

  /// 채팅 메시지 리스트 (role, text, optional: categoryData)
  final List<Map<String, dynamic>> _messages = [];

  /// 현재 추천 질문 키 리스트 (초기 진입 시 세팅)
  List<String> _suggestedKeys = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  /// ❶ 첫 화면 진입 시 과거 대화(history) 불러오기
  Future<void> _loadChatHistory() async {
    try {
      final history = await _advisorService.fetchChatHistory();
      setState(() {
        // 과거 대화 내역을 _messages에 보관
        for (var item in history) {
          if (item.categoryData != null) {
            _messages.add({
              'role': item.role,
              'text': item.text,
              'categoryData': item.categoryData,
            });
          } else {
            _messages.add({'role': item.role, 'text': item.text});
          }
        }
        // ❷ 초기 진입 시 추천 질문(세로) 세팅 (항상 뜨도록 하려면, DB에 저장된 마지막 followUps를 가져오거나,
        //    없으면 기본 3가지(이번 달 지출, 지난 달 비교, 카테고리별 내역)을 넣어줍니다.)
        _suggestedKeys = [
          'thisMonthExpense',
          'compareLastMonth',
          'categoryBreakdown',
        ];
      });
    } catch (e) {
      debugPrint("챗 이력 로드 실패: $e");
      setState(() {
        // 실패했어도 기본 추천 질문을 띄워줌
        _suggestedKeys = [
          'thisMonthExpense',
          'compareLastMonth',
          'categoryBreakdown',
        ];
      });
    }
  }

  /// ❸ 사용자 질문 전송
  Future<void> _sendMessage({String? key, String? text}) async {
    if ((key == null || key.isEmpty) && (text == null || text.isEmpty)) {
      return;
    }

    setState(() {
      _isLoading = true;
      if (text != null && text.isNotEmpty) {
        _messages.add({'role': 'user', 'text': text});
      } else if (key != null) {
        _messages.add({'role': 'user', 'text': _mapKeyToLabel(key)});
      }
      // 기존 추천 키를 지우지 않고, “로딩 중”만 표시하기 위해 빈 리스트로 두지 않고 최소화
      _suggestedKeys = [];
      _textController.clear();
    });

    try {
      final resp = await _advisorService.fetchAdvisor(
        questionKey: key,
        userInput: text,
      );
      setState(() {
        if (resp.categoryData != null) {
          _messages.add({
            'role': 'bot',
            'text': resp.answer,
            'categoryData': resp.categoryData,
          });
        } else {
          _messages.add({'role': 'bot', 'text': resp.answer});
        }
        // ❹ 매 요청마다 followUps가 항상 non-empty이므로, 그대로 _suggestedKeys에 반영
        _suggestedKeys = resp.followUps;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': '서버 호출 중 오류가 발생했습니다.\n$e'});
        // 오류가 나도 기본 추천 질문은 유지하도록
        _suggestedKeys = [
          'thisMonthExpense',
          'compareLastMonth',
          'categoryBreakdown',
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 질문 키(key)를 사람이 알아볼 수 있는 라벨로 매핑
  String _mapKeyToLabel(String key) {
    switch (key) {
      case 'thisMonthExpense':
        return '이번 달 총 지출이 어떻게 되나요?';
      case 'compareLastMonth':
        return '지난 달과 비교해서 지출이 늘었나요?';
      case 'categoryBreakdown':
        return '카테고리별 지출 내역을 보여줘';
      case 'budgetAdvice':
        return '다음 달 예산은 어떻게 잡아야 할까요?';
      case 'mostExpensiveCategory':
        return '가장 많이 쓴 카테고리는 어디인가요?';
      case 'expenseReductionTips':
        return '지출 절약 팁을 알려줘';
      case 'nextMonthBudget':
        return '다음 달 예산을 추천해줘';
      case 'saveTipsForCategory':
        return '특정 카테고리 절약 방법을 알려줘';
      case 'unexpectedExpense':
        return '이번 달 예상 못 한 지출이 있나요?';
      case 'setCategoryBudget':
        return '카테고리별 예산은 어떻게 설정하면 좋을까요?';
      default:
        return key;
    }
  }

  /// 카테고리별 파이 차트 섹션 생성
  List<PieChartSectionData> _buildPieSections(
    Map<String, dynamic> categoryData,
  ) {
    final total = categoryData.values.fold<double>(
      0,
      (sum, value) => sum + (value as num).toDouble(),
    );
    int idx = 0;
    final colors = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.brown,
      Colors.cyanAccent,
    ];

    return categoryData.entries.map((e) {
      final v = (e.value as num).toDouble();
      final pct = (total == 0) ? 0.0 : (v / total) * 100;
      final section = PieChartSectionData(
        color: colors[idx % colors.length],
        value: v,
        title: "${pct.toStringAsFixed(1)}%",
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      idx++;
      return section;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수입·지출 어드바이저')),
      body: Column(
        children: [
          // 1) 과거까지 포함한 채팅 로그
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Column(
                  crossAxisAlignment:
                      isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    // 2) 봇 답변 직후 파이 차트가 있으면 렌더링
                    if (!isUser && msg.containsKey('categoryData'))
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(
                              msg['categoryData'] as Map<String, dynamic>,
                            ),
                            centerSpaceRadius: 30,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 3) 로딩 인디케이터
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),

          // 4) 추천 질문을 세로 Column으로 노출 (항상 followUps가 non-empty이므로 여기에 무조건 노출됨)
          if (_suggestedKeys.isNotEmpty)
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    _suggestedKeys.map((key) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed:
                              _isLoading ? null : () => _sendMessage(key: key),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _mapKeyToLabel(key),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

          // ↓↓↓ 자유 입력 필드 + 전송 버튼
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '질문을 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            final text = _textController.text.trim();
                            if (text.isNotEmpty) {
                              _sendMessage(text: text);
                            }
                          },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
