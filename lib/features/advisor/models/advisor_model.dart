// lib/features/advisor/models/advisor_model.dart

import 'dart:convert'; // ← jsonDecode 사용을 위해 꼭 필요

class AdvisorRequest {
  final String? questionKey;
  final String? userInput;

  AdvisorRequest({this.questionKey, this.userInput});

  Map<String, dynamic> toJson() {
    return {'questionKey': questionKey, 'userInput': userInput};
  }
}

class AdvisorResponse {
  final String answer;
  final List<String> followUps;
  final Map<String, dynamic>? categoryData;

  AdvisorResponse({
    required this.answer,
    required this.followUps,
    this.categoryData,
  });

  factory AdvisorResponse.fromJson(Map<String, dynamic> json) {
    return AdvisorResponse(
      answer: json['answer'] as String,
      followUps: List<String>.from(json['followUps'] as List<dynamic>),
      categoryData:
          json['categoryData'] != null
              ? Map<String, dynamic>.from(json['categoryData'] as Map)
              : null,
    );
  }
}

/// 과거 대화 내역을 받을 때 사용하는 DTO
class ChatHistoryItem {
  final String role;
  final String text;
  final Map<String, dynamic>? categoryData;
  final DateTime createdAt;

  ChatHistoryItem({
    required this.role,
    required this.text,
    this.categoryData,
    required this.createdAt,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? cat;
    if (json['categoryDataJson'] != null) {
      cat = Map<String, dynamic>.from(
        jsonDecode(json['categoryDataJson'] as String) as Map,
      );
    }
    return ChatHistoryItem(
      role: json['role'] as String,
      text: json['text'] as String,
      categoryData: cat,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
